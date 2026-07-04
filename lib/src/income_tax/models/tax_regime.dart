/// Indian income tax regime — determines which slab table, standard deduction,
/// and Section 87A rebate threshold apply.
///
/// Always verify which regime your user has opted into before passing this to
/// [IncomeTaxSolver.calculate]. The two regimes cannot be mixed within a
/// single assessment year.
enum TaxRegime {
  /// **New Tax Regime** (default from FY 2023-24 onwards).
  ///
  /// - Lower tax rates across 6 slabs.
  /// - Standard deduction of ₹75,000 for salaried / pensioners.
  /// - Most deductions (80C, 80D, HRA exemption, etc.) are **not** available.
  /// - Section 87A rebate: full rebate for total income ≤ ₹12,00,000.
  /// - Surcharge capped at 25% (no 37% bracket).
  newRegime,

  /// **Old Tax Regime** (requires explicit opt-in from FY 2023-24 onwards).
  ///
  /// - Higher rates across 4 slabs.
  /// - Standard deduction of ₹50,000 for salaried / pensioners.
  /// - Most deductions available: 80C (cap ₹1.5L), 80D, HRA exemption, etc.
  /// - Section 87A rebate: rebate up to ₹12,500 for total income ≤ ₹5,00,000.
  /// - Surcharge up to 37% for income above ₹5 Crore.
  oldRegime,
}
