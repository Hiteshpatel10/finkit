/// The complete result of a compound interest calculation.
///
/// Contains both the summary figures and a full period-by-period breakdown,
/// making it suitable for rendering charts, tables, and summary cards.
class CompoundResult {
  /// Final corpus value at the end of the tenure.
  final double maturityAmount;

  /// Total amount invested (principal + all contributions, before growth).
  final double totalInvested;

  /// Total interest / returns earned = maturityAmount − totalInvested.
  final double totalInterest;

  /// Period-by-period breakdown (one entry per compounding period).
  final List<CompoundBreakdownEntry> breakdown;

  const CompoundResult({
    required this.maturityAmount,
    required this.totalInvested,
    required this.totalInterest,
    required this.breakdown,
  });

  /// Aggregated yearly breakdown derived from the period breakdown.
  List<YearlyBreakdownEntry> get yearlyBreakdown {
    final Map<int, List<CompoundBreakdownEntry>> byYear = {};

    for (final entry in breakdown) {
      byYear.putIfAbsent(entry.year, () => []).add(entry);
    }

    return byYear.entries.map((e) {
      final entries       = e.value;
      final year          = e.key;
      final invested      = entries.fold(0.0, (sum, e) => sum + e.contributionThisPeriod);
      final closingBalance = entries.last.closingBalance;
      final interestEarned = entries.fold(0.0, (sum, e) => sum + e.interestThisPeriod);

      return YearlyBreakdownEntry(
        year:            year,
        totalInvested:   invested,
        interestEarned:  interestEarned,
        closingBalance:  closingBalance,
      );
    }).toList();
  }
}

/// A single period's data in the compound interest breakdown.
class CompoundBreakdownEntry {
  /// Period index (1-based).
  final int period;

  /// Calendar year this period falls in (1-based).
  final int year;

  /// Balance at the start of this period.
  final double openingBalance;

  /// Contribution made this period (0 if no contribution this period).
  final double contributionThisPeriod;

  /// Interest earned this period on the opening balance + contribution.
  final double interestThisPeriod;

  /// Balance at the end of this period.
  final double closingBalance;

  /// Cumulative amount invested up to and including this period.
  final double cumulativeInvested;

  const CompoundBreakdownEntry({
    required this.period,
    required this.year,
    required this.openingBalance,
    required this.contributionThisPeriod,
    required this.interestThisPeriod,
    required this.closingBalance,
    required this.cumulativeInvested,
  });
}

/// Aggregated data for a single calendar year.
class YearlyBreakdownEntry {
  final int year;
  final double totalInvested;
  final double interestEarned;
  final double closingBalance;

  const YearlyBreakdownEntry({
    required this.year,
    required this.totalInvested,
    required this.interestEarned,
    required this.closingBalance,
  });
}
