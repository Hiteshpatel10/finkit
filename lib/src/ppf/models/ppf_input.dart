import 'package:finkit/src/compound/models/payment_config.dart';

/// Input parameters for a Public Provident Fund (PPF) calculation.
final class PpfInput {
  /// The amount deposited per period.
  /// Minimum total yearly deposit is ₹500, maximum is ₹1,50,000.
  final double depositAmount;

  /// How often the deposit is made. Usually [PaymentFrequency.yearly] or [PaymentFrequency.monthly].
  final PaymentFrequency depositFrequency;

  /// The timing of the deposit within the period.
  ///
  /// For PPF, interest is calculated on the lowest balance between the 5th and end of the month.
  /// - Use [PaymentTiming.beginning] to simulate deposits made on or before the 5th.
  /// - Use [PaymentTiming.end] to simulate deposits made after the 5th.
  final PaymentTiming depositTiming;

  /// The duration of the PPF investment in years. Standard is 15 years.
  final int tenureYears;

  /// The annual interest rate set by the government. Default is typically 7.1%.
  final double annualInterestRate;

  const PpfInput({
    required this.depositAmount,
    this.depositFrequency = PaymentFrequency.yearly,
    this.depositTiming = PaymentTiming.beginning,
    this.tenureYears = 15,
    this.annualInterestRate = 7.1,
  });
}
