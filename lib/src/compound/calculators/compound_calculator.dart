import 'package:finkit/src/compound/models/compound_frequency.dart';
import 'package:finkit/src/compound/models/compound_input.dart';
import 'package:finkit/src/compound/models/compound_result.dart';
import 'package:finkit/src/compound/models/contribution_frequency.dart';
import 'compound_interfaces.dart';

/// The core compound interest engine — single source of truth for all
/// investment calculations in finkit.
///
/// Unified formula:
///   M = P × (1 + r/f)^(f×n)
///     + Σ [ C(t) × (1 + r/f)^(f × remaining_years(t)) ]
///
/// where:
///   P    = principal (lumpsum)
///   r    = annual rate (decimal)
///   f    = compounding periods per year
///   n    = total years
///   C(t) = contribution at time t — stepped up yearly via [ContributionStepUp]
///
/// Special cases:
///   P = 0          → pure SIP
///   contribution=0 → pure lumpsum
///   both > 0       → combined (lumpsum + regular top-ups)
///
/// **Step-up behaviour**:
///   - [FixedStepUp]      → currentContribution += amountPerYear  (linear growth)
///   - [PercentageStepUp] → currentContribution *= (1 + rate)     (compounding growth)
///   - null               → flat contributions throughout
///
/// This class is the delegate for [SipCalculator] and [LumpsumCalculator].
class CompoundCalculator
    implements
        CompoundMaturitySolver,
        CompoundContributionSolver,
        CompoundRateSolver,
        CompoundTenureSolver {
  // ─── Core Engine ────────────────────────────────────────────────────────────

  /// The main calculation method. Returns a full [CompoundResult] including
  /// period-by-period breakdown and yearly summary.
  ///
  /// Strategy: simulate period-by-period to correctly handle:
  ///   - mismatched compounding vs contribution frequencies
  ///   - yearly contribution step-up (fixed amount or percentage)
  ///   - partial periods at the end of tenure
  @override
  CompoundResult calculate(CompoundInput input) {
    final breakdown = <CompoundBreakdownEntry>[];
    double balance = input.principal;
    double totalInvested = input.principal;

    // Periodic rate: annualRate / compoundPeriodsPerYear
    final double periodicRate =
        (input.annualRate / 100) / input.compoundFrequency.periodsPerYear;

    // How many compounding periods fit in the tenure
    final int totalPeriods = _totalCompoundPeriods(
      tenureMonths: input.tenureMonths,
      compoundFrequency: input.compoundFrequency,
    );

    // How many compounding periods correspond to one contribution cycle.
    // e.g. monthly contribution + monthly compounding  = 1 period per contribution
    //      quarterly contribution + monthly compounding = 3 periods per contribution
    final double periodsPerContribution =
        input.compoundFrequency.periodsPerYear /
        input.contributionFrequency.periodsPerYear;

    // Tracks the current contribution amount — mutated by step-up logic each year
    double currentContribution = input.contribution;

    for (int period = 1; period <= totalPeriods; period++) {
      final int year = _yearOf(period, input.compoundFrequency);
      final double opening = balance;

      // ── Apply yearly step-up at the start of each new year (year > 1) ───────
      if (input.contribution > 0 &&
          input.stepUp != null &&
          period > 1 &&
          _isFirstPeriodOfYear(period, input.compoundFrequency)) {
        switch (input.stepUp) {
          case FixedStepUp(:final amountPerYear):
            currentContribution += amountPerYear;
          case PercentageStepUp(:final percentPerYear):
            currentContribution *= (1 + percentPerYear / 100);
          case null:
            break; // unreachable — guarded above, satisfies exhaustiveness
        }
      }

      // ── Apply contribution if this period aligns with contribution schedule ──
      double contributionThisPeriod = 0;

      if (input.contribution > 0 &&
          _isContributionPeriod(period, periodsPerContribution)) {
        contributionThisPeriod = currentContribution;
        totalInvested += contributionThisPeriod;
        balance += contributionThisPeriod;
      }

      // ── Compound interest on balance (after contribution) ───────────────────
      final double interest = balance * periodicRate;
      balance += interest;

      breakdown.add(
        CompoundBreakdownEntry(
          period: period,
          year: year,
          openingBalance: opening,
          contributionThisPeriod: contributionThisPeriod,
          interestThisPeriod: interest,
          closingBalance: balance,
          cumulativeInvested: totalInvested,
        ),
      );
    }

    final maturity = balance;
    final totalInterest = maturity - totalInvested;

    return CompoundResult(
      maturityAmount: maturity,
      totalInvested: totalInvested,
      totalInterest: totalInterest,
      breakdown: List.unmodifiable(breakdown),
    );
  }

  // ─── Contribution Solver ────────────────────────────────────────────────────

  // No closed-form when step-up is active or frequencies differ.
  // Bisection is used universally for correctness across all configurations.
  @override
  double calculateRequiredContribution({
    required double targetAmount,
    required double principal,
    required double annualRate,
    required int tenureMonths,
    ContributionFrequency contributionFrequency = ContributionFrequency.monthly,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
    ContributionStepUp? stepUp,
  }) {
    // Maturity is monotonically increasing with contribution → bisection valid
    double low = 0;
    double high =
        targetAmount; // upper bound: contribute entire target every period
    double mid = 0;

    for (int i = 0; i < 100; i++) {
      mid = (low + high) / 2;

      final result = calculate(
        CompoundInput(
          principal: principal,
          annualRate: annualRate,
          tenureMonths: tenureMonths,
          contribution: mid,
          contributionFrequency: contributionFrequency,
          compoundFrequency: compoundFrequency,
          stepUp: stepUp,
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

  // ─── Rate Solver ────────────────────────────────────────────────────────────

  // No closed-form for rate when contributions are involved.
  // Newton-Raphson with bisection fallback.
  @override
  double calculateRequiredRate({
    required double targetAmount,
    required double principal,
    required double contribution,
    required int tenureMonths,
    ContributionFrequency contributionFrequency = ContributionFrequency.monthly,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
    ContributionStepUp? stepUp,
  }) {
    CompoundResult maturityAt(double annualRate) => calculate(
      CompoundInput(
        principal: principal,
        annualRate: annualRate,
        tenureMonths: tenureMonths,
        contribution: contribution,
        contributionFrequency: contributionFrequency,
        compoundFrequency: compoundFrequency,
        stepUp: stepUp,
      ),
    );

    try {
      return _newtonRaphsonRate(targetAmount, maturityAt);
    } catch (_) {
      return _bisectionRate(targetAmount, maturityAt);
    }
  }

  // ─── Tenure Solver ──────────────────────────────────────────────────────────

  // Maturity grows monotonically with tenure → integer bisection.
  @override
  int calculateRequiredTenure({
    required double targetAmount,
    required double principal,
    required double annualRate,
    required double contribution,
    ContributionFrequency contributionFrequency = ContributionFrequency.monthly,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
    ContributionStepUp? stepUp,
  }) {
    int low = 1;
    int high = 1200; // 100 years in months upper bound

    while (low < high) {
      final mid = (low + high) ~/ 2;

      final result = calculate(
        CompoundInput(
          principal: principal,
          annualRate: annualRate,
          tenureMonths: mid,
          contribution: contribution,
          contributionFrequency: contributionFrequency,
          compoundFrequency: compoundFrequency,
          stepUp: stepUp,
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

  // ─── Private: Numerical Methods ─────────────────────────────────────────────

  /// Newton-Raphson for rate.
  ///
  /// Approximates derivative numerically (finite difference) since the
  /// simulation-based approach has no analytical derivative.
  ///
  ///   f(r)  = maturity(r) − target  →  find root
  ///   f'(r) ≈ (maturity(r + h) − maturity(r)) / h   [numerical derivative]
  ///   r₁    = r₀ − f(r₀) / f'(r₀)
  double _newtonRaphsonRate(
    double target,
    CompoundResult Function(double) maturityAt,
  ) {
    double r = 10.0; // initial guess: 10% annual
    const h = 0.0001; // finite difference step

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

      if ((next - r).abs() < 1e-8) {
        return next;
      }

      r = next;
    }

    return r;
  }

  /// Bisection fallback for rate.
  /// Maturity is monotonically increasing with rate → valid.
  double _bisectionRate(
    double target,
    CompoundResult Function(double) maturityAt,
  ) {
    double low = 0.0;
    double high = 200.0; // 200% annual rate cap
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

  // ─── Private: Period Helpers ─────────────────────────────────────────────────

  /// Total number of compounding periods for the given tenure.
  int _totalCompoundPeriods({
    required int tenureMonths,
    required CompoundFrequency compoundFrequency,
  }) {
    return ((tenureMonths / 12) * compoundFrequency.periodsPerYear).round();
  }

  /// Which calendar year (1-based) a given period belongs to.
  int _yearOf(int period, CompoundFrequency compoundFrequency) {
    return ((period - 1) / compoundFrequency.periodsPerYear).floor() + 1;
  }

  /// Whether this period is the first period of a new year.
  bool _isFirstPeriodOfYear(int period, CompoundFrequency compoundFrequency) {
    return (period - 1) % compoundFrequency.periodsPerYear == 0;
  }

  /// Whether a contribution should be made on this compounding period.
  ///
  /// Handles mismatched frequencies:
  ///   e.g. monthly contribution + daily compounding → contribute every ~30 periods
  bool _isContributionPeriod(int period, double periodsPerContribution) {
    // Rounding handles non-integer ratios (e.g. weekly contributions
    // with monthly compounding)
    final expected = (period / periodsPerContribution).round();
    final previous = ((period - 1) / periodsPerContribution).round();
    return expected != previous;
  }
}
