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
class CompoundCalculator
    implements
        CompoundMaturitySolver,
        CompoundContributionSolver,
        CompoundRateSolver,
        CompoundTenureSolver {
  // ─── Core Engine ────────────────────────────────────────────────────────────

  @override
  CompoundResult calculate(CompoundInput input) {
    final breakdown = <CompoundBreakdownEntry>[];
    double balance = input.principal;
    double totalInvested = input.principal;
    double totalWithdrawn = 0;

    final double periodicRate =
        (input.annualRate / 100) / input.compoundFrequency.periodsPerYear;

    final int totalPeriods = _totalCompoundPeriods(
      tenureMonths: input.tenureMonths,
      compoundFrequency: input.compoundFrequency,
    );

    // Unpack contribution config — null means no contributions
    final contrib = input.contribution;
    final double periodsPerContribution = contrib != null
        ? input.compoundFrequency.periodsPerYear /
              contrib.frequency.periodsPerYear
        : double.infinity;

    // Unpack withdrawal config — null means no withdrawals
    final withdrawal = input.withdrawal;
    final double periodsPerWithdrawal = withdrawal != null
        ? input.compoundFrequency.periodsPerYear /
              withdrawal.frequency.periodsPerYear
        : double.infinity;

    // Mutable amounts — mutated by step-up logic each cycle
    double currentContribution = contrib?.amount ?? 0;
    double currentWithdrawal = withdrawal?.amount ?? 0;

    // Track fired step-up event counts to detect new cycles
    int contributionStepUpCount = 0;
    int withdrawalStepUpCount = 0;

    for (int period = 1; period <= totalPeriods; period++) {
      final int year = _yearOf(period, input.compoundFrequency);
      final double opening = balance;

      // ── Contribution step-up ──────────────────────────────────────────────
      if (contrib != null && contrib.stepUp != null) {
        final int newCount = _stepUpEventCount(
          period: period,
          compoundFrequency: input.compoundFrequency,
          stepUpFrequency: contrib.stepUp!.stepUpFrequency,
        );
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
        final int newCount = _stepUpEventCount(
          period: period,
          compoundFrequency: input.compoundFrequency,
          stepUpFrequency: withdrawal.stepUp!.stepUpFrequency,
        );
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
      final bool hasContribution =
          contrib != null &&
          _isContributionPeriod(period, periodsPerContribution);

      final bool hasWithdrawal =
          withdrawal != null &&
          currentWithdrawal > 0 &&
          _isContributionPeriod(period, periodsPerWithdrawal);

      // ── Annuity-due: contribute BEFORE interest ───────────────────────────
      double contributionThisPeriod = 0;
      if (hasContribution && contrib.timing == PaymentTiming.beginning) {
        contributionThisPeriod = currentContribution;
        totalInvested += contributionThisPeriod;
        balance += contributionThisPeriod;
      }

      // ── Compound interest ─────────────────────────────────────────────────
      final double interest = balance * periodicRate;
      balance += interest;

      // ── Ordinary annuity: contribute AFTER interest ───────────────────────
      if (hasContribution && contrib.timing == PaymentTiming.end) {
        contributionThisPeriod = currentContribution;
        totalInvested += contributionThisPeriod;
        balance += contributionThisPeriod;
      }

      // ── Withdrawal (always end-of-period) ─────────────────────────────────
      double withdrawalThisPeriod = 0;
      bool exhausted = false;
      if (hasWithdrawal) {
        if (currentWithdrawal >= balance) {
          withdrawalThisPeriod = balance;
          exhausted = true;
        } else {
          withdrawalThisPeriod = currentWithdrawal;
        }
        totalWithdrawn += withdrawalThisPeriod;
        balance -= withdrawalThisPeriod;
      }

      breakdown.add(
        CompoundBreakdownEntry(
          period: period,
          year: year,
          openingBalance: opening,
          contributionThisPeriod: contributionThisPeriod,
          interestThisPeriod: interest,
          withdrawalThisPeriod: withdrawalThisPeriod,
          closingBalance: balance,
          cumulativeInvested: totalInvested,
          cumulativeWithdrawn: totalWithdrawn,
          balanceExhausted: exhausted,
        ),
      );

      if (exhausted) break;
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

  // ─── Private: Period Helpers ──────────────────────────────────────────────────

  int _totalCompoundPeriods({
    required int tenureMonths,
    required CompoundFrequency compoundFrequency,
  }) {
    return ((tenureMonths / 12) * compoundFrequency.periodsPerYear).round();
  }

  int _yearOf(int period, CompoundFrequency compoundFrequency) {
    return ((period - 1) / compoundFrequency.periodsPerYear).floor() + 1;
  }

  /// How many step-up events have fired by the start of [period].
  ///
  /// Fires once per completed step-up cycle (first event at start of cycle 2).
  int _stepUpEventCount({
    required int period,
    required CompoundFrequency compoundFrequency,
    required PaymentFrequency stepUpFrequency,
  }) {
    final double periodsPerStepUp =
        compoundFrequency.periodsPerYear / stepUpFrequency.periodsPerYear;
    return ((period - 1) / periodsPerStepUp).floor();
  }

  /// Whether a contribution/withdrawal should occur on this compounding period.
  bool _isContributionPeriod(int period, double periodsPerContribution) {
    final expected = (period / periodsPerContribution).round();
    final previous = ((period - 1) / periodsPerContribution).round();
    return expected != previous;
  }
}
