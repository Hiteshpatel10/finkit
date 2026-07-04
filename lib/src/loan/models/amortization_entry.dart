/// A single row in a loan amortization schedule.
///
/// Each entry represents one month's payment breakdown.
final class AmortizationEntry {
  final int month;
  final double openingBalance;
  final double emi;
  final double interest;
  final double principal;
  final double prepayment;
  final double extraCharges;
  final double closingBalance;

  const AmortizationEntry({
    required this.month,
    required this.openingBalance,
    required this.emi,
    required this.interest,
    required this.principal,
    this.prepayment = 0,
    this.extraCharges = 0,
    required this.closingBalance,
  });
}

/// Represents a grouped set of amortization entries (e.g., a year containing its months).
final class AmortizationGroupedBreakdown {
  /// The summary of the entire group.
  final AmortizationEntry summary;
  
  /// The individual entries that make up this group.
  final List<AmortizationEntry> entries;

  const AmortizationGroupedBreakdown({
    required this.summary,
    required this.entries,
  });
}

/// Utility extension to group monthly amortizations into larger hierarchical periods.
extension AmortizationGrouping on Iterable<AmortizationEntry> {
  /// Groups the breakdown into larger periods, keeping the underlying entries.
  ///
  /// [monthsPerGroup] determines the grouping size (e.g., 12 for yearly, 3 for quarterly).
  List<AmortizationGroupedBreakdown> groupByMonths(int monthsPerGroup) {
    if (isEmpty || monthsPerGroup <= 1) {
      return map((e) => AmortizationGroupedBreakdown(summary: e, entries: [e])).toList();
    }

    final groupedEntries = <AmortizationGroupedBreakdown>[];

    for (int i = 0; i < length; i += monthsPerGroup) {
      final chunk = skip(i).take(monthsPerGroup).toList();

      final firstMonth = chunk.first;
      final lastMonth = chunk.last;

      final totalEmi = chunk.fold(
          0.0, (sum, entry) => sum + entry.emi);
      final totalInterest = chunk.fold(
          0.0, (sum, entry) => sum + entry.interest);
      final totalPrincipal = chunk.fold(
          0.0, (sum, entry) => sum + entry.principal);
      final totalPrepayment = chunk.fold(
          0.0, (sum, entry) => sum + entry.prepayment);
      final totalExtraCharges = chunk.fold(
          0.0, (sum, entry) => sum + entry.extraCharges);

      final summary = AmortizationEntry(
        month: lastMonth.month, // or maybe currentGroupPeriod if we wanted to number them 1,2,3... but using month is fine
        openingBalance: firstMonth.openingBalance,
        emi: totalEmi,
        interest: totalInterest,
        principal: totalPrincipal,
        prepayment: totalPrepayment,
        extraCharges: totalExtraCharges,
        closingBalance: lastMonth.closingBalance,
      );

      groupedEntries.add(
        AmortizationGroupedBreakdown(
          summary: summary,
          entries: chunk,
        ),
      );
    }

    return groupedEntries;
  }
}

