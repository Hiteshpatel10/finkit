import 'package:finkit/src/ppf/models/ppf_input.dart';
import 'package:finkit/src/ppf/models/ppf_result.dart';

/// Calculates the maturity value and schedule for a PPF investment.
abstract interface class PpfMaturitySolver {
  /// Calculates PPF returns based on the provided [input].
  ///
  /// Throws an [ArgumentError] if the yearly deposit exceeds the maximum allowed
  /// (₹1,50,000) or falls below the minimum required (₹500).
  PpfResult calculateMaturity(PpfInput input);
}
