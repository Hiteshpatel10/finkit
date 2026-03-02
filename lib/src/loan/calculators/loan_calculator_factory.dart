import 'package:finkit/src/core/calculator_factory.dart';
import 'package:finkit/src/core/capability_registry.dart';
import 'package:finkit/src/loan/calculators/flat_emi_calculator.dart';
import 'package:finkit/src/loan/calculators/reducing_emi_calculator.dart';
import 'package:finkit/src/loan/calculators/loan_interfaces.dart';
import 'package:finkit/src/loan/models/loan.dart';

class LoanCalculatorFactory implements CalculatorFactory<LoanType> {
  final Map<LoanType, CapabilityProvider> _providers = {};

  LoanCalculatorFactory() {
    _providers[LoanType.reducing] = _ReducingCapabilityProvider();
    _providers[LoanType.flat] = _FlatCapabilityProvider();
  }

  @override
  void register(LoanType type, CapabilityProvider provider) {
    _providers[type] = provider;
  }

  @override
  CapabilityRegistry create(LoanType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('No provider registered for LoanType.$type');
    }
    final registry = <Type, Object>{};
    provider.registerCapabilities(registry);
    return CapabilityRegistry(registry);
  }
}

class _ReducingCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    final calc = ReducingEmiCalculator();
    registry[EmiSolver] = calc;
    registry[TenureSolver] = calc;
    registry[RateSolver] = calc;
    registry[PrincipalSolver] = calc;
    registry[Amortization] = calc;
  }
}

class _FlatCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    final calc = FlatEmiCalculator();
    registry[EmiSolver] = calc;
    registry[TenureSolver] = calc;
    registry[RateSolver] = calc;
    registry[PrincipalSolver] = calc;
    registry[Amortization] = calc;
  }
}
