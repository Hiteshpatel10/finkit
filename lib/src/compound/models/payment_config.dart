// How often regular contributions are made.
enum PaymentFrequency {
  daily(365),
  weekly(52),
  monthly(12),
  quarterly(4),
  halfYearly(2),
  yearly(1);

  /// Number of contribution periods per year.
  final int periodsPerYear;

  const PaymentFrequency(this.periodsPerYear);
}

/// Controls whether contributions are made at the **start** or **end**
/// of each contribution period.
///
/// - [beginning]: contribution is added *before* interest is applied (annuity-due).
///   Slightly higher returns because the contribution earns interest immediately.
/// - [end]: contribution is added *after* interest is applied (ordinary annuity).
///   Standard / default behaviour in most SIP calculators.
enum PaymentTiming {
  /// Contribute at the start of each period (annuity-due).
  beginning,

  /// Contribute at the end of each period (ordinary annuity). Default.
  end,
}
