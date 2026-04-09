import 'package:finkit/src/core/calculator_factory.dart';
import 'package:finkit/src/core/capability_registry.dart';
import 'package:finkit/src/gst/calculators/gst_calculator.dart';
import 'package:finkit/src/gst/calculators/gst_interfaces.dart';

/// Identifies the variant of GST calculation logic.
enum GstType {
  /// Standard GST logic.
  standard,
}

/// Factory for GST calculators.
///
/// Follows the package-wide pattern used by Loan and Compound calculators,
/// allowing type-safe access to GST capabilities.
final class GstCalculatorFactory implements CalculatorFactory<GstType> {
  final Map<GstType, CapabilityProvider> _providers = {};

  GstCalculatorFactory() {
    _providers[GstType.standard] = _DefaultGstCapabilityProvider();
  }

  @override
  void register(GstType type, CapabilityProvider provider) {
    _providers[type] = provider;
  }

  @override
  CapabilityRegistry create(GstType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('No provider registered for GstType.$type');
    }
    final registry = <Type, Object>{};
    provider.registerCapabilities(registry);
    return CapabilityRegistry(registry);
  }
}

class _DefaultGstCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    registry[GstSolver] = GstCalculator();
  }
}
