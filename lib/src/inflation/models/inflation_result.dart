/// The output of an Inflation calculation.
///
/// [result] holds the primary computed value, whose meaning depends on the
/// operation that produced it:
/// - [InflationSolver.calculateFutureValue] → future cost in nominal terms.
/// - [InflationSolver.calculatePresentValue] → present purchasing power.
/// - [InflationSolver.calculateRealReturn]   → real return as a **percentage**.
///
/// [description] provides a short human-readable label for the value (useful
/// for display in UI or logs without the caller needing to remember which
/// operation was invoked).
final class InflationResult {
  /// The primary computed value.
  ///
  /// For `calculateFutureValue` and `calculatePresentValue`, this is a
  /// monetary amount in the same currency as the input.
  ///
  /// For `calculateRealReturn`, this is a percentage (e.g. `3.77` means 3.77%).
  final double result;

  /// Short label describing what [result] represents.
  ///
  /// Examples: `"Future Cost"`, `"Present Value"`, `"Real Return (%)"`.
  final String description;

  const InflationResult({
    required this.result,
    required this.description,
  });

  @override
  String toString() => 'InflationResult($description: $result)';
}
