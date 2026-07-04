/// A single period's snapshot within the compound interest simulation.
final class CompoundBreakdownEntry {
  /// Compounding period number (1-based).
  final int period;

  /// Calendar year this period belongs to (1-based).
  final int year;

  /// Balance at the start of the period (before any contribution or interest).
  final double openingBalance;

  /// Contribution applied this period (0 if no contribution was scheduled).
  /// For [ContributionTiming.beginning] this is added before interest;
  /// for [ContributionTiming.end] it is added after interest.
  final double contributionThisPeriod;

  /// Interest earned this period.
  final double interestThisPeriod;

  /// Withdrawal taken this period (0 if no withdrawal was scheduled).
  /// Always applied after interest is compounded.
  final double withdrawalThisPeriod;

  /// Balance at the end of the period (after contribution, interest, withdrawal).
  final double closingBalance;

  /// Running total of all contributions + principal invested so far.
  final double cumulativeInvested;

  /// Running total of all withdrawals taken so far.
  final double cumulativeWithdrawn;

  /// True when the corpus was exhausted by the withdrawal this period.
  /// When true, [closingBalance] will be 0 and no further periods are simulated.
  final bool balanceExhausted;

  const CompoundBreakdownEntry({
    required this.period,
    required this.year,
    required this.openingBalance,
    required this.contributionThisPeriod,
    required this.interestThisPeriod,
    this.withdrawalThisPeriod = 0,
    required this.closingBalance,
    required this.cumulativeInvested,
    this.cumulativeWithdrawn = 0,
    this.balanceExhausted = false,
  });
}

/// The final output of a compound interest calculation.
final class CompoundResult {
  /// Final corpus value at the end of the tenure.
  /// Will be 0 if the corpus was exhausted by withdrawals before the tenure ended.
  final double maturityAmount;

  /// Total amount invested (principal + all contributions).
  final double totalInvested;

  /// Net interest / growth earned.
  ///   totalInterest = maturityAmount + totalWithdrawn − totalInvested
  final double totalInterest;

  /// Total amount withdrawn over the tenure (SWP total).
  /// 0 when no [WithdrawalConfig] is provided.
  final double totalWithdrawn;

  /// Period-by-period simulation log.
  final List<CompoundBreakdownEntry> breakdown;

  /// True if the corpus was exhausted before the end of the tenure.
  bool get isCorpusExhausted =>
      breakdown.isNotEmpty && breakdown.last.balanceExhausted;

  /// The period at which the corpus was exhausted, or null if it wasn't.
  int? get exhaustedAtPeriod =>
      isCorpusExhausted ? breakdown.last.period : null;

  const CompoundResult({
    required this.maturityAmount,
    required this.totalInvested,
    required this.totalInterest,
    this.totalWithdrawn = 0,
    required this.breakdown,
  });

  /// Groups the monthly breakdown into a yearly summary for easier viewing.
  List<CompoundGroupedBreakdown> get yearlyBreakdown =>
      breakdown.groupByMonths(12);
}

/// Represents a grouped set of breakdown entries (e.g., a year containing its months).
final class CompoundGroupedBreakdown {
  /// The summary of the entire group.
  final CompoundBreakdownEntry summary;
  
  /// The individual entries that make up this group.
  final List<CompoundBreakdownEntry> entries;

  const CompoundGroupedBreakdown({
    required this.summary,
    required this.entries,
  });
}

/// Utility extension to group monthly breakdowns into larger hierarchical periods.
extension CompoundBreakdownGrouping on Iterable<CompoundBreakdownEntry> {
  /// Groups the breakdown into larger periods, keeping the underlying entries.
  ///
  /// [monthsPerGroup] determines the grouping size (e.g., 12 for yearly, 3 for quarterly).
  List<CompoundGroupedBreakdown> groupByMonths(int monthsPerGroup) {
    if (isEmpty || monthsPerGroup <= 1) {
      return map((e) => CompoundGroupedBreakdown(summary: e, entries: [e])).toList();
    }

    final groupedEntries = <CompoundGroupedBreakdown>[];
    int currentGroupPeriod = 1;

    for (int i = 0; i < length; i += monthsPerGroup) {
      final chunk = skip(i).take(monthsPerGroup).toList();

      final firstMonth = chunk.first;
      final lastMonth = chunk.last;

      final totalContribution = chunk.fold(
          0.0, (sum, entry) => sum + entry.contributionThisPeriod);
      final totalInterest = chunk.fold(
          0.0, (sum, entry) => sum + entry.interestThisPeriod);
      final totalWithdrawal = chunk.fold(
          0.0, (sum, entry) => sum + entry.withdrawalThisPeriod);

      final summary = CompoundBreakdownEntry(
        period: currentGroupPeriod,
        year: lastMonth.year,
        openingBalance: firstMonth.openingBalance,
        contributionThisPeriod: totalContribution,
        interestThisPeriod: totalInterest,
        withdrawalThisPeriod: totalWithdrawal,
        closingBalance: lastMonth.closingBalance,
        cumulativeInvested: lastMonth.cumulativeInvested,
        cumulativeWithdrawn: lastMonth.cumulativeWithdrawn,
        balanceExhausted: lastMonth.balanceExhausted,
      );

      groupedEntries.add(
        CompoundGroupedBreakdown(
          summary: summary,
          entries: chunk,
        ),
      );

      currentGroupPeriod++;
    }

    return groupedEntries;
  }
}

