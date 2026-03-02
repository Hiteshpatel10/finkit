import 'compound_frequency.dart';

/// The single input model for all compound interest calculations.
///
/// This is the source of truth for SIP, lumpsum, and combined scenarios.
///
/// How each use case maps to this model:
///
/// **Lumpsum only** (one-time investment, no contributions):
/// ```dart
/// CompoundInput(principal: 100000, contribution: 0, ...)
/// ```
///
/// **SIP only** (regular contributions, no lumpsum):
/// ```dart
/// CompoundInput(principal: 0, contribution: 5000, ...)
/// ```
///
/// **Combined** (lumpsum + regular top-ups):
/// ```dart
/// CompoundInput(principal: 100000, contribution: 5000, ...)
/// ```
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

  /// Optional: annual % rate at which the contribution amount grows.
  ///
  /// Example: contribution = ₹5000, annualContributionGrowthRate = 10
  /// means the contribution increases by 10% every year.
  /// Use 0 for flat contributions.
  final double annualContributionGrowthRate;

  const CompoundInput({
    required this.principal,
    required this.annualRate,
    required this.tenureMonths,
    required this.contribution,
    this.compoundFrequency = CompoundFrequency.monthly,
    this.contributionFrequency = ContributionFrequency.monthly,
    this.annualContributionGrowthRate = 0,
  });

  CompoundInput copyWith({
    double? principal,
    double? annualRate,
    int? tenureMonths,
    CompoundFrequency? compoundFrequency,
    double? contribution,
    ContributionFrequency? contributionFrequency,
    double? annualContributionGrowthRate,
  }) {
    return CompoundInput(
      principal: principal ?? this.principal,
      annualRate: annualRate ?? this.annualRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      compoundFrequency: compoundFrequency ?? this.compoundFrequency,
      contribution: contribution ?? this.contribution,
      contributionFrequency: contributionFrequency ?? this.contributionFrequency,
      annualContributionGrowthRate:
          annualContributionGrowthRate ?? this.annualContributionGrowthRate,
    );
  }
}

/// How often regular contributions are made.
enum ContributionFrequency {
  daily(365),
  weekly(52),
  monthly(12),
  quarterly(4),
  halfYearly(2),
  yearly(1);

  /// Number of contribution periods per year.
  final int periodsPerYear;

  const ContributionFrequency(this.periodsPerYear);
}
