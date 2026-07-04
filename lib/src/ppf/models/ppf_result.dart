import 'package:finkit/src/compound/models/compound_result.dart';

/// The result of a PPF calculation.
final class PpfResult {
  /// The final maturity amount available at the end of the tenure.
  final double maturityAmount;

  /// The total principal invested over the tenure.
  final double totalInvested;

  /// The total interest earned over the tenure.
  final double totalInterest;

  /// Detailed breakdown of the investment.
  /// Depending on the underlying calculation frequency, this may be monthly or yearly.
  final List<CompoundBreakdownEntry> breakdown;

  const PpfResult({
    required this.maturityAmount,
    required this.totalInvested,
    required this.totalInterest,
    required this.breakdown,
  });

  /// Groups the monthly breakdown into a yearly summary for easier viewing.
  List<CompoundGroupedBreakdown> get yearlyBreakdown =>
      breakdown.groupByMonths(12);
}
