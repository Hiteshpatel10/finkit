import 'package:finkit/src/income_tax/models/deductions.dart';
import 'package:finkit/src/income_tax/models/income_tax_result.dart';
import 'package:finkit/src/income_tax/models/tax_regime.dart';

/// Contract for Indian Income Tax computation.
///
/// Works for **FY 2025-26 (AY 2026-27)** when obtained from
/// [IncomeTaxCalculatorFactory] with [IncomeTaxType.fy2025_26].
///
/// ## Quick usage (New Regime, salaried)
/// ```dart
/// final registry =
///     IncomeTaxCalculatorFactory().create(IncomeTaxType.fy2025_26);
/// final solver = registry.require<IncomeTaxSolver>();
///
/// final result = solver.calculate(
///   grossIncome: 1200000, // ₹12,00,000 annual CTC
///   regime:      TaxRegime.newRegime,
/// );
/// print(result.totalTax);       // 0 (87A full rebate applies)
/// print(result.effectiveRate);  // 0.0%
/// ```
///
/// ## Old Regime with deductions
/// ```dart
/// final result = solver.calculate(
///   grossIncome: 1500000,
///   regime:      TaxRegime.oldRegime,
///   deductions:  Deductions(
///     section80C:  150000,
///     section80D:  25000,
///     hraExemption: 60000,
///   ),
/// );
/// ```
abstract interface class IncomeTaxSolver {
  /// Computes the complete income tax for the given inputs.
  ///
  /// [grossIncome] — Annual total income (CTC for salaried, or total income
  ///   from all sources). Must be >= 0.
  ///
  /// [regime] — The tax regime to use ([TaxRegime.newRegime] or [TaxRegime.oldRegime]).
  ///
  /// [isSalaried] — When `true`, the applicable standard deduction is applied
  ///   automatically (₹75,000 for New Regime, ₹50,000 for Old Regime). Set to
  ///   `false` for non-salaried/business income.
  ///
  /// [deductions] — Old Regime deductions (80C, 80D, HRA, etc.). Ignored when
  ///   [regime] is [TaxRegime.newRegime].
  ///
  /// Throws [ArgumentError] if [grossIncome] is negative.
  IncomeTaxResult calculate({
    required double grossIncome,
    required TaxRegime regime,
    bool isSalaried,
    Deductions deductions,
  });
}
