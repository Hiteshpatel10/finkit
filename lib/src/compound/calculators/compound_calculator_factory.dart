import 'package:finkit/src/core/calculator_factory.dart';
import 'package:finkit/src/core/capability_registry.dart';
import 'package:finkit/src/compound/calculators/compound_calculator.dart';
import 'package:finkit/src/compound/calculators/compound_interfaces.dart';

/// The investment strategy type — determines which capabilities are registered.
///
/// All types delegate to the same [CompoundCalculator] engine. The type
/// controls which solver interfaces are advertised in the [CapabilityRegistry],
/// preventing misuse (e.g. calling [SwpMaturitySolver] on a SIP configuration).
///
/// Use [CompoundInput] named constructors to build the matching input:
///
/// ```dart
/// // SIP
/// final registry = CompoundCalculatorFactory().create(CompoundType.sip);
/// final solver   = registry.get<CompoundMaturitySolver>();
/// final result   = solver.calculate(CompoundInput.sip(...));
///
/// // SWP
/// final registry = CompoundCalculatorFactory().create(CompoundType.swp);
/// final solver   = registry.get<CompoundMaturitySolver>();
/// final result   = solver.calculate(CompoundInput.swp(...));
/// ```
enum CompoundType {
  /// Systematic Investment Plan — periodic contributions, no lumpsum.
  sip,

  /// Step-up SIP — periodic contributions that increase over time.
  stepUpSip,

  /// Lumpsum — one-time investment, no contributions.
  lumpsum,

  /// Lumpsum + SIP — one-time investment with periodic top-ups.
  lumpsumPlusSip,

  /// Systematic Withdrawal Plan — periodic withdrawals from a corpus.
  swp,
}

/// Factory for compound interest calculators.
///
/// Mirrors [LoanCalculatorFactory] — each [CompoundType] maps to a
/// [CapabilityProvider] that registers the relevant solver interfaces.
///
/// All types share the same [CompoundCalculator] engine underneath.
/// The factory exists to:
///   1. Make intent explicit at construction time.
///   2. Allow custom providers to be swapped in via [register].
///   3. Mirror the package-wide factory pattern for consistency.
///
/// Usage:
/// ```dart
/// final factory  = CompoundCalculatorFactory();
/// final registry = factory.create(CompoundType.sip);
///
/// // Maturity
/// final maturity = registry.get<CompoundMaturitySolver>()
///     .calculate(CompoundInput.sip(contribution: 5000, annualRate: 12, tenureMonths: 120));
///
/// // Required contribution to hit a target
/// final contrib  = registry.get<CompoundContributionSolver>()
///     .calculateRequiredContribution(targetAmount: 1000000, ...);
/// ```
class CompoundCalculatorFactory implements CalculatorFactory<CompoundType> {
  final Map<CompoundType, CapabilityProvider> _providers = {};

  CompoundCalculatorFactory() {
    _providers[CompoundType.sip] = _SipCapabilityProvider();
    _providers[CompoundType.stepUpSip] = _StepUpSipCapabilityProvider();
    _providers[CompoundType.lumpsum] = _LumpsumCapabilityProvider();
    _providers[CompoundType.lumpsumPlusSip] =
        _LumpsumPlusSipCapabilityProvider();
    _providers[CompoundType.swp] = _SwpCapabilityProvider();
  }

  @override
  void register(CompoundType type, CapabilityProvider provider) {
    _providers[type] = provider;
  }

  @override
  CapabilityRegistry create(CompoundType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('No provider registered for CompoundType.$type');
    }
    final registry = <Type, Object>{};
    provider.registerCapabilities(registry);
    return CapabilityRegistry(registry);
  }
}

// ─── Capability Providers ─────────────────────────────────────────────────────
//
// Each provider instantiates ONE CompoundCalculator and registers it under
// every interface it is capable of fulfilling for that investment type.
//
// SIP / step-up SIP / lumpsum / lumpsum+SIP all expose the four solvers
// (maturity, contribution, rate, tenure). SWP exposes only maturity — there
// is no well-defined "required contribution" concept for a withdrawal plan.

class _SipCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    final calc = CompoundCalculator();
    registry[CompoundMaturitySolver] = calc;
    registry[CompoundContributionSolver] = calc;
    registry[CompoundRateSolver] = calc;
    registry[CompoundTenureSolver] = calc;
  }
}

class _StepUpSipCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    final calc = CompoundCalculator();
    registry[CompoundMaturitySolver] = calc;
    registry[CompoundContributionSolver] = calc;
    registry[CompoundRateSolver] = calc;
    registry[CompoundTenureSolver] = calc;
  }
}

class _LumpsumCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    final calc = CompoundCalculator();
    registry[CompoundMaturitySolver] = calc;
    // No ContributionSolver — lumpsum has no periodic contribution to solve for
    registry[CompoundRateSolver] = calc;
    registry[CompoundTenureSolver] = calc;
  }
}

class _LumpsumPlusSipCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    final calc = CompoundCalculator();
    registry[CompoundMaturitySolver] = calc;
    registry[CompoundContributionSolver] = calc;
    registry[CompoundRateSolver] = calc;
    registry[CompoundTenureSolver] = calc;
  }
}

class _SwpCapabilityProvider implements CapabilityProvider {
  @override
  void registerCapabilities(Map<Type, Object> registry) {
    final calc = CompoundCalculator();
    registry[CompoundMaturitySolver] = calc;
    // No ContributionSolver / TenureSolver for SWP —
    // the meaningful question is "how long does the corpus last"
    // which is answered by maturity reaching 0, visible in the breakdown.
    registry[CompoundRateSolver] = calc;
  }
}
