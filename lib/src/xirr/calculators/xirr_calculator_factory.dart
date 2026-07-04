import 'package:finkit/src/core/calculator_factory.dart';
import 'package:finkit/src/core/capability_registry.dart';
import 'package:finkit/src/xirr/calculators/xirr_calculator.dart';
import 'package:finkit/src/xirr/calculators/xirr_interfaces.dart';

/// The variant of XIRR calculation logic.
///
/// Currently only [standard] is provided — it uses the Newton-Raphson /
/// bisection solver with an ACT/365 day-count convention (matching Excel /
/// Google Sheets XIRR). Register a custom [CapabilityProvider] via
/// [XirrCalculatorFactory.register] to plug in alternative implementations.
enum XirrType {
  /// Standard XIRR — Newton-Raphson + bisection, ACT/365 day-count.
  standard,
}

/// Factory for XIRR calculators.
///
/// Follows the package-wide pattern used by [LoanCalculatorFactory] and
/// [CompoundCalculatorFactory].
///
/// Usage:
/// ```dart
/// final registry = XirrCalculatorFactory().create(XirrType.standard);
/// final solver   = registry.require<XirrSolver>();
///
/// final result = solver.calculate([
///   XirrCashFlow(date: DateTime(2023, 1, 1),  amount: -10000),
///   XirrCashFlow(date: DateTime(2024, 1, 1),  amount:  11000),
/// ]);
///
/// print(result.annualizedReturn); // ≈ 10.0
/// ```
final class XirrCalculatorFactory implements CalculatorFactory<XirrType> {
  final Map<XirrType, CapabilityProvider> _providers = {};

  XirrCalculatorFactory() {
    _providers[XirrType.standard] = _DefaultXirrCapabilityProvider();
  }

  @override
  void register(XirrType type, CapabilityProvider provider) {
    _providers[type] = provider;
  }

  @override
  CapabilityRegistry create(XirrType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('No provider registered for XirrType.$type');
    }
    final registry = <Type, Object>{};
    provider.registerCapabilities(registry);
    return CapabilityRegistry(registry);
  }
}

// ─── Capability Providers ─────────────────────────────────────────────────────

class _DefaultXirrCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    registry[XirrSolver] = XirrCalculator();
  }
}
