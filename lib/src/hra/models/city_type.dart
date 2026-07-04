/// Identifies whether the employee resides in a Metro or Non-Metro city.
///
/// Under Section 10(13A) of the Indian Income Tax Act, the city type determines
/// the percentage of (Basic Salary + DA) used in Rule 2 of the HRA exemption:
/// - Metro cities → 50%
/// - Non-Metro cities → 40%
///
/// Metro cities are: **Delhi, Mumbai, Chennai, Kolkata**.
/// All other Indian cities are treated as Non-Metro.
enum CityType {
  /// Delhi, Mumbai, Chennai, or Kolkata — 50% of (Basic + DA) applies.
  metro,

  /// Any city other than the four metros — 40% of (Basic + DA) applies.
  nonMetro,
}
