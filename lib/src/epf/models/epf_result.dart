import 'package:finkit/src/compound/models/compound_result.dart';

/// The result of an EPF calculation.
final class EpfResult {
  /// The final maturity amount available at retirement.
  final double maturityAmount;

  /// The total amount contributed by the employee over the tenure.
  final double totalEmployeeContribution;

  /// The total amount contributed by the employer (to EPF) over the tenure.
  final double totalEmployerContribution;

  /// The total interest earned over the tenure.
  final double totalInterest;

  /// Detailed breakdown of the investment.
  final List<CompoundBreakdownEntry> breakdown;

  const EpfResult({
    required this.maturityAmount,
    required this.totalEmployeeContribution,
    required this.totalEmployerContribution,
    required this.totalInterest,
    required this.breakdown,
  });

  /// Groups the monthly breakdown into a yearly summary for easier viewing.
  List<CompoundGroupedBreakdown> get yearlyBreakdown =>
      breakdown.groupByMonths(12);
}
