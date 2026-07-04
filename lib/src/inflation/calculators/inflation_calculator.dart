import 'dart:math';

import 'package:finkit/src/inflation/calculators/inflation_interfaces.dart';
import 'package:finkit/src/inflation/models/inflation_result.dart';

/// Core engine for Inflation calculations.
///
/// Implements [InflationSolver] using closed-form formulas — no iterative
/// solver is needed since all three operations have direct solutions.
///
/// ## Formulas
///
/// **Future Value** (cost of goods after inflation erodes purchasing power):
/// ```
/// FV = PV × (1 + r)^n
/// ```
///
/// **Present Value** (purchasing power of a future amount in today's money):
/// ```
/// PV = FV / (1 + r)^n
/// ```
///
/// **Real Return** (inflation-adjusted investment return via Fisher Equation):
/// ```
/// realReturn = ((1 + nominal) / (1 + inflation)) − 1
/// ```
///
/// All rates are expressed as **percentages** (e.g. `6` means 6%).
final class InflationCalculator implements InflationSolver {
  // ─── Future Value ──────────────────────────────────────────────────────────

  @override
  InflationResult calculateFutureValue({
    required double presentValue,
    required double inflationRate,
    required int years,
  }) {
    _validateAmount(presentValue, 'presentValue');
    _validateRate(inflationRate, 'inflationRate');
    _validateYears(years);

    final r = inflationRate / 100;
    final fv = presentValue * pow(1 + r, years);

    return InflationResult(
      result: fv,
      description: 'Future Cost',
    );
  }

  // ─── Present Value ─────────────────────────────────────────────────────────

  @override
  InflationResult calculatePresentValue({
    required double futureValue,
    required double inflationRate,
    required int years,
  }) {
    _validateAmount(futureValue, 'futureValue');
    _validateRate(inflationRate, 'inflationRate');
    _validateYears(years);

    final r = inflationRate / 100;
    final pv = futureValue / pow(1 + r, years);

    return InflationResult(
      result: pv,
      description: 'Present Value',
    );
  }

  // ─── Real Return ───────────────────────────────────────────────────────────

  @override
  InflationResult calculateRealReturn({
    required double nominalRate,
    required double inflationRate,
  }) {
    // inflationRate of -100% makes the denominator 0 — undefined.
    if (inflationRate <= -100) {
      throw ArgumentError.value(
        inflationRate,
        'inflationRate',
        'Must be > -100 (denominator becomes zero or negative)',
      );
    }

    // Fisher Equation (exact form):
    //   realReturn = ((1 + nominal/100) / (1 + inflation/100)) − 1
    final realFraction =
        ((1 + nominalRate / 100) / (1 + inflationRate / 100)) - 1;

    return InflationResult(
      result: realFraction * 100, // convert fraction → percentage
      description: 'Real Return (%)',
    );
  }

  // ─── Validation helpers ────────────────────────────────────────────────────

  void _validateAmount(double value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'Must be >= 0');
    }
  }

  void _validateRate(double rate, String name) {
    if (rate < 0) {
      throw ArgumentError.value(rate, name, 'Must be >= 0');
    }
  }

  void _validateYears(int years) {
    if (years < 0) {
      throw ArgumentError.value(years, 'years', 'Must be >= 0');
    }
  }
}
