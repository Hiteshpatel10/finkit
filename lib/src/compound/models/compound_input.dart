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

final class CompoundInput {
  /// One-time initial investment. Use 0 for pure SIP.
  final double principal;

  /// Expected annual return rate (%).
  final double annualRate;

  /// Total investment duration in months.
  final int tenureMonths;

  /// How often interest is compounded per year.
  final CompoundFrequency compoundFrequency;

  /// Custom number of compounding periods per year (used if compoundFrequency is custom).
  final int? customCompoundPeriods;

  /// Periodic contribution config. Null means no contributions (pure lumpsum / SWP).
  final ContributionConfig? contribution;

  /// Periodic withdrawal config. Null means no withdrawals.
  final WithdrawalConfig? withdrawal;

  const CompoundInput({
    required this.principal,
    required this.annualRate,
    required this.tenureMonths,
    this.compoundFrequency = CompoundFrequency.monthly,
    this.customCompoundPeriods,
    this.contribution,
    this.withdrawal,
  });

  /// Creates a pure **SIP** configuration (no initial lumpsum).
  factory CompoundInput.sip({
    required double monthlyAmount,
    required double annualRate,
    required int tenureMonths,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
  }) {
    return CompoundInput(
      principal: 0,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
      compoundFrequency: compoundFrequency,
      customCompoundPeriods: null,
      contribution: ContributionConfig(amount: monthlyAmount),
    );
  }

  /// Creates a pure **lumpsum** configuration (no periodic contributions).
  factory CompoundInput.lumpsum({
    required double principal,
    required double annualRate,
    required int tenureMonths,
    CompoundFrequency compoundFrequency = CompoundFrequency.yearly,
  }) {
    return CompoundInput(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
      compoundFrequency: compoundFrequency,
      customCompoundPeriods: null,
    );
  }

  /// Creates an **SWP** (Systematic Withdrawal Plan) configuration.
  factory CompoundInput.swp({
    required double principal,
    required double monthlyWithdrawal,
    required double annualRate,
    required int tenureMonths,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
  }) {
    return CompoundInput(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
      compoundFrequency: compoundFrequency,
      customCompoundPeriods: null,
      withdrawal: WithdrawalConfig(amount: monthlyWithdrawal),
    );
  }

  /// Creates a **step-up SIP** configuration (contributions increase over time).
  factory CompoundInput.stepUpSip({
    required double monthlyAmount,
    required double annualRate,
    required int tenureMonths,
    required double annualStepUpPercent,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
  }) {
    return CompoundInput(
      principal: 0,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
      compoundFrequency: compoundFrequency,
      customCompoundPeriods: null,
      contribution: ContributionConfig(
        amount: monthlyAmount,
        stepUp: PercentageStepUp(annualStepUpPercent),
      ),
    );
  }

  /// Creates a **lumpsum + SIP** configuration (one-time investment with monthly top-ups).
  factory CompoundInput.lumpsumPlusSip({
    required double principal,
    required double monthlyAmount,
    required double annualRate,
    required int tenureMonths,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
  }) {
    return CompoundInput(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
      compoundFrequency: compoundFrequency,
      customCompoundPeriods: null,
      contribution: ContributionConfig(amount: monthlyAmount),
    );
  }

  CompoundInput copyWith({
    double? principal,
    double? annualRate,
    int? tenureMonths,
    CompoundFrequency? compoundFrequency,
    int? customCompoundPeriods,
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
      customCompoundPeriods: customCompoundPeriods ?? this.customCompoundPeriods,
      contribution:
          clearContribution ? null : (contribution ?? this.contribution),
      withdrawal: clearWithdrawal ? null : (withdrawal ?? this.withdrawal),
    );
  }
}
