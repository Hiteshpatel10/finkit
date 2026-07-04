import 'package:finkit/src/compound/models/compound_result.dart';

/// The result of an NPS calculation.
final class NpsResult {
  /// The total corpus accumulated at retirement.
  final double totalCorpus;

  /// The total principal invested.
  final double totalInvested;

  /// The total interest/growth earned.
  final double totalInterest;

  /// The tax-free lump sum amount withdrawn at retirement.
  final double lumpSumAmount;

  /// The amount reinvested to purchase an annuity.
  final double annuityAmount;

  /// The expected monthly pension generated from the annuity.
  final double expectedMonthlyPension;

  /// Detailed breakdown of the investment period.
  final List<CompoundBreakdownEntry> breakdown;

  const NpsResult({
    required this.totalCorpus,
    required this.totalInvested,
    required this.totalInterest,
    required this.lumpSumAmount,
    required this.annuityAmount,
    required this.expectedMonthlyPension,
    required this.breakdown,
  });

  /// Groups the monthly breakdown into a yearly summary for easier viewing.
  List<CompoundGroupedBreakdown> get yearlyBreakdown =>
      breakdown.groupByMonths(12);
}
