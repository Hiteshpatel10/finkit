import 'package:test/test.dart';
import 'package:finkit/src/core/capability_registry.dart';

abstract interface class DummySolver {}
class DummySolverImpl implements DummySolver {}
class UnregisteredSolver {}

void main() {
  group('CapabilityRegistry', () {
    late CapabilityRegistry registry;

    setUp(() {
      registry = CapabilityRegistry({
        DummySolver: DummySolverImpl(),
      });
    });

    test('get() returns solver when registered', () {
      expect(registry.get<DummySolver>(), isA<DummySolverImpl>());
    });

    test('get() returns null when unregistered', () {
      expect(registry.get<UnregisteredSolver>(), isNull);
    });

    test('require() returns solver when registered', () {
      expect(registry.require<DummySolver>(), isA<DummySolverImpl>());
    });

    test('require() throws UnsupportedError when unregistered', () {
      expect(
        () => registry.require<UnregisteredSolver>(),
        throwsUnsupportedError,
      );
    });

    test('supports() returns true for registered capability', () {
      expect(registry.supports<DummySolver>(), isTrue);
    });

    test('supports() returns false for unregistered capability', () {
      expect(registry.supports<UnregisteredSolver>(), isFalse);
    });
  });
}
