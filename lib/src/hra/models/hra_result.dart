import 'package:finkit/src/hra/models/city_type.dart';

/// The output of an HRA exemption calculation under Section 10(13A) of the
/// Indian Income Tax Act.
///
/// The exempted amount is determined by the **minimum of three rules**:
/// - [rule1ActualHra] — Actual HRA received from employer.
/// - [rule2CityPercentage] — 50% (Metro) or 40% (Non-Metro) of (Basic + DA).
/// - [rule3RentMinus10Percent] — Actual rent paid minus 10% of (Basic + DA).
///
/// The winning rule (the minimum) becomes [exemptedHra].
/// The remaining HRA above the exemption is [taxableHra].
///
/// All amounts are in the **same period** as the inputs (monthly or annual).
final class HraResult {
  /// The portion of HRA that is exempt from income tax.
  ///
  /// This is `min(rule1, rule2, rule3)`, floored at 0.
  final double exemptedHra;

  /// The portion of HRA that is taxable.
  ///
  /// `taxableHra = hraReceived − exemptedHra`
  final double taxableHra;

  // ── Rule breakdown (useful for UI explanation) ─────────────────────────────

  /// Rule 1: Actual HRA received from the employer.
  final double rule1ActualHra;

  /// Rule 2: 50% of (Basic + DA) for Metro, 40% for Non-Metro.
  final double rule2CityPercentage;

  /// Rule 3: Rent paid − 10% of (Basic + DA). Floored at 0.
  final double rule3RentMinus10Percent;

  /// The city type used in the calculation — determines the Rule 2 percentage.
  final CityType cityType;

  const HraResult({
    required this.exemptedHra,
    required this.taxableHra,
    required this.rule1ActualHra,
    required this.rule2CityPercentage,
    required this.rule3RentMinus10Percent,
    required this.cityType,
  });

  @override
  String toString() =>
      'HraResult(exempted: $exemptedHra, taxable: $taxableHra, '
      'rules: [$rule1ActualHra, $rule2CityPercentage, $rule3RentMinus10Percent])';
}
