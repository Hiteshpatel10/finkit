/// How many times per year interest is compounded.
///
/// This directly affects the effective rate applied each period:
///   periodic rate = annualRate / frequency
enum CompoundFrequency {
  daily(365),
  daily360(360),
  semiWeekly(104),
  weekly(52),
  biWeekly(26),
  semiMonthly(24),
  monthly(12),
  biMonthly(6),
  quarterly(4),
  halfYearly(2),
  yearly(1),
  custom(-1);

  /// Number of compounding periods per year.
  final int periodsPerYear;

  const CompoundFrequency(this.periodsPerYear);
}
