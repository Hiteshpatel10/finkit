import 'dart:math';

import 'package:finkit/src/compound/models/compound_frequency.dart';
import 'package:finkit/src/compound/models/compound_input.dart';
import 'package:finkit/src/compound/models/compound_result.dart';
import 'package:finkit/src/compound/models/contribution_config.dart';
import 'package:finkit/src/compound/models/payment_config.dart';
import 'package:finkit/src/compound/models/withdrawal_config.dart';
import 'compound_interfaces.dart';

/// The core compound interest engine — single source of truth for all
/// investment calculations in finkit.
///
/// Unified formula:
///   M = P × (1 + r/f)^(f×n)
///     + Σ [ C(t) × (1 + r/f)^(f × remaining_years(t)) ]
///     − Σ [ W(t) × (1 + r/f)^(f × remaining_years(t)) ]
///
/// Both contribution and withdrawal are optional config objects on [CompoundInput].
/// Null means that side is inactive:
///
/// | Scenario       | contribution | withdrawal |
/// |----------------|--------------|------------|
/// | Pure SIP       | set          | null       |
/// | Pure lumpsum   | null         | null       |
/// | Lumpsum + SIP  | set          | null       |
/// | SWP            | null         | set        |
/// | SIP + SWP      | set          | set        |
///
/// **Contribution timing** ([PaymentTiming] inside [ContributionConfig]):
///   - [PaymentTiming.beginning]: added *before* interest (annuity-due)
///   - [PaymentTiming.end]: added *after* interest (ordinary annuity, default)
///
/// **Step-up** (on both [ContributionConfig.stepUp] and [WithdrawalConfig.stepUp]):
///   - [FixedStepUp] / [FixedWithdrawalStepUp]      → amount += delta
///   - [PercentageStepUp] / [PercentageWithdrawalStepUp] → amount *= (1 + rate)
///   - Frequency controlled by [ContributionStepUp.stepUpFrequency], default yearly
///
/// **Withdrawal** ([WithdrawalConfig]):
///   - Applied end-of-period, after interest
///   - If balance would go negative, corpus is exhausted and simulation stops
final class CompoundCalculator
    implements
        CompoundMaturitySolver,
        CompoundContributionSolver,
        CompoundRateSolver,
        CompoundTenureSolver {
  // ─── Core Engine ────────────────────────────────────────────────────────────

  @override
  CompoundResult calculate(CompoundInput input) {
    if (input.principal < 0) {
      throw ArgumentError.value(
        input.principal, 'principal', 'Must be >= 0');
    }
    if (input.annualRate < 0) {
      throw ArgumentError.value(
        input.annualRate, 'annualRate', 'Must be >= 0');
    }
    if (input.tenureMonths <= 0) {
      throw ArgumentError.value(
          input.tenureMonths, 'tenureMonths', 'Tenure must be positive');
    }

    // ── Defense-in-depth: Ensure step-up cadence stays at monthly minimum ─────
    // (StepUpFrequency inherently restricts this, but this protects against future enum changes)
    if (input.contribution?.stepUp != null &&
        input.contribution!.stepUp!.stepUpFrequency.periodsPerYear > 12) {
      throw ArgumentError.value(
        input.contribution!.stepUp!.stepUpFrequency,
        'contribution.stepUp.stepUpFrequency',
        'Step-up frequency cannot be more frequent than monthly',
      );
    }
    if (input.withdrawal?.stepUp != null &&
        input.withdrawal!.stepUp!.stepUpFrequency.periodsPerYear > 12) {
      throw ArgumentError.value(
        input.withdrawal!.stepUp!.stepUpFrequency,
        'withdrawal.stepUp.stepUpFrequency',
        'Step-up frequency cannot be more frequent than monthly',
      );
    }

    final breakdown = <CompoundBreakdownEntry>[];
    double balance = input.principal;
    double totalInvested = input.principal;
    double totalWithdrawn = 0;

    // We iterate exactly tenureMonths times, ensuring 1 entry per month
    // This fixes the bug where non-monthly compounding drops monthly deposits.
    final int totalMonths = input.tenureMonths;

    double uncompoundedInterest = 0;
    
    // Determine when compounding happens
    final int periodsPerYear = input.compoundFrequency == CompoundFrequency.custom 
        ? (input.customCompoundPeriods ?? 12) 
        : input.compoundFrequency.periodsPerYear;

    final bool isDaily = periodsPerYear == 365 || periodsPerYear == 360;
    final double dailyRate = isDaily ? (input.annualRate / 100) / periodsPerYear : 0;
    final double monthlySimpleRate = (input.annualRate / 100) / 12;

    // Unpack contribution config
    final contrib = input.contribution;
    // Unpack withdrawal config
    final withdrawal = input.withdrawal;
    // Read once, null-safe, outside the loop. Inside the loop the only guard
    // was the hasWithdrawal bool, and the AOT compiler hoisted the field load
    // above it (crash on iOS 27 for SIP, where withdrawal is null).
    final WithdrawalType? withdrawalType = withdrawal?.type;

    // Mutable amounts — mutated by step-up logic each cycle
    double currentContribution = contrib?.amount ?? 0;
    double currentWithdrawal = withdrawal?.amount ?? 0;

    int contributionStepUpCount = 0;
    int withdrawalStepUpCount = 0;

    for (int month = 1; month <= totalMonths; month++) {
      final int year = ((month - 1) ~/ 12) + 1;
      final double opening = balance + (isDaily ? 0 : uncompoundedInterest);

      // ── Contribution step-up ──────────────────────────────────────────────
      if (contrib != null && contrib.stepUp != null) {
        final int stepUpMonths = 12 ~/ contrib.stepUp!.stepUpFrequency.periodsPerYear;
        final int newCount = (month - 1) ~/ stepUpMonths;
        if (newCount > contributionStepUpCount) {
          contributionStepUpCount = newCount;
          switch (contrib.stepUp) {
            case FixedStepUp(:final amount):
              currentContribution += amount;
            case PercentageStepUp(:final percent):
              currentContribution *= (1 + percent / 100);
            case null:
              break;
          }
        }
      }

      // ── Withdrawal step-up ────────────────────────────────────────────────
      if (withdrawal != null && withdrawal.stepUp != null) {
        final int stepUpMonths = 12 ~/ withdrawal.stepUp!.stepUpFrequency.periodsPerYear;
        final int newCount = (month - 1) ~/ stepUpMonths;
        if (newCount > withdrawalStepUpCount) {
          withdrawalStepUpCount = newCount;
          switch (withdrawal.stepUp) {
            case FixedWithdrawalStepUp(:final amount):
              currentWithdrawal += amount;
            case PercentageWithdrawalStepUp(:final percent):
              currentWithdrawal *= (1 + percent / 100);
            case null:
              break;
          }
        }
      }

      // ── Period flags ──────────────────────────────────────────────────────
      final int contribPeriods = contrib?.frequency.periodsPerYear ?? 12;
      final int withdrawalPeriods = withdrawal?.frequency.periodsPerYear ?? 12;

      final bool hasContribution = contrib != null;
      final bool hasWithdrawal = withdrawal != null && currentWithdrawal > 0;

      // ── Annuity-due: contribute BEFORE interest ───────────────────────────
      double contributionThisPeriod = 0;
      if (hasContribution) {
        if (contribPeriods > 12) {
           contributionThisPeriod = currentContribution * (contribPeriods / 12);
        } else {
           final int interval = 12 ~/ contribPeriods;
           if (interval > 0 && (month - 1) % interval == 0) {
             contributionThisPeriod = currentContribution;
           }
        }
      }

      if (contributionThisPeriod > 0 && contrib!.timing == PaymentTiming.beginning) {
        totalInvested += contributionThisPeriod;
        balance += contributionThisPeriod;
      }

      // ── Compound interest ─────────────────────────────────────────────────
      double interestForMonth = 0;
      if (isDaily) {
         final days = periodsPerYear / 12; // average days per month
         final effectiveMultiplier = pow(1 + dailyRate, days) - 1;
         interestForMonth = balance * effectiveMultiplier;
         balance += interestForMonth;
      } else if (periodsPerYear > 12) {
         final periodsPerMonth = periodsPerYear / 12;
         final ratePerPeriod = (input.annualRate / 100) / periodsPerYear;
         final effectiveMultiplier = pow(1 + ratePerPeriod, periodsPerMonth) - 1;
         interestForMonth = balance * effectiveMultiplier;
         balance += interestForMonth;
      } else {
         interestForMonth = balance * monthlySimpleRate;
         uncompoundedInterest += interestForMonth;
         
         // Compounding boundary
         final int interval = 12 ~/ periodsPerYear;
         if (interval > 0 && month % interval == 0) {
            balance += uncompoundedInterest;
            uncompoundedInterest = 0;
         }
      }

      // ── Ordinary annuity: contribute AFTER interest ───────────────────────
      if (contributionThisPeriod > 0 && contrib!.timing == PaymentTiming.end) {
        totalInvested += contributionThisPeriod;
        balance += contributionThisPeriod;
      }

      // ── Withdrawal (always end-of-period) ─────────────────────────────────
      double withdrawalThisPeriod = 0;
      bool exhausted = false;
      if (hasWithdrawal) {
        double effectiveBalance = balance + (isDaily || periodsPerYear > 12 ? 0 : uncompoundedInterest);
        
        double withdrawalTarget = 0;
        switch (withdrawalType) {
          case WithdrawalType.fixedAmount:
             withdrawalTarget = currentWithdrawal;
             break;
          case WithdrawalType.percentageOfBalance:
             withdrawalTarget = effectiveBalance * (currentWithdrawal / 100);
             break;
          case WithdrawalType.percentageOfEarnings:
             double earnings = effectiveBalance + totalWithdrawn - totalInvested;
             if (earnings > 0) {
               withdrawalTarget = earnings * (currentWithdrawal / 100);
             }
             break;
          case null:
             break;
        }

        double withdrawalThisPeriodTarget = 0;
        if (withdrawalTarget > 0) {
          if (withdrawalPeriods > 12) {
             withdrawalThisPeriodTarget = withdrawalTarget * (withdrawalPeriods / 12);
          } else {
             final int interval = 12 ~/ withdrawalPeriods;
             if (interval > 0 && (month - 1) % interval == 0) {
               withdrawalThisPeriodTarget = withdrawalTarget;
             }
          }
        }

        if (withdrawalThisPeriodTarget > 0) {
          if (withdrawalThisPeriodTarget >= effectiveBalance) {
            withdrawalThisPeriod = effectiveBalance;
            exhausted = true;
          } else {
            withdrawalThisPeriod = withdrawalThisPeriodTarget;
          }
          totalWithdrawn += withdrawalThisPeriod;
          
          // Deduct from uncompounded interest first, then balance
          if (!isDaily && periodsPerYear <= 12) {
            if (withdrawalThisPeriod <= uncompoundedInterest) {
              uncompoundedInterest -= withdrawalThisPeriod;
            } else {
              double remaining = withdrawalThisPeriod - uncompoundedInterest;
              uncompoundedInterest = 0;
              balance -= remaining;
            }
          } else {
            balance -= withdrawalThisPeriod;
          }
        }
      }

      breakdown.add(
        CompoundBreakdownEntry(
          period: month, // period is always month now
          year: year,
          openingBalance: opening,
          contributionThisPeriod: contributionThisPeriod,
          interestThisPeriod: interestForMonth,
          withdrawalThisPeriod: withdrawalThisPeriod,
          closingBalance: balance + (isDaily || periodsPerYear > 12 ? 0 : uncompoundedInterest),
          cumulativeInvested: totalInvested,
          cumulativeWithdrawn: totalWithdrawn,
          balanceExhausted: exhausted,
        ),
      );

      if (exhausted) break;
    }

    // Force final compounding at maturity if not already compounded
    if (!isDaily && periodsPerYear <= 12 && uncompoundedInterest > 0) {
       balance += uncompoundedInterest;
       uncompoundedInterest = 0;
    }

    return CompoundResult(
      maturityAmount: balance,
      totalInvested: totalInvested,
      totalInterest: balance + totalWithdrawn - totalInvested,
      totalWithdrawn: totalWithdrawn,
      breakdown: List.unmodifiable(breakdown),
    );
  }

  // ─── Contribution Solver ─────────────────────────────────────────────────────
  //
  // Accepts a ContributionConfig template — the solver varies only `amount`
  // via bisection, preserving all other config (frequency, timing, step-up).

  @override
  double calculateRequiredContribution({
    required double targetAmount,
    required double principal,
    required double annualRate,
    required int tenureMonths,
    required ContributionConfig contributionTemplate,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
    WithdrawalConfig? withdrawal,
  }) {
    if (targetAmount <= 0) {
      throw ArgumentError.value(
        targetAmount, 'targetAmount', 'Must be > 0');
    }
    if (principal < 0) {
      throw ArgumentError.value(principal, 'principal', 'Must be >= 0');
    }
    if (annualRate < 0) {
      throw ArgumentError.value(annualRate, 'annualRate', 'Must be >= 0');
    }
    if (tenureMonths <= 0) {
      throw ArgumentError.value(tenureMonths, 'tenureMonths', 'Must be > 0');
    }

    // Check if target is already met by principal alone
    final lumpsumResult = calculate(
      CompoundInput(
        principal: principal,
        annualRate: annualRate,
        tenureMonths: tenureMonths,
        compoundFrequency: compoundFrequency,
        withdrawal: withdrawal,
      ),
    );
    if (lumpsumResult.maturityAmount >= targetAmount) return 0;

    double low = 0;
    double high = targetAmount;
    double mid = 0;

    for (int i = 0; i < 100; i++) {
      mid = (low + high) / 2;

      final result = calculate(
        CompoundInput(
          principal: principal,
          annualRate: annualRate,
          tenureMonths: tenureMonths,
          compoundFrequency: compoundFrequency,
          contribution: contributionTemplate.copyWith(amount: mid),
          withdrawal: withdrawal,
        ),
      );

      if (result.maturityAmount > targetAmount) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return mid;
  }

  // ─── Rate Solver ─────────────────────────────────────────────────────────────

  @override
  double calculateRequiredRate({
    required double targetAmount,
    required double principal,
    required int tenureMonths,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
    ContributionConfig? contribution,
    WithdrawalConfig? withdrawal,
  }) {
    if (targetAmount <= 0) {
      throw ArgumentError.value(
        targetAmount, 'targetAmount', 'Must be > 0');
    }
    if (principal < 0) {
      throw ArgumentError.value(principal, 'principal', 'Must be >= 0');
    }
    if (tenureMonths <= 0) {
      throw ArgumentError.value(tenureMonths, 'tenureMonths', 'Must be > 0');
    }

    CompoundResult maturityAt(double annualRate) => calculate(
      CompoundInput(
        principal: principal,
        annualRate: annualRate,
        tenureMonths: tenureMonths,
        compoundFrequency: compoundFrequency,
        contribution: contribution,
        withdrawal: withdrawal,
      ),
    );

    try {
      return _newtonRaphsonRate(targetAmount, maturityAt);
    } catch (_) {
      return _bisectionRate(targetAmount, maturityAt);
    }
  }

  // ─── Tenure Solver ────────────────────────────────────────────────────────────

  @override
  int calculateRequiredTenure({
    required double targetAmount,
    required double principal,
    required double annualRate,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
    ContributionConfig? contribution,
    WithdrawalConfig? withdrawal,
  }) {
    if (targetAmount <= 0) {
      throw ArgumentError.value(
        targetAmount, 'targetAmount', 'Must be > 0');
    }
    if (principal < 0) {
      throw ArgumentError.value(principal, 'principal', 'Must be >= 0');
    }
    if (annualRate < 0) {
      throw ArgumentError.value(annualRate, 'annualRate', 'Must be >= 0');
    }

    // If rate is 0 and no contributions, target may be unreachable
    if (annualRate == 0 && contribution == null && principal < targetAmount) {
      throw ArgumentError(
        'Target amount ($targetAmount) is unreachable: '
        'rate is 0% and no contributions are configured');
    }

    int low = 1;
    int high = 1200; // 100 years upper bound

    while (low < high) {
      final mid = (low + high) ~/ 2;

      final result = calculate(
        CompoundInput(
          principal: principal,
          annualRate: annualRate,
          tenureMonths: mid,
          compoundFrequency: compoundFrequency,
          contribution: contribution,
          withdrawal: withdrawal,
        ),
      );

      if (result.maturityAmount >= targetAmount) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    return low;
  }

  // ─── Private: Numerical Methods ──────────────────────────────────────────────

  /// Newton-Raphson for rate (numerical derivative via finite difference).
  ///   f(r)  = maturity(r) − target
  ///   f'(r) ≈ (maturity(r + h) − maturity(r)) / h
  ///   r₁    = r₀ − f(r₀) / f'(r₀)
  double _newtonRaphsonRate(
    double target,
    CompoundResult Function(double) maturityAt,
  ) {
    double r = 10.0;
    const h = 0.0001;

    for (int i = 0; i < 50; i++) {
      final f = maturityAt(r).maturityAmount - target;
      final fPlus = maturityAt(r + h).maturityAmount - target;
      final fPrime = (fPlus - f) / h;

      if (fPrime.abs() < 1e-10) {
        throw StateError('Derivative too flat, switching to bisection');
      }

      final next = r - f / fPrime;

      if (next <= 0 || next > 200) {
        throw StateError('Newton-Raphson diverged, switching to bisection');
      }

      if ((next - r).abs() < 1e-8) return next;

      r = next;
    }

    return r;
  }

  /// Bisection fallback for rate.
  double _bisectionRate(
    double target,
    CompoundResult Function(double) maturityAt,
  ) {
    double low = 0.0;
    double high = 200.0;
    double mid = 0.0;

    for (int i = 0; i < 200; i++) {
      mid = (low + high) / 2;
      if (maturityAt(mid).maturityAmount > target) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return mid;
  }

}
