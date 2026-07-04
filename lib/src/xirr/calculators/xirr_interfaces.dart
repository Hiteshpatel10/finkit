import 'package:finkit/src/xirr/models/xirr_cash_flow.dart';
import 'package:finkit/src/xirr/models/xirr_result.dart';

/// Contract for computing XIRR (Extended Internal Rate of Return).
///
/// XIRR calculates the annualized rate of return for an irregular series of
/// cash flows (i.e., flows that do not occur at equal intervals).
///
/// Sign convention (matches Excel / Google Sheets):
/// - Negative cash flows = outflows (investments).
/// - Positive cash flows = inflows (redemptions / maturity).
///
/// Usage:
/// ```dart
/// final registry = XirrCalculatorFactory().create(XirrType.standard);
/// final solver   = registry.require<XirrSolver>();
///
/// final result = solver.calculate([
///   XirrCashFlow(date: DateTime(2023, 1, 1),  amount: -10000),
///   XirrCashFlow(date: DateTime(2024, 1, 1),  amount:  11000),
/// ]);
///
/// print(result.annualizedReturn); // ≈ 10.0
/// ```
abstract interface class XirrSolver {
  /// Calculates XIRR for the given list of [cashFlows].
  ///
  /// Throws [ArgumentError] if:
  /// - [cashFlows] has fewer than 2 entries.
  /// - All amounts share the same sign (no investment + redemption mix).
  /// - All cash flows fall on the same date.
  XirrResult calculate(List<XirrCashFlow> cashFlows);
}
