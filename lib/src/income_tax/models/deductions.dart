import 'package:finkit/src/income_tax/models/tax_regime.dart';
/// Old Regime deductions input model.
///
/// Only relevant when IncomeTaxSolver.calculate is called with
/// [TaxRegime.oldRegime]. All fields default to 0 and are optional.
///
/// ## Caps applied internally by the engine
/// | Field | Internal cap |
/// |-------|-------------|
/// | [section80C] | ₹1,50,000 |
/// | [section80D] | None (caller's responsibility) |
/// | [hraExemption] | None (use [HraCalculator] to pre-compute) |
/// | [otherDeductions] | None |
///
/// Example usage:
/// ```dart
/// Deductions(
///   section80C:     150000,  // PPF + LIC + ELSS
///   section80D:     25000,   // health insurance
///   hraExemption:   120000,  // from HraCalculator
///   otherDeductions: 50000,  // NPS 80CCD(1B)
/// )
/// ```
final class Deductions {
  /// Section 80C investments — PF, PPF, LIC, ELSS, home loan principal, etc.
  /// Capped internally at ₹1,50,000 regardless of the value provided.
  final double section80C;

  /// Section 80D — health insurance premiums for self, family, and parents.
  final double section80D;

  /// Pre-calculated HRA exemption (use [HraCalculator] to compute this).
  final double hraExemption;

  /// Any other eligible deductions (80E — education loan interest,
  /// 80CCD(1B) — additional NPS, etc.).
  final double otherDeductions;

  const Deductions({
    this.section80C = 0,
    this.section80D = 0,
    this.hraExemption = 0,
    this.otherDeductions = 0,
  });
}
