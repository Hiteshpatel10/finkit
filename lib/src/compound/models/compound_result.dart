/// A single period's snapshot within the compound interest simulation.
class CompoundBreakdownEntry {
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
class CompoundResult {
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
}
