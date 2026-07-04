import 'package:finkit/src/core/calculator_factory.dart';
import 'package:finkit/src/core/capability_registry.dart';
import 'package:finkit/src/income_tax/calculators/income_tax_calculator.dart';
import 'package:finkit/src/income_tax/calculators/income_tax_interfaces.dart';

/// Identifies the **Financial Year** for which tax slabs and rules apply.
///
/// Always pass the correct FY type so consumers of your application know
/// exactly which budget's rules are being used.
///
/// | Enum value | Financial Year | Assessment Year | Budget |
/// |------------|---------------|-----------------|--------|
/// | [fy2025_26] | FY 2025-26 | AY 2026-27 | Union Budget 2025 |
///
/// > **Adding future years:** When a new budget is announced, add a new enum
/// > value (e.g. `fy2026_27`) and register a corresponding [CapabilityProvider]
/// > via [IncomeTaxCalculatorFactory.register]. Existing code using [fy2025_26]
/// > remains completely unaffected.
enum IncomeTaxType {
  /// **FY 2025-26 / AY 2026-27** — Union Budget 2025 rules.
  ///
  /// New Regime slabs: 0% / 5% / 10% / 15% / 20% / 30%
  /// Old Regime slabs: 0% / 5% / 20% / 30%
  ///
  /// Key features:
  /// - New Regime standard deduction: ₹75,000
  /// - Old Regime standard deduction: ₹50,000
  /// - New Regime 87A rebate threshold: ₹12,00,000
  /// - Old Regime 87A rebate threshold: ₹5,00,000 (max rebate ₹12,500)
  fy2025_26,
}

/// Factory for Income Tax calculators.
///
/// Follows the package-wide pattern used by all finkit factories.
///
/// Usage:
/// ```dart
/// final registry =
///     IncomeTaxCalculatorFactory().create(IncomeTaxType.fy2025_26);
/// final solver = registry.require<IncomeTaxSolver>();
///
/// final result = solver.calculate(
///   grossIncome: 1500000,
///   regime:      TaxRegime.newRegime,
/// );
/// print(result.totalTax); // ₹1,30,000 + cess
/// ```
final class IncomeTaxCalculatorFactory
    implements CalculatorFactory<IncomeTaxType> {
  final Map<IncomeTaxType, CapabilityProvider> _providers = {};

  IncomeTaxCalculatorFactory() {
    _providers[IncomeTaxType.fy2025_26] = _Fy2025To26CapabilityProvider();
  }

  @override
  void register(IncomeTaxType type, CapabilityProvider provider) {
    _providers[type] = provider;
  }

  @override
  CapabilityRegistry create(IncomeTaxType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('No provider registered for IncomeTaxType.$type');
    }
    final registry = <Type, Object>{};
    provider.registerCapabilities(registry);
    return CapabilityRegistry(registry);
  }
}

// ─── Capability Providers ─────────────────────────────────────────────────────

class _Fy2025To26CapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    registry[IncomeTaxSolver] = IncomeTaxCalculator();
  }
}
