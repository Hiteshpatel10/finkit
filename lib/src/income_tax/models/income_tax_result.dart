import 'package:finkit/src/income_tax/models/tax_regime.dart';
import 'package:finkit/src/income_tax/models/tax_slab_entry.dart';

/// The complete output of an Indian income tax calculation.
///
/// All monetary fields are in **Indian Rupees (₹)**.
/// All rate fields ([effectiveRate], [marginalRate]) are **percentages**
/// (e.g. `14.5` means 14.5%).
///
/// ## Computation layers (in order)
/// ```
/// grossIncome
///   − totalDeductions   → taxableIncome
///                          ↓  slab computation
///                        baseTax
///                          − rebate87A      → taxAfterRebate
///                          + surcharge
///                          + cess (4%)
///                          ───────────────    totalTax
/// ```
final class IncomeTaxResult {
  // ── Input summary ───────────────────────────────────────────────────────────

  /// Total gross income provided (CTC or income from all sources).
  final double grossIncome;

  /// Sum of all deductions applied (standard deduction + Old Regime deductions).
  final double totalDeductions;

  /// Income on which tax slabs are applied: `grossIncome − totalDeductions`.
  final double taxableIncome;

  // ── Tax layers ──────────────────────────────────────────────────────────────

  /// Raw tax computed from the progressive slab table, before any rebate.
  final double baseTax;

  /// Section 87A rebate applied (and marginal relief at the 87A threshold
  /// for the New Regime, if applicable). Equals `baseTax` when full rebate
  /// is available.
  final double rebate87A;

  /// `baseTax − rebate87A`. This is the base on which surcharge is computed.
  final double taxAfterRebate;

  /// Surcharge levied on [taxAfterRebate] based on [taxableIncome] tier.
  /// Already accounts for **marginal relief at each surcharge threshold**.
  final double surcharge;

  /// Health & Education Cess: 4% of `(taxAfterRebate + surcharge)`.
  final double cess;

  /// **Final tax payable**: `taxAfterRebate + surcharge + cess`.
  final double totalTax;

  // ── Rate summaries ──────────────────────────────────────────────────────────

  /// `totalTax / grossIncome × 100` — how much of total income goes as tax.
  final double effectiveRate;

  /// Rate at which the **last rupee** of income is taxed, including surcharge
  /// and cess. Useful for tax-planning decisions.
  ///
  /// `topSlabRate × (1 + surchargeRate) × 1.04`
  final double marginalRate;

  // ── Metadata ────────────────────────────────────────────────────────────────

  /// The regime under which this calculation was performed.
  final TaxRegime regime;

  /// Per-slab breakdown — one entry per slab the taxpayer's income enters.
  final List<TaxSlabEntry> slabBreakdown;

  const IncomeTaxResult({
    required this.grossIncome,
    required this.totalDeductions,
    required this.taxableIncome,
    required this.baseTax,
    required this.rebate87A,
    required this.taxAfterRebate,
    required this.surcharge,
    required this.cess,
    required this.totalTax,
    required this.effectiveRate,
    required this.marginalRate,
    required this.regime,
    required this.slabBreakdown,
  });

  @override
  String toString() =>
      'IncomeTaxResult(taxable: ₹$taxableIncome, total: ₹$totalTax, '
      'effective: ${effectiveRate.toStringAsFixed(2)}%, regime: $regime)';
}
