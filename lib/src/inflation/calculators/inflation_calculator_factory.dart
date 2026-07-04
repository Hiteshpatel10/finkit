import 'package:finkit/src/core/calculator_factory.dart';
import 'package:finkit/src/core/capability_registry.dart';
import 'package:finkit/src/inflation/calculators/inflation_calculator.dart';
import 'package:finkit/src/inflation/calculators/inflation_interfaces.dart';

/// The variant of Inflation calculation logic.
///
/// Currently only [standard] is provided — it uses closed-form formulas
/// (compound interest for FV/PV, Fisher Equation for real return).
/// Register a custom [CapabilityProvider] via [InflationCalculatorFactory.register]
/// to plug in alternative implementations.
enum InflationType {
  /// Standard inflation calculator — compound FV/PV + Fisher Equation.
  standard,
}

/// Factory for Inflation calculators.
///
/// Follows the package-wide pattern used by [LoanCalculatorFactory],
/// [CompoundCalculatorFactory], and [XirrCalculatorFactory].
///
/// Usage:
/// ```dart
/// final registry = InflationCalculatorFactory().create(InflationType.standard);
/// final solver   = registry.require<InflationSolver>();
///
/// // Future cost: ₹1,00,000 item in 10 years at 6% inflation
/// final fv = solver.calculateFutureValue(
///   presentValue:  100000,
///   inflationRate: 6,
///   years:         10,
/// );
/// print(fv.result); // ≈ 1,79,084
///
/// // Purchasing power: ₹1,00,000 in 10 years at 6% inflation
/// final pv = solver.calculatePresentValue(
///   futureValue:   100000,
///   inflationRate: 6,
///   years:         10,
/// );
/// print(pv.result); // ≈ 55,839
///
/// // Real return: 12% nominal, 6% inflation
/// final real = solver.calculateRealReturn(
///   nominalRate:   12,
///   inflationRate: 6,
/// );
/// print(real.result); // ≈ 5.66%
/// ```
final class InflationCalculatorFactory
    implements CalculatorFactory<InflationType> {
  final Map<InflationType, CapabilityProvider> _providers = {};

  InflationCalculatorFactory() {
    _providers[InflationType.standard] = _DefaultInflationCapabilityProvider();
  }

  @override
  void register(InflationType type, CapabilityProvider provider) {
    _providers[type] = provider;
  }

  @override
  CapabilityRegistry create(InflationType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('No provider registered for InflationType.$type');
    }
    final registry = <Type, Object>{};
    provider.registerCapabilities(registry);
    return CapabilityRegistry(registry);
  }
}

// ─── Capability Providers ─────────────────────────────────────────────────────

class _DefaultInflationCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    registry[InflationSolver] = InflationCalculator();
  }
}
