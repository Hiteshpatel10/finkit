import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('Inflation Calculator', () {
    late InflationSolver solver;

    setUpAll(() {
      final registry =
          InflationCalculatorFactory().create(InflationType.standard);
      solver = registry.require<InflationSolver>();
    });

    // ── Future Value ────────────────────────────────────────────────────────

    group('calculateFutureValue', () {
      test('₹1,00,000 at 6% for 10 years → ≈ ₹1,79,084', () {
        // FV = 100000 × (1.06)^10
        final result = solver.calculateFutureValue(
          presentValue: 100000,
          inflationRate: 6,
          years: 10,
        );

        expect(result.result, closeTo(179084.77, 0.5));
        expect(result.description, equals('Future Cost'));
      });

      test('0% inflation returns same amount', () {
        final result = solver.calculateFutureValue(
          presentValue: 50000,
          inflationRate: 0,
          years: 5,
        );

        expect(result.result, closeTo(50000, 0.001));
      });

      test('0 years returns same amount regardless of rate', () {
        final result = solver.calculateFutureValue(
          presentValue: 75000,
          inflationRate: 8,
          years: 0,
        );

        expect(result.result, closeTo(75000, 0.001));
      });

      test('throws ArgumentError for negative presentValue', () {
        expect(
          () => solver.calculateFutureValue(
            presentValue: -1000,
            inflationRate: 6,
            years: 10,
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for negative inflationRate', () {
        expect(
          () => solver.calculateFutureValue(
            presentValue: 100000,
            inflationRate: -1,
            years: 10,
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for negative years', () {
        expect(
          () => solver.calculateFutureValue(
            presentValue: 100000,
            inflationRate: 6,
            years: -1,
          ),
          throwsArgumentError,
        );
      });
    });

    // ── Present Value ───────────────────────────────────────────────────────

    group('calculatePresentValue', () {
      test('₹1,00,000 in 10 years at 6% → ≈ ₹55,839 today', () {
        // PV = 100000 / (1.06)^10
        final result = solver.calculatePresentValue(
          futureValue: 100000,
          inflationRate: 6,
          years: 10,
        );

        expect(result.result, closeTo(55839.47, 0.5));
        expect(result.description, equals('Present Value'));
      });

      test('0% inflation returns same amount', () {
        final result = solver.calculatePresentValue(
          futureValue: 50000,
          inflationRate: 0,
          years: 10,
        );

        expect(result.result, closeTo(50000, 0.001));
      });

      test('is the exact inverse of calculateFutureValue', () {
        const original = 100000.0;
        final fv = solver.calculateFutureValue(
          presentValue: original,
          inflationRate: 7,
          years: 15,
        );
        final pv = solver.calculatePresentValue(
          futureValue: fv.result,
          inflationRate: 7,
          years: 15,
        );

        expect(pv.result, closeTo(original, 0.001));
      });

      test('throws ArgumentError for negative futureValue', () {
        expect(
          () => solver.calculatePresentValue(
            futureValue: -5000,
            inflationRate: 6,
            years: 5,
          ),
          throwsArgumentError,
        );
      });
    });

    // ── Real Return (Fisher Equation) ───────────────────────────────────────

    group('calculateRealReturn', () {
      test('12% nominal, 6% inflation → ≈ 5.66% real return', () {
        // ((1.12 / 1.06) - 1) * 100 ≈ 5.66%
        final result = solver.calculateRealReturn(
          nominalRate: 12,
          inflationRate: 6,
        );

        expect(result.result, closeTo(5.66, 0.01));
        expect(result.description, equals('Real Return (%)'));
      });

      test('nominal equals inflation → ≈ 0% real return', () {
        final result = solver.calculateRealReturn(
          nominalRate: 6,
          inflationRate: 6,
        );

        expect(result.result, closeTo(0.0, 0.001));
      });

      test('nominal less than inflation → negative real return', () {
        final result = solver.calculateRealReturn(
          nominalRate: 4,
          inflationRate: 7,
        );

        expect(result.result, lessThan(0.0));
        // ≈ ((1.04/1.07) - 1) * 100 ≈ -2.80%
        expect(result.result, closeTo(-2.80, 0.01));
      });

      test('0% inflation → real return equals nominal return', () {
        final result = solver.calculateRealReturn(
          nominalRate: 10,
          inflationRate: 0,
        );

        expect(result.result, closeTo(10.0, 0.001));
      });

      test('Fisher result differs from simple subtraction', () {
        // Demonstrate why the Fisher equation is more accurate
        const nominal = 12.0;
        const inflation = 6.0;
        final fisher = solver.calculateRealReturn(
          nominalRate: nominal,
          inflationRate: inflation,
        );

        // Simple approximation: 12 - 6 = 6% — overstates by ~0.34%
        expect(fisher.result, lessThan(nominal - inflation));
      });

      test('throws ArgumentError for inflationRate <= -100', () {
        expect(
          () => solver.calculateRealReturn(
            nominalRate: 10,
            inflationRate: -100,
          ),
          throwsArgumentError,
        );
      });
    });

    // ── Factory ─────────────────────────────────────────────────────────────

    group('InflationCalculatorFactory', () {
      test('create(standard) returns registry with InflationSolver', () {
        final registry =
            InflationCalculatorFactory().create(InflationType.standard);
        expect(registry.supports<InflationSolver>(), isTrue);
        expect(registry.require<InflationSolver>(), isA<InflationSolver>());
      });

      test('get<InflationSolver>() returns non-null for standard type', () {
        final registry =
            InflationCalculatorFactory().create(InflationType.standard);
        expect(registry.get<InflationSolver>(), isNotNull);
      });
    });
  });
}
