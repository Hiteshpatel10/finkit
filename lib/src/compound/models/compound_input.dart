import 'package:finkit/src/compound/models/contribution_config.dart';

import 'compound_frequency.dart';
import 'withdrawal_config.dart';

/// The single input model for all compound interest calculations.
///
/// Both contribution and withdrawal are optional config objects.
/// Null means that side is inactive:
///
/// | Scenario          | contribution | withdrawal |
/// |-------------------|--------------|------------|
/// | Pure SIP          | set          | null       |
/// | Pure lumpsum      | null         | null       |
/// | Lumpsum + SIP     | set          | null       |
/// | SWP               | null         | set        |
/// | SIP + SWP         | set          | set        |
///
/// Examples:
/// ```dart
/// // Pure SIP
/// CompoundInput(
///   principal: 0,
///   annualRate: 12,
///   tenureMonths: 120,
///   contribution: ContributionConfig(amount: 5000),
/// )
///
/// // Lumpsum
/// CompoundInput(
///   principal: 100000,
///   annualRate: 12,
///   tenureMonths: 120,
/// )
///
/// // SWP
/// CompoundInput(
///   principal: 1000000,
///   annualRate: 8,
///   tenureMonths: 240,
///   withdrawal: WithdrawalConfig(amount: 10000),
/// )
///
/// // Step-up SIP
/// CompoundInput(
///   principal: 0,
///   annualRate: 12,
///   tenureMonths: 120,
///   contribution: ContributionConfig(
///     amount: 5000,
///     stepUp: PercentageStepUp(10),
///   ),
/// )
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

  /// Periodic contribution config. Null means no contributions (pure lumpsum / SWP).
  final ContributionConfig? contribution;

  /// Periodic withdrawal config. Null means no withdrawals.
  final WithdrawalConfig? withdrawal;

  const CompoundInput({
    required this.principal,
    required this.annualRate,
    required this.tenureMonths,
    this.compoundFrequency = CompoundFrequency.monthly,
    this.contribution,
    this.withdrawal,
  });

  CompoundInput copyWith({
    double? principal,
    double? annualRate,
    int? tenureMonths,
    CompoundFrequency? compoundFrequency,
    ContributionConfig? contribution,
    bool clearContribution = false,
    WithdrawalConfig? withdrawal,
    bool clearWithdrawal = false,
  }) {
    return CompoundInput(
      principal: principal ?? this.principal,
      annualRate: annualRate ?? this.annualRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      compoundFrequency: compoundFrequency ?? this.compoundFrequency,
      contribution: clearContribution
          ? null
          : (contribution ?? this.contribution),
      withdrawal: clearWithdrawal ? null : (withdrawal ?? this.withdrawal),
    );
  }
}
