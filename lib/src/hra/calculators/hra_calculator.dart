import 'package:finkit/src/hra/calculators/hra_interfaces.dart';
import 'package:finkit/src/hra/models/city_type.dart';
import 'package:finkit/src/hra/models/hra_result.dart';

/// Core engine for HRA (House Rent Allowance) exemption calculations.
///
/// Implements [HraSolver] using the three-rule formula under
/// Section 10(13A) of the Indian Income Tax Act.
///
/// ## The Three Rules
///
/// Let `B` = Basic Salary + Dearness Allowance.
///
/// | Rule | Value |
/// |------|-------|
/// | Rule 1 | Actual HRA received |
/// | Rule 2 | 50% × B (Metro) or 40% × B (Non-Metro) |
/// | Rule 3 | max(Rent Paid − 10% × B, 0) |
///
/// **Exempted HRA = min(Rule 1, Rule 2, Rule 3)**
/// **Taxable HRA  = HRA Received − Exempted HRA**
///
/// ## Important Notes
/// - If rent paid is less than 10% of (Basic + DA), Rule 3 = 0, meaning
///   **no HRA exemption is available** regardless of HRA received.
/// - All inputs must use the same time period (monthly or annual).
final class HraCalculator implements HraSolver {
  @override
  HraResult calculate({
    required double basicSalary,
    double dearnessAllowance = 0,
    required double hraReceived,
    required double rentPaid,
    required CityType cityType,
  }) {
    _validate(basicSalary, dearnessAllowance, hraReceived, rentPaid);

    final basicPlusDa = basicSalary + dearnessAllowance;

    // ── Rule 1: Actual HRA received ──────────────────────────────────────────
    final rule1 = hraReceived;

    // ── Rule 2: City percentage of (Basic + DA) ──────────────────────────────
    final cityPercent = cityType == CityType.metro ? 0.50 : 0.40;
    final rule2 = basicPlusDa * cityPercent;

    // ── Rule 3: Rent paid minus 10% of (Basic + DA), floored at 0 ────────────
    final tenPercentOfBasicDa = basicPlusDa * 0.10;
    final rule3 = (rentPaid - tenPercentOfBasicDa).clamp(0.0, double.infinity);

    // ── Exempted HRA: minimum of the three rules ──────────────────────────────
    final exempted = [rule1, rule2, rule3].reduce((a, b) => a < b ? a : b);

    // ── Taxable HRA: the remainder ────────────────────────────────────────────
    final taxable = (hraReceived - exempted).clamp(0.0, double.infinity);

    return HraResult(
      exemptedHra: exempted,
      taxableHra: taxable,
      rule1ActualHra: rule1,
      rule2CityPercentage: rule2,
      rule3RentMinus10Percent: rule3,
      cityType: cityType,
    );
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  void _validate(
    double basicSalary,
    double dearnessAllowance,
    double hraReceived,
    double rentPaid,
  ) {
    if (basicSalary < 0) {
      throw ArgumentError.value(basicSalary, 'basicSalary', 'Must be >= 0');
    }
    if (dearnessAllowance < 0) {
      throw ArgumentError.value(
          dearnessAllowance, 'dearnessAllowance', 'Must be >= 0');
    }
    if (hraReceived < 0) {
      throw ArgumentError.value(hraReceived, 'hraReceived', 'Must be >= 0');
    }
    if (rentPaid < 0) {
      throw ArgumentError.value(rentPaid, 'rentPaid', 'Must be >= 0');
    }
  }
}
