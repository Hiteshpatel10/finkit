import 'dart:math';

import 'package:finkit/src/income_tax/calculators/income_tax_interfaces.dart';
import 'package:finkit/src/income_tax/models/deductions.dart';
import 'package:finkit/src/income_tax/models/income_tax_result.dart';
import 'package:finkit/src/income_tax/models/tax_regime.dart';
import 'package:finkit/src/income_tax/models/tax_slab_entry.dart';

/// Core engine for Indian Income Tax calculations — **FY 2025-26 (AY 2026-27)**.
///
/// ## Computation pipeline
/// ```
/// grossIncome
///   − standardDeduction (₹75k New / ₹50k Old, if salaried)
///   − Old Regime deductions (80C capped at ₹1.5L, 80D, HRA, others)
///   = taxableIncome
///        ↓
///   progressive slab tax
///        ↓
///   Section 87A rebate + marginal relief (New Regime at ₹12L threshold)
///        ↓
///   surcharge (tiered) + marginal relief at each surcharge threshold
///        ↓
///   Health & Education Cess (4%)
///        ↓
///   totalTax
/// ```
///
/// ## Marginal Relief
/// Applied at **two levels** to prevent cliff-edge tax spikes:
///
/// 1. **87A threshold (New Regime only):** For taxable income just above ₹12L,
///    tax is capped at `(taxableIncome − ₹12,00,000)`. This ensures the tax
///    payable never exceeds the excess income over the rebate threshold.
///
/// 2. **Surcharge thresholds:** At each surcharge bracket boundary (₹50L, ₹1Cr,
///    ₹2Cr, ₹5Cr), the total tax (before cess) is capped at
///    `(totalTaxAtThreshold + excessIncomeAboveThreshold)`.
///
/// > **Note:** Marginal relief on surcharge is NOT the same as surcharge
/// > exemption. It only prevents the tax increase from exceeding the income
/// > increase that caused the bracket crossing.
final class IncomeTaxCalculator implements IncomeTaxSolver {
  // ── Slab tables ─────────────────────────────────────────────────────────────

  // Each record: (from, to, ratePercent)
  // 'to' is the exclusive upper bound. double.infinity = unlimited.
  static final _newRegimeSlabs = <({double from, double to, double rate})>[
    (from: 0, to: 300000, rate: 0.0),
    (from: 300000, to: 700000, rate: 0.05),
    (from: 700000, to: 1000000, rate: 0.10),
    (from: 1000000, to: 1200000, rate: 0.15),
    (from: 1200000, to: 1500000, rate: 0.20),
    (from: 1500000, to: double.infinity, rate: 0.30),
  ];

  static final _oldRegimeSlabs = <({double from, double to, double rate})>[
    (from: 0, to: 250000, rate: 0.0),
    (from: 250000, to: 500000, rate: 0.05),
    (from: 500000, to: 1000000, rate: 0.20),
    (from: 1000000, to: double.infinity, rate: 0.30),
  ];

  // ── Surcharge thresholds ─────────────────────────────────────────────────────
  // Each record: (threshold above which this rate applies, rate)
  // The rate of 0.37 is only for Old Regime above ₹5Cr; New Regime caps at 0.25.
  static const _surchargeThresholds = <(double, double)>[
    (0.0, 0.0),          // ≤ ₹50L: no surcharge
    (5000000.0, 0.10),   // ₹50L+ : 10%
    (10000000.0, 0.15),  // ₹1Cr+ : 15%
    (20000000.0, 0.25),  // ₹2Cr+ : 25%
    (50000000.0, 0.37),  // ₹5Cr+ : 37% (Old) — overridden to 0.25 for New below
  ];

  // ── Constants ────────────────────────────────────────────────────────────────

  static const _standardDeductionNew = 75000.0;
  static const _standardDeductionOld = 50000.0;
  static const _rebateThresholdNew = 1200000.0;   // ₹12L
  static const _rebateThresholdOld = 500000.0;     // ₹5L
  static const _maxRebateOld = 12500.0;
  static const _cap80C = 150000.0;                 // ₹1.5L

  // ── Public API ───────────────────────────────────────────────────────────────

  @override
  IncomeTaxResult calculate({
    required double grossIncome,
    required TaxRegime regime,
    bool isSalaried = true,
    Deductions deductions = const Deductions(),
  }) {
    if (grossIncome < 0) {
      throw ArgumentError.value(grossIncome, 'grossIncome', 'Must be >= 0');
    }

    // ── Step 1: Deductions ────────────────────────────────────────────────────

    final standardDeduction = isSalaried
        ? (regime == TaxRegime.newRegime
            ? _standardDeductionNew
            : _standardDeductionOld)
        : 0.0;

    double otherDeductions = 0;
    if (regime == TaxRegime.oldRegime) {
      final capped80C = deductions.section80C.clamp(0.0, _cap80C);
      otherDeductions = capped80C +
          deductions.section80D +
          deductions.hraExemption +
          deductions.otherDeductions;
    }

    final totalDeductions = standardDeduction + otherDeductions;
    final taxableIncome =
        (grossIncome - totalDeductions).clamp(0.0, double.infinity);

    // ── Step 2: Slab tax ──────────────────────────────────────────────────────

    final slabs = regime == TaxRegime.newRegime ? _newRegimeSlabs : _oldRegimeSlabs;
    final (:tax, :breakdown) = _computeSlabTax(taxableIncome, slabs);
    final baseTax = tax;

    // ── Step 3: 87A rebate + marginal relief at 87A threshold ─────────────────

    double rebate87A = _compute87ARebate(taxableIncome, baseTax, regime);

    // New Regime marginal relief at ₹12L boundary:
    // If income is just above ₹12L, tax is capped at (taxableIncome - ₹12L).
    // This prevents tax from exceeding the additional income above the threshold.
    if (regime == TaxRegime.newRegime &&
        taxableIncome > _rebateThresholdNew) {
      final cappedTax = taxableIncome - _rebateThresholdNew;
      final normalTaxAfterRebate = baseTax - rebate87A; // rebate is 0 here
      if (normalTaxAfterRebate > cappedTax) {
        // Adjust rebate so taxAfterRebate = cappedTax
        rebate87A = baseTax - cappedTax;
      }
    }

    final taxAfterRebate = (baseTax - rebate87A).clamp(0.0, double.infinity);

    // ── Step 4: Surcharge with marginal relief ────────────────────────────────

    final surcharge =
        _computeSurchargeWithMarginalRelief(taxableIncome, taxAfterRebate, regime, slabs);

    // ── Step 5: Cess ──────────────────────────────────────────────────────────

    final cess = (taxAfterRebate + surcharge) * 0.04;

    // ── Step 6: Totals and rates ──────────────────────────────────────────────

    final totalTax = taxAfterRebate + surcharge + cess;
    final effectiveRate =
        grossIncome > 0 ? (totalTax / grossIncome) * 100 : 0.0;

    // Marginal rate = topSlabRate × (1 + surchargeRate) × (1 + 4% cess)
    final topSlabRate = _getApplicableSlabRate(taxableIncome, slabs);
    final surchargeRate = _getSurchargeRate(taxableIncome, regime);
    final marginalRate = topSlabRate * (1 + surchargeRate) * 1.04 * 100;

    return IncomeTaxResult(
      grossIncome: grossIncome,
      totalDeductions: totalDeductions,
      taxableIncome: taxableIncome,
      baseTax: baseTax,
      rebate87A: rebate87A,
      taxAfterRebate: taxAfterRebate,
      surcharge: surcharge,
      cess: cess,
      totalTax: totalTax,
      effectiveRate: effectiveRate,
      marginalRate: marginalRate,
      regime: regime,
      slabBreakdown: breakdown,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Applies the progressive slab table to [taxableIncome] and returns
  /// the total tax plus a per-slab breakdown.
  ({double tax, List<TaxSlabEntry> breakdown}) _computeSlabTax(
    double taxableIncome,
    List<({double from, double to, double rate})> slabs,
  ) {
    double totalTax = 0;
    final breakdown = <TaxSlabEntry>[];

    for (final slab in slabs) {
      if (taxableIncome <= slab.from) break;

      final upper = slab.to.isFinite ? slab.to : taxableIncome;
      final taxableInSlab = min(taxableIncome, upper) - slab.from;
      final taxInSlab = taxableInSlab * slab.rate;
      totalTax += taxInSlab;

      breakdown.add(TaxSlabEntry(
        slabFrom: slab.from,
        slabTo: slab.to,
        ratePercent: slab.rate * 100,
        taxableInThisSlab: taxableInSlab,
        taxInThisSlab: taxInSlab,
      ));
    }

    return (tax: totalTax, breakdown: breakdown);
  }

  /// Returns the Section 87A rebate amount.
  ///
  /// - New Regime: full rebate (= baseTax) if taxable income ≤ ₹12L.
  /// - Old Regime: rebate = min(baseTax, ₹12,500) if taxable income ≤ ₹5L.
  double _compute87ARebate(
      double taxableIncome, double baseTax, TaxRegime regime) {
    if (regime == TaxRegime.newRegime) {
      return taxableIncome <= _rebateThresholdNew ? baseTax : 0;
    } else {
      return taxableIncome <= _rebateThresholdOld
          ? min(baseTax, _maxRebateOld)
          : 0;
    }
  }

  /// Returns the applicable surcharge rate (as a fraction) for [taxableIncome].
  double _getSurchargeRate(double taxableIncome, TaxRegime regime) {
    double rate = 0;
    for (final (threshold, r) in _surchargeThresholds) {
      if (taxableIncome > threshold) rate = r;
    }
    // New Regime caps surcharge at 25% (no 37% bracket)
    if (regime == TaxRegime.newRegime && rate > 0.25) rate = 0.25;
    return rate;
  }

  /// Returns the tax slab rate (as a fraction) applicable to [taxableIncome].
  double _getApplicableSlabRate(
    double taxableIncome,
    List<({double from, double to, double rate})> slabs,
  ) {
    double rate = 0;
    for (final slab in slabs) {
      if (taxableIncome > slab.from) rate = slab.rate;
    }
    return rate;
  }

  /// Computes the surcharge on [taxAfterRebate] for the given [taxableIncome],
  /// applying **marginal relief** at each surcharge threshold.
  ///
  /// Marginal relief ensures:
  ///   `(taxAfterRebate + surcharge) ≤ (totalTaxAtThreshold + excessIncome)`
  ///
  /// where `totalTaxAtThreshold` is the tax (after rebate, before surcharge of
  /// the lower bracket) at the exact threshold that was crossed.
  double _computeSurchargeWithMarginalRelief(
    double taxableIncome,
    double taxAfterRebate,
    TaxRegime regime,
    List<({double from, double to, double rate})> slabs,
  ) {
    final currentRate = _getSurchargeRate(taxableIncome, regime);
    final normalSurcharge = taxAfterRebate * currentRate;

    if (currentRate == 0) return 0;

    // Find the threshold that was just crossed (the last one where income > threshold).
    // We need the previous surcharge rate and the threshold value.
    double crossedThreshold = 0;
    double prevRate = 0;

    for (final (threshold, rate) in _surchargeThresholds) {
      if (taxableIncome > threshold) {
        double effectiveRate = rate;
        if (regime == TaxRegime.newRegime && effectiveRate > 0.25) {
          effectiveRate = 0.25;
        }
        if (effectiveRate == currentRate && crossedThreshold == 0) {
          crossedThreshold = threshold;
          // prevRate was set in the iteration before this
        } else if (effectiveRate < currentRate) {
          prevRate = effectiveRate;
          crossedThreshold = threshold;
        }
      }
    }

    // Compute total tax (before cess) at the crossed threshold.
    final computedAtThreshold = _computeSlabTax(crossedThreshold, slabs);
    final baseTaxAtThreshold = computedAtThreshold.tax;
    final rebateAtThreshold =
        _compute87ARebate(crossedThreshold, baseTaxAtThreshold, regime);
    final taxAfterRebateAtThreshold =
        (baseTaxAtThreshold - rebateAtThreshold).clamp(0.0, double.infinity);
    final surchargeAtThreshold = taxAfterRebateAtThreshold * prevRate;
    final totalBeforeCessAtThreshold =
        taxAfterRebateAtThreshold + surchargeAtThreshold;

    // The taxpayer's total tax (before cess) should not exceed:
    //   totalAtThreshold + (income above threshold)
    final maxAllowedTotalBeforeCess =
        totalBeforeCessAtThreshold + (taxableIncome - crossedThreshold);
    final normalTotalBeforeCess = taxAfterRebate + normalSurcharge;

    if (normalTotalBeforeCess > maxAllowedTotalBeforeCess) {
      // Apply marginal relief — cap the surcharge
      return max(0, maxAllowedTotalBeforeCess - taxAfterRebate);
    }

    return normalSurcharge;
  }
}
