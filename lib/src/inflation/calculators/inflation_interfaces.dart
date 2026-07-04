import 'package:finkit/src/inflation/models/inflation_result.dart';

/// Contract for Inflation calculations.
///
/// Covers the three core inflation questions:
/// 1. **Future Value** — what will something cost in the future?
/// 2. **Present Value** — what is a future amount worth in today's money?
/// 3. **Real Return**  — what is my investment return after accounting for inflation?
///
/// Usage:
/// ```dart
/// final registry = InflationCalculatorFactory().create(InflationType.standard);
/// final solver   = registry.require<InflationSolver>();
///
/// // ₹1,00,000 today → what will it cost in 10 years at 6% inflation?
/// final fv = solver.calculateFutureValue(
///   presentValue:  100000,
///   inflationRate: 6,
///   years:         10,
/// );
/// print(fv.result); // ≈ 1,79,084
/// ```
abstract interface class InflationSolver {
  /// Calculates the **future cost** required to maintain current purchasing power.
  ///
  /// Formula: `FV = PV × (1 + r)^n`
  ///
  /// where `r = inflationRate / 100` and `n = years`.
  ///
  /// Throws [ArgumentError] if [presentValue] < 0, [inflationRate] < 0,
  /// or [years] < 0.
  InflationResult calculateFutureValue({
    required double presentValue,
    required double inflationRate,
    required int years,
  });

  /// Calculates the **present purchasing power** of a future amount.
  ///
  /// Answers: "What will ₹X in [years] years be worth in today's money?"
  ///
  /// Formula: `PV = FV / (1 + r)^n`
  ///
  /// Throws [ArgumentError] if [futureValue] < 0, [inflationRate] < 0,
  /// or [years] < 0.
  InflationResult calculatePresentValue({
    required double futureValue,
    required double inflationRate,
    required int years,
  });

  /// Calculates the **inflation-adjusted (real) return** using the Fisher Equation.
  ///
  /// Answers: "If my investment grows at [nominalRate]% but inflation is
  /// [inflationRate]%, what is my actual purchasing-power gain?"
  ///
  /// Formula: `realReturn = ((1 + nominal) / (1 + inflation)) − 1`
  ///
  /// Note: This is the exact Fisher Equation. The simplified approximation
  /// `nominal − inflation` is intentionally avoided here because it
  /// overstates real returns (especially at higher rate levels).
  ///
  /// Throws [ArgumentError] if [inflationRate] <= -100 (undefined).
  InflationResult calculateRealReturn({
    required double nominalRate,
    required double inflationRate,
  });
}
