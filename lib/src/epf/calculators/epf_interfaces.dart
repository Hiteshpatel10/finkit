import 'package:finkit/src/epf/models/epf_input.dart';
import 'package:finkit/src/epf/models/epf_result.dart';

/// Calculates the maturity value and schedule for an EPF investment.
abstract interface class EpfMaturitySolver {
  /// Calculates EPF returns based on the provided [input].
  ///
  /// Throws an [ArgumentError] if the retirement age is less than or equal to current age.
  EpfResult calculateMaturity(EpfInput input);
}
