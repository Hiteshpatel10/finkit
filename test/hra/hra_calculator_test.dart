import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('HRA Calculator', () {
    late HraSolver solver;

    setUpAll(() {
      final registry = HraCalculatorFactory().create(HraType.standard);
      solver = registry.require<HraSolver>();
    });

    // ── Rule 3 wins (most common real-world scenario) ───────────────────────

    group('Rule 3 wins – rent paid is the limiting factor', () {
      // Annual: Basic ₹6,00,000 | HRA ₹2,40,000 | Rent ₹1,80,000 | Metro
      // Rule 1 = 2,40,000
      // Rule 2 = 50% × 6,00,000 = 3,00,000
      // Rule 3 = 1,80,000 − (10% × 6,00,000) = 1,80,000 − 60,000 = 1,20,000  ← min
      // Exempted = 1,20,000 | Taxable = 2,40,000 − 1,20,000 = 1,20,000
      test('Metro – annual figures → exempted ₹1,20,000', () {
        final result = solver.calculate(
          basicSalary: 600000,
          hraReceived: 240000,
          rentPaid: 180000,
          cityType: CityType.metro,
        );

        expect(result.exemptedHra, closeTo(120000, 0.01));
        expect(result.taxableHra, closeTo(120000, 0.01));
        expect(result.rule1ActualHra, closeTo(240000, 0.01));
        expect(result.rule2CityPercentage, closeTo(300000, 0.01));
        expect(result.rule3RentMinus10Percent, closeTo(120000, 0.01));
      });

      test('Non-Metro – 40% applies → lower Rule 2', () {
        // Rule 2 = 40% × 6,00,000 = 2,40,000 (same as Rule 1 here)
        // Rule 3 = 1,80,000 − 60,000 = 1,20,000 ← still min
        final result = solver.calculate(
          basicSalary: 600000,
          hraReceived: 240000,
          rentPaid: 180000,
          cityType: CityType.nonMetro,
        );

        expect(result.exemptedHra, closeTo(120000, 0.01));
        expect(result.rule2CityPercentage, closeTo(240000, 0.01));
        expect(result.cityType, equals(CityType.nonMetro));
      });
    });

    // ── Rule 1 wins – actual HRA is lowest ─────────────────────────────────

    group('Rule 1 wins – HRA received is the limiting factor', () {
      // Basic ₹10,00,000 | HRA ₹60,000 | Rent ₹5,00,000 | Metro
      // Rule 1 = 60,000   ← min
      // Rule 2 = 50% × 10,00,000 = 5,00,000
      // Rule 3 = 5,00,000 − 1,00,000 = 4,00,000
      test('very small HRA means Rule 1 is the ceiling', () {
        final result = solver.calculate(
          basicSalary: 1000000,
          hraReceived: 60000,
          rentPaid: 500000,
          cityType: CityType.metro,
        );

        expect(result.exemptedHra, closeTo(60000, 0.01));
        expect(result.taxableHra, closeTo(0, 0.01));
      });
    });

    // ── Rule 2 wins – city percentage is lowest ─────────────────────────────

    group('Rule 2 wins – city % is the limiting factor', () {
      // Basic ₹2,00,000 | HRA ₹1,50,000 | Rent ₹1,40,000 | Non-Metro
      // Rule 1 = 1,50,000
      // Rule 2 = 40% × 2,00,000 = 80,000   ← min
      // Rule 3 = 1,40,000 − 20,000 = 1,20,000
      test('Non-Metro with high HRA and high rent → Rule 2 wins', () {
        final result = solver.calculate(
          basicSalary: 200000,
          hraReceived: 150000,
          rentPaid: 140000,
          cityType: CityType.nonMetro,
        );

        expect(result.exemptedHra, closeTo(80000, 0.01));
        expect(result.taxableHra, closeTo(70000, 0.01));
        expect(result.rule2CityPercentage, closeTo(80000, 0.01));
      });
    });

    // ── Zero exemption – rent < 10% of basic ───────────────────────────────

    group('zero exemption', () {
      // If rentPaid < 10% of (Basic + DA), Rule 3 = 0 → no exemption
      // Basic ₹5,00,000 | HRA ₹1,00,000 | Rent ₹40,000 | Metro
      // 10% of basic = ₹50,000 > ₹40,000 → Rule 3 = 0 ← min
      test('rent paid less than 10% of basic → fully taxable HRA', () {
        final result = solver.calculate(
          basicSalary: 500000,
          hraReceived: 100000,
          rentPaid: 40000,
          cityType: CityType.metro,
        );

        expect(result.rule3RentMinus10Percent, closeTo(0, 0.01));
        expect(result.exemptedHra, closeTo(0, 0.01));
        expect(result.taxableHra, closeTo(100000, 0.01));
      });

      test('zero rent paid → zero exemption', () {
        final result = solver.calculate(
          basicSalary: 500000,
          hraReceived: 100000,
          rentPaid: 0,
          cityType: CityType.metro,
        );

        expect(result.exemptedHra, closeTo(0, 0.01));
        expect(result.taxableHra, closeTo(100000, 0.01));
      });
    });

    // ── Dearness Allowance (DA) ─────────────────────────────────────────────

    group('with Dearness Allowance', () {
      // Basic ₹4,00,000 | DA ₹1,00,000 | HRA ₹2,00,000 | Rent ₹1,80,000 | Metro
      // Basic + DA = ₹5,00,000
      // Rule 1 = 2,00,000
      // Rule 2 = 50% × 5,00,000 = 2,50,000
      // Rule 3 = 1,80,000 − 50,000 = 1,30,000  ← min
      test('DA is included in the Basic + DA base for all rules', () {
        final result = solver.calculate(
          basicSalary: 400000,
          dearnessAllowance: 100000,
          hraReceived: 200000,
          rentPaid: 180000,
          cityType: CityType.metro,
        );

        expect(result.rule2CityPercentage, closeTo(250000, 0.01));
        expect(result.rule3RentMinus10Percent, closeTo(130000, 0.01));
        expect(result.exemptedHra, closeTo(130000, 0.01));
      });
    });

    // ── Input validation ────────────────────────────────────────────────────

    group('input validation', () {
      test('throws ArgumentError for negative basicSalary', () {
        expect(
          () => solver.calculate(
            basicSalary: -1,
            hraReceived: 10000,
            rentPaid: 8000,
            cityType: CityType.metro,
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for negative dearnessAllowance', () {
        expect(
          () => solver.calculate(
            basicSalary: 50000,
            dearnessAllowance: -100,
            hraReceived: 10000,
            rentPaid: 8000,
            cityType: CityType.metro,
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for negative hraReceived', () {
        expect(
          () => solver.calculate(
            basicSalary: 50000,
            hraReceived: -500,
            rentPaid: 8000,
            cityType: CityType.metro,
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for negative rentPaid', () {
        expect(
          () => solver.calculate(
            basicSalary: 50000,
            hraReceived: 10000,
            rentPaid: -1,
            cityType: CityType.metro,
          ),
          throwsArgumentError,
        );
      });
    });

    // ── Factory ─────────────────────────────────────────────────────────────

    group('HraCalculatorFactory', () {
      test('create(standard) returns registry with HraSolver', () {
        final registry = HraCalculatorFactory().create(HraType.standard);
        expect(registry.supports<HraSolver>(), isTrue);
        expect(registry.require<HraSolver>(), isA<HraSolver>());
      });

      test('get<HraSolver>() returns non-null for standard type', () {
        final registry = HraCalculatorFactory().create(HraType.standard);
        expect(registry.get<HraSolver>(), isNotNull);
      });
    });
  });
}
