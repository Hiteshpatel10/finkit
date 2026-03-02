/// How many times per year interest is compounded.
///
/// This directly affects the effective rate applied each period:
///   periodic rate = annualRate / frequency
enum CompoundFrequency {
  daily(365),
  monthly(12),
  quarterly(4),
  halfYearly(2),
  yearly(1);

  /// Number of compounding periods per year.
  final int periodsPerYear;

  const CompoundFrequency(this.periodsPerYear);
}
