import 'compound_frequency.dart';
import 'contribution_frequency.dart';

/// Defines how the contribution amount increases over time.
sealed class ContributionStepUp {
  const ContributionStepUp();
}

/// Contribution increases by a fixed amount each year.
/// e.g. ₹500/year → ₹5000, ₹5500, ₹6000 ...
class FixedStepUp extends ContributionStepUp {
  /// Amount to add to the contribution each year.
  final double amountPerYear;
  const FixedStepUp(this.amountPerYear);
}

/// Contribution increases by a % of the *current* contribution each year.
/// e.g. 10%/year → ₹5000, ₹5500, ₹6050 ... (compounds)
class PercentageStepUp extends ContributionStepUp {
  /// Percentage increase per year (e.g. 10 means 10%).
  final double percentPerYear;
  const PercentageStepUp(this.percentPerYear);
}

/// The single input model for all compound interest calculations.
class CompoundInput {
  /// One-time initial investment. Use 0 for pure SIP.
  final double principal;

  /// Expected annual return rate (%).
  final double annualRate;

  /// Total investment duration in months.
  final int tenureMonths;

  /// How often interest is compounded per year.
  final CompoundFrequency compoundFrequency;

  /// Regular contribution amount per [contributionFrequency] period.
  /// Use 0 for pure lumpsum.
  final double contribution;

  /// How often contributions are made.
  final ContributionFrequency contributionFrequency;

  /// Optional step-up rule for contributions. Null means flat contributions.
  ///
  /// Step-up is always applied yearly, at the start of each new year.
  ///
  /// Examples:
  /// ```dart
  /// stepUp: FixedStepUp(500)        // +₹500 every year
  /// stepUp: PercentageStepUp(10)    // +10% of current amount every year
  /// stepUp: null                    // flat, no increase
  /// ```
  final ContributionStepUp? stepUp;

  const CompoundInput({
    required this.principal,
    required this.annualRate,
    required this.tenureMonths,
    required this.contribution,
    this.compoundFrequency = CompoundFrequency.monthly,
    this.contributionFrequency = ContributionFrequency.monthly,
    this.stepUp,
  });

  CompoundInput copyWith({
    double? principal,
    double? annualRate,
    int? tenureMonths,
    CompoundFrequency? compoundFrequency,
    double? contribution,
    ContributionFrequency? contributionFrequency,
    ContributionStepUp? stepUp,
    bool clearStepUp = false,
  }) {
    return CompoundInput(
      principal: principal ?? this.principal,
      annualRate: annualRate ?? this.annualRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      compoundFrequency: compoundFrequency ?? this.compoundFrequency,
      contribution: contribution ?? this.contribution,
      contributionFrequency:
          contributionFrequency ?? this.contributionFrequency,
      stepUp: clearStepUp ? null : (stepUp ?? this.stepUp),
    );
  }
}
