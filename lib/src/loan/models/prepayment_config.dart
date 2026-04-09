enum PrepaymentType { oneTime, recurring }

/// Configuration for a specific extra payment.
final class PrepaymentConfig {
  final double amount;
  final int month;
  final PrepaymentType type;
  
  /// For recurring, how many months it should last. 
  /// If null, lasts until loan ends.
  final int? durationMonths;

  const PrepaymentConfig({
    required this.amount,
    required this.month,
    this.type = PrepaymentType.oneTime,
    this.durationMonths,
  });
}

/// Configuration for early full payoff of the loan.
final class ForeclosureConfig {
  final int month;
  
  /// Fee as a percentage of outstanding principal (e.g. 2.0 for 2%).
  final double feePercentage;

  const ForeclosureConfig({
    required this.month,
    this.feePercentage = 0,
  });
}
