import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('XIRR Calculator', () {
    late XirrSolver solver;

    setUpAll(() {
      final registry = XirrCalculatorFactory().create(XirrType.standard);
      solver = registry.require<XirrSolver>();
    });

    // ── Basic round-trip ────────────────────────────────────────────────────

    group('basic – single-year exact return', () {
      test('invest 10 000, receive 11 000 after exactly 1 year → ≈ 10%', () {
        final result = solver.calculate([
          XirrCashFlow(date: DateTime(2023, 1, 1), amount: -10000),
          XirrCashFlow(date: DateTime(2024, 1, 1), amount: 11000),
        ]);

        expect(result.converged, isTrue);
        expect(result.annualizedReturn, closeTo(10.0, 0.001));
      });

      test('invest 10 000, receive 12 000 after exactly 2 years → ≈ 9.54%', () {
        // (12000/10000)^(1/2) − 1 ≈ 0.09544
        final result = solver.calculate([
          XirrCashFlow(date: DateTime(2022, 1, 1), amount: -10000),
          XirrCashFlow(date: DateTime(2024, 1, 1), amount: 12000),
        ]);

        expect(result.converged, isTrue);
        expect(result.annualizedReturn, closeTo(9.544, 0.01));
      });

      test('zero return — invest and redeem the same amount → ≈ 0%', () {
        final result = solver.calculate([
          XirrCashFlow(date: DateTime(2023, 1, 1), amount: -10000),
          XirrCashFlow(date: DateTime(2024, 1, 1), amount: 10000),
        ]);

        expect(result.converged, isTrue);
        expect(result.annualizedReturn, closeTo(0.0, 0.001));
      });
    });

    // ── SIP-like (multiple equal investments) ───────────────────────────────

    group('SIP-like – equal monthly investments', () {
      test('12 × 5 000 monthly SIP, redeem 65 000 at end → positive XIRR', () {
        final flows = <XirrCashFlow>[];
        for (int month = 0; month < 12; month++) {
          flows.add(XirrCashFlow(
            date: DateTime(2023, 1 + month, 1),
            amount: -5000,
          ));
        }
        // Redemption — slightly above total invested (₹60 000) to ensure gain
        flows.add(XirrCashFlow(date: DateTime(2024, 1, 1), amount: 65000));

        final result = solver.calculate(flows);

        expect(result.converged, isTrue);
        // Should be a modest positive return (~15–18% depending on timing)
        expect(result.annualizedReturn, greaterThan(0.0));
        expect(result.annualizedReturn, lessThan(50.0));
      });

      test('SIP with loss — redeem below total invested → negative XIRR', () {
        final flows = <XirrCashFlow>[];
        for (int month = 0; month < 12; month++) {
          flows.add(XirrCashFlow(
            date: DateTime(2023, 1 + month, 1),
            amount: -5000,
          ));
        }
        flows.add(XirrCashFlow(date: DateTime(2024, 1, 1), amount: 55000));

        final result = solver.calculate(flows);

        expect(result.converged, isTrue);
        expect(result.annualizedReturn, lessThan(0.0));
      });
    });

    // ── Irregular dates (Excel-validated) ──────────────────────────────────

    group('irregular dates', () {
      // Flows: −1 000 on 2023-01-01, −2 500 on 2023-03-15, +4 000 on 2023-09-30
      // ACT/365 engine-verified XIRR ≈ 24.78%
      test('three irregular flows → XIRR ≈ 24.78%', () {
        final result = solver.calculate([
          XirrCashFlow(date: DateTime(2023, 1, 1),  amount: -1000),
          XirrCashFlow(date: DateTime(2023, 3, 15), amount: -2500),
          XirrCashFlow(date: DateTime(2023, 9, 30), amount:  4000),
        ]);

        expect(result.converged, isTrue);
        expect(result.annualizedReturn, closeTo(24.78, 0.01));
      });

      // Flows: −5 000 on 2021-06-01, −3 000 on 2022-01-15, +10 000 on 2023-06-01
      // ACT/365 engine-verified XIRR ≈ 13.42%
      test('multi-year irregular flows → XIRR ≈ 13.42%', () {
        final result = solver.calculate([
          XirrCashFlow(date: DateTime(2021, 6, 1),  amount: -5000),
          XirrCashFlow(date: DateTime(2022, 1, 15), amount: -3000),
          XirrCashFlow(date: DateTime(2023, 6, 1),  amount: 10000),
        ]);

        expect(result.converged, isTrue);
        expect(result.annualizedReturn, closeTo(13.42, 0.01));
      });
    });

    // ── Result metadata ─────────────────────────────────────────────────────

    group('result metadata', () {
      test('converged is true for well-formed inputs', () {
        final result = solver.calculate([
          XirrCashFlow(date: DateTime(2023, 1, 1), amount: -10000),
          XirrCashFlow(date: DateTime(2024, 1, 1), amount: 11000),
        ]);
        expect(result.converged, isTrue);
      });

      test('iterations is positive', () {
        final result = solver.calculate([
          XirrCashFlow(date: DateTime(2023, 1, 1), amount: -10000),
          XirrCashFlow(date: DateTime(2024, 1, 1), amount: 11000),
        ]);
        expect(result.iterations, greaterThan(0));
      });
    });

    // ── Input validation (ArgumentError) ───────────────────────────────────

    group('input validation', () {
      test('throws ArgumentError for fewer than 2 cash flows', () {
        expect(
          () => solver.calculate([
            XirrCashFlow(date: DateTime(2023, 1, 1), amount: -10000),
          ]),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when all amounts are negative (no inflow)', () {
        expect(
          () => solver.calculate([
            XirrCashFlow(date: DateTime(2023, 1, 1), amount: -5000),
            XirrCashFlow(date: DateTime(2023, 6, 1), amount: -3000),
          ]),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when all amounts are positive (no outflow)', () {
        expect(
          () => solver.calculate([
            XirrCashFlow(date: DateTime(2023, 1, 1), amount: 5000),
            XirrCashFlow(date: DateTime(2023, 6, 1), amount: 3000),
          ]),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when all cash flows share the same date', () {
        expect(
          () => solver.calculate([
            XirrCashFlow(date: DateTime(2023, 1, 1), amount: -10000),
            XirrCashFlow(date: DateTime(2023, 1, 1), amount:  11000),
          ]),
          throwsArgumentError,
        );
      });
    });

    // ── Factory ─────────────────────────────────────────────────────────────

    group('XirrCalculatorFactory', () {
      test('create(standard) returns a registry with XirrSolver', () {
        final registry = XirrCalculatorFactory().create(XirrType.standard);
        expect(registry.supports<XirrSolver>(), isTrue);
        expect(registry.require<XirrSolver>(), isA<XirrSolver>());
      });

      test('get<XirrSolver>() returns non-null for standard type', () {
        final registry = XirrCalculatorFactory().create(XirrType.standard);
        expect(registry.get<XirrSolver>(), isNotNull);
      });
    });
  });
}
