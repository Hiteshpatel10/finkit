/// A single row in a loan amortization schedule.
///
/// Each entry represents one month's payment breakdown.
final class AmortizationEntry {
  final int month;
  final double openingBalance;
  final double emi;
  final double interest;
  final double principal;
  final double closingBalance;

  const AmortizationEntry({
    required this.month,
    required this.openingBalance,
    required this.emi,
    required this.interest,
    required this.principal,
    required this.closingBalance,
  });
}
