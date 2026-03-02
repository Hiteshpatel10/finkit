/// A type-safe registry that maps capability interfaces to their implementations.
///
/// Used by every calculator family (loan, SIP, lumpsum) to expose
/// only the capabilities they support, without forcing callers to
/// cast or check types manually.
///
/// Usage:
/// ```dart
/// final caps = registry.require<EmiSolver>();
/// final emi  = caps.calculateEmi(...);
/// ```
class CapabilityRegistry {
  final Map<Type, Object> _registry;

  const CapabilityRegistry(this._registry);

  /// Returns the capability or null if not registered.
  T? get<T>() => _registry[T] as T?;

  /// Returns the capability or throws [UnsupportedError] if not registered.
  T require<T>() {
    final solver = _registry[T];
    if (solver == null) {
      throw UnsupportedError(
        'Capability $T is not registered for this calculator type.',
      );
    }
    return solver as T;
  }

  /// Returns true if the capability is registered.
  bool supports<T>() => _registry.containsKey(T);
}

/// Contract for any class that registers its capabilities into a registry.
/// Each calculator family implements this to self-describe what it can do.
abstract interface class CapabilityProvider {
  void registerCapabilities(Map<Type, Object> registry);
}
