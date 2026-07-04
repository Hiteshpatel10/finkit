/// A single dated cash flow for use in XIRR calculations.
///
/// Sign convention matches Excel / Google Sheets XIRR():
/// - **Negative** amounts represent **outflows** (investments / purchases).
/// - **Positive** amounts represent **inflows** (redemptions / dividends / maturity).
///
/// Example — 12-month SIP then full redemption:
/// ```dart
/// final cashFlows = [
///   XirrCashFlow(date: DateTime(2023, 1, 1), amount: -5000),
///   XirrCashFlow(date: DateTime(2023, 2, 1), amount: -5000),
///   // … more monthly investments …
///   XirrCashFlow(date: DateTime(2023, 12, 1), amount: -5000),
///   XirrCashFlow(date: DateTime(2024, 1, 1), amount: 65000), // redemption
/// ];
/// ```
final class XirrCashFlow {
  /// The date on which this cash flow occurs.
  final DateTime date;

  /// The cash flow amount.
  ///
  /// Negative → money going out (investment).
  /// Positive → money coming in (redemption / maturity).
  final double amount;

  const XirrCashFlow({
    required this.date,
    required this.amount,
  });

  @override
  String toString() => 'XirrCashFlow(date: $date, amount: $amount)';
}
