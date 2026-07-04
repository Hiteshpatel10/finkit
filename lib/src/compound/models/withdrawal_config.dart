import 'package:finkit/src/compound/models/payment_config.dart';

// ─── Withdrawal Step-Up ──────────────────────────────────────────────────────

/// Defines how the withdrawal amount changes over time.
///
/// Both subtypes accept an optional [stepUpFrequency] that controls *how often*
/// the step-up is applied. Defaults to [PaymentFrequency.yearly].
///
/// Examples:
/// ```dart
/// // +₹1 000 every year (default)
/// FixedWithdrawalStepUp(1000)
///
/// // +₹1 000 every 6 months
/// FixedWithdrawalStepUp(1000, stepUpFrequency: StepUpFrequency.halfYearly)
///
/// // +5% every year (default)
/// PercentageWithdrawalStepUp(5)
///
/// // +5% every quarter
/// PercentageWithdrawalStepUp(5, stepUpFrequency: StepUpFrequency.quarterly)
/// ```
sealed class WithdrawalStepUp {
  /// How often the step-up is applied. Defaults to [StepUpFrequency.yearly].
  final StepUpFrequency stepUpFrequency;
  const WithdrawalStepUp({this.stepUpFrequency = StepUpFrequency.yearly});
}

/// Withdrawal increases by a fixed amount every [stepUpFrequency] period.
/// e.g. ₹1 000/year → ₹10 000, ₹11 000, ₹12 000 …
class FixedWithdrawalStepUp extends WithdrawalStepUp {
  /// Amount added to the withdrawal on each step-up event.
  final double amount;
  const FixedWithdrawalStepUp(
    this.amount, {
    super.stepUpFrequency = StepUpFrequency.yearly,
  });
}

/// Withdrawal increases by a % of the *current* withdrawal every
/// [stepUpFrequency] period.
/// e.g. 10 %/year → ₹10 000, ₹11 000, ₹12 100 … (compounds)
class PercentageWithdrawalStepUp extends WithdrawalStepUp {
  /// Percentage increase per step-up event (e.g. 10 means 10 %).
  final double percent;
  const PercentageWithdrawalStepUp(
    this.percent, {
    super.stepUpFrequency = StepUpFrequency.yearly,
  });
}

// ─── Withdrawal Type ─────────────────────────────────────────────────────────

/// Determines how the withdrawal amount is interpreted.
enum WithdrawalType {
  /// Withdraws a fixed monetary amount (e.g. ₹10,000) every period.
  fixedAmount,

  /// Withdraws a percentage of the total accumulated balance every period.
  percentageOfBalance,

  /// Withdraws a percentage of the total earnings (interest) every period.
  percentageOfEarnings,
}

// ─── Withdrawal Config ───────────────────────────────────────────────────────

/// Configuration for periodic withdrawals from the corpus.
///
/// Withdrawals happen *after* interest is applied for the period (end-of-period).
/// This mirrors the behaviour of a Systematic Withdrawal Plan (SWP).
///
/// If the balance would go below zero after a withdrawal, the remaining
/// balance is withdrawn and the corpus is exhausted. The calculator
/// records this via [CompoundBreakdownEntry.balanceExhausted].
///
/// Example — ₹10 000/month withdrawal, stepping up 5 % every year:
/// ```dart
/// withdrawal: WithdrawalConfig(
///   amount: 10000,
///   frequency: ContributionFrequency.monthly,
///   stepUp: PercentageWithdrawalStepUp(5),
/// )
/// ```
final class WithdrawalConfig {
  /// Amount to withdraw per [frequency] period.
  /// If [type] is [WithdrawalType.percentageOfBalance] or [WithdrawalType.percentageOfEarnings], 
  /// this represents the percentage (e.g., 5 means 5%).
  final double amount;

  /// How often withdrawals are made.
  final PaymentFrequency frequency;

  /// Determines how the [amount] is interpreted (fixed vs percentage).
  final WithdrawalType type;

  /// Optional yearly step-up. Null means flat withdrawals throughout.
  final WithdrawalStepUp? stepUp;

  const WithdrawalConfig({
    required this.amount,
    this.frequency = PaymentFrequency.monthly,
    this.type = WithdrawalType.fixedAmount,
    this.stepUp,
  });

  WithdrawalConfig copyWith({
    double? amount,
    PaymentFrequency? frequency,
    WithdrawalType? type,
    WithdrawalStepUp? stepUp,
    bool clearStepUp = false,
  }) {
    return WithdrawalConfig(
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      type: type ?? this.type,
      stepUp: clearStepUp ? null : (stepUp ?? this.stepUp),
    );
  }
}
