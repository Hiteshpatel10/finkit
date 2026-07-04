import 'package:finkit/src/core/calculator_factory.dart';
import 'package:finkit/src/core/capability_registry.dart';
import 'package:finkit/src/hra/calculators/hra_calculator.dart';
import 'package:finkit/src/hra/calculators/hra_interfaces.dart';

/// The variant of HRA calculation logic.
///
/// Currently only [standard] is provided — it implements the three-rule
/// formula under Section 10(13A) of the Indian Income Tax Act.
/// Register a custom [CapabilityProvider] via [HraCalculatorFactory.register]
/// to plug in alternative implementations (e.g. a state-specific variant).
enum HraType {
  /// Standard HRA — three-rule formula under Section 10(13A) of the Indian
  /// Income Tax Act.
  standard,
}

/// Factory for HRA calculators.
///
/// Follows the package-wide pattern used by [LoanCalculatorFactory],
/// [CompoundCalculatorFactory], [XirrCalculatorFactory], and
/// [InflationCalculatorFactory].
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
final class HraCalculatorFactory implements CalculatorFactory<HraType> {
  final Map<HraType, CapabilityProvider> _providers = {};

  HraCalculatorFactory() {
    _providers[HraType.standard] = _DefaultHraCapabilityProvider();
  }

  @override
  void register(HraType type, CapabilityProvider provider) {
    _providers[type] = provider;
  }

  @override
  CapabilityRegistry create(HraType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('No provider registered for HraType.$type');
    }
    final registry = <Type, Object>{};
    provider.registerCapabilities(registry);
    return CapabilityRegistry(registry);
  }
}

// ─── Capability Providers ─────────────────────────────────────────────────────

class _DefaultHraCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    registry[HraSolver] = HraCalculator();
  }
}
