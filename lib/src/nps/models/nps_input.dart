/// Input parameters for a National Pension System (NPS) calculation.
final class NpsInput {
  /// The current age of the individual.
  final int currentAge;

  /// The expected retirement age (usually 60).
  final int retirementAge;

  /// The monthly contribution amount.
  final double monthlyContribution;

  /// The expected rate of return (CAGR) on the NPS investments.
  final double expectedReturnRate;

  /// The percentage of the final corpus used to purchase an annuity.
  /// Mandatory minimum is 40%.
  final double annuityPurchasePercentage;

  /// The expected interest rate on the annuity to generate the monthly pension.
  final double expectedAnnuityRate;

  /// Optional: Existing NPS account balance.
  final double currentNpsBalance;

  const NpsInput({
    required this.currentAge,
    this.retirementAge = 60,
    required this.monthlyContribution,
    required this.expectedReturnRate,
    this.annuityPurchasePercentage = 40.0,
    required this.expectedAnnuityRate,
    this.currentNpsBalance = 0.0,
  });
}
