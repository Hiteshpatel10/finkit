import 'package:finkit/src/compound/models/payment_config.dart';

/// Configuration for periodic contributions (SIP / top-ups).
/// Examples:
/// ```dart
/// // Plain ₹5 000/month
/// ContributionConfig(amount: 5000)
///
/// // ₹5 000/month, contributed at the start of each period
/// ContributionConfig(
///   amount: 5000,
///   timing: ContributionTiming.beginning,
/// )
///
/// // ₹5 000/month stepping up 10% every year
/// ContributionConfig(
///   amount: 5000,
///   stepUp: PercentageStepUp(10),
/// )
///
/// // ₹5 000/quarter, +₹500 every 6 months
/// ContributionConfig(
///   amount: 5000,
///   frequency: PaymentFrequency.quarterly,
///   stepUp: FixedStepUp(500, stepUpFrequency: StepUpFrequency.halfYearly),
/// )
/// ```
final class ContributionConfig {
  /// Amount to contribute per [frequency] period.
  final double amount;

  /// How often contributions are made. Defaults to monthly.
  final PaymentFrequency frequency;

  /// Whether contributions are applied at the start or end of each period.
  ///
  /// - [PaymentTiming.beginning] (annuity-due): applied *before* interest
  ///   compounds — each rupee earns one extra period of interest.
  /// - [PaymentTiming.end] (ordinary annuity, **default**): applied *after*
  ///   interest compounds. Matches most SIP calculators.
  final PaymentTiming timing;

  /// Optional step-up rule. Null means flat contributions throughout.
  final ContributionStepUp? stepUp;

  const ContributionConfig({
    required this.amount,
    this.frequency = PaymentFrequency.monthly,
    this.timing = PaymentTiming.end,
    this.stepUp,
  });

  ContributionConfig copyWith({
    double? amount,
    PaymentFrequency? frequency,
    PaymentTiming? timing,
    ContributionStepUp? stepUp,
    bool clearStepUp = false,
  }) {
    return ContributionConfig(
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      timing: timing ?? this.timing,
      stepUp: clearStepUp ? null : (stepUp ?? this.stepUp),
    );
  }
}

/// Defines how the contribution amount increases over time.
///
/// Both subtypes accept an optional [stepUpFrequency] that controls *how often*
/// the step-up is applied. Defaults to [StepUpFrequency.yearly].
sealed class ContributionStepUp {
  final StepUpFrequency stepUpFrequency;
  const ContributionStepUp({this.stepUpFrequency = StepUpFrequency.yearly});
}

/// Contribution increases by a fixed amount every [stepUpFrequency] period.
class FixedStepUp extends ContributionStepUp {
  final double amount;
  const FixedStepUp(
    this.amount, {
    super.stepUpFrequency = StepUpFrequency.yearly,
  });
}

/// Contribution increases by a % of the current amount every [stepUpFrequency] period.
class PercentageStepUp extends ContributionStepUp {
  final double percent;
  const PercentageStepUp(
    this.percent, {
    super.stepUpFrequency = StepUpFrequency.yearly,
  });
}
