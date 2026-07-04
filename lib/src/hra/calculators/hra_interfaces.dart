import 'package:finkit/src/hra/models/city_type.dart';
import 'package:finkit/src/hra/models/hra_result.dart';

/// Contract for HRA (House Rent Allowance) exemption calculation.
///
/// Implements the 3-rule formula under **Section 10(13A)** of the Indian
/// Income Tax Act. The tax-exempt portion of HRA is the **minimum** of:
///
/// 1. Actual HRA received from the employer.
/// 2. 50% of (Basic + DA) for Metro cities, 40% for Non-Metro cities.
/// 3. Actual rent paid minus 10% of (Basic + DA).
///
/// All monetary inputs must use the **same time period** (either all monthly
/// or all annual). Mixing periods will produce incorrect results.
///
/// Usage:
/// ```dart
/// final registry = HraCalculatorFactory().create(HraType.standard);
/// final solver   = registry.require<HraSolver>();
///
/// // Annual figures: Basic ₹6,00,000, HRA ₹2,40,000, Rent ₹1,80,000, Metro
/// final result = solver.calculate(
///   basicSalary: 600000,
///   hraReceived: 240000,
///   rentPaid:    180000,
///   cityType:    CityType.metro,
/// );
///
/// print(result.exemptedHra); // ₹1,20,000
/// print(result.taxableHra);  // ₹1,20,000
/// ```
abstract interface class HraSolver {
  /// Calculates the HRA exemption and taxable amounts.
  ///
  /// [basicSalary] — Basic salary for the period.
  /// [dearnessAllowance] — DA for the period (defaults to 0 if not applicable).
  /// [hraReceived] — Total HRA received from employer for the period.
  /// [rentPaid] — Total rent actually paid for the period.
  /// [cityType] — Metro or Non-Metro (determines the Rule 2 percentage).
  ///
  /// Throws [ArgumentError] if any input is negative.
  HraResult calculate({
    required double basicSalary,
    double dearnessAllowance,
    required double hraReceived,
    required double rentPaid,
    required CityType cityType,
  });
}
