import 'capability_registry.dart';

/// Base contract for all calculator factories in finkit.
///
/// Every domain (loan, SIP, lumpsum) has its own typed factory that
/// extends this, keeping high-level code decoupled from concrete implementations.
///
/// Type parameter [T] is the enum that identifies calculator variants
/// (e.g. [LoanType], [SipType], [LumpsumType]).
abstract interface class CalculatorFactory<T> {
  /// Creates a [CapabilityRegistry] for the given calculator [type].
  CapabilityRegistry create(T type);

  /// Registers a custom [CapabilityProvider] for a given [type],
  /// enabling extension without modifying the factory (OCP).
  void register(T type, CapabilityProvider provider);
}
