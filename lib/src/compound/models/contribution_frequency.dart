/// How often regular contributions are made.
enum ContributionFrequency {
  daily(365),
  weekly(52),
  monthly(12),
  quarterly(4),
  halfYearly(2),
  yearly(1);

  /// Number of contribution periods per year.
  final int periodsPerYear;

  const ContributionFrequency(this.periodsPerYear);
}
