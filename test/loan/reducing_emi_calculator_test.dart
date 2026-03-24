import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('Reducing EMI Calculator', () {
    late EmiSolver emiSolver;
    late TenureSolver tenureSolver;
    late PrincipalSolver principalSolver;
    late RateSolver rateSolver;
    late Amortization amortization;

    setUpAll(() {
      final registry = LoanCalculatorFactory().create(LoanType.reducing);
      emiSolver = registry.require<EmiSolver>();
      tenureSolver = registry.require<TenureSolver>();
      principalSolver = registry.require<PrincipalSolver>();
      rateSolver = registry.require<RateSolver>();
      amortization = registry.require<Amortization>();
    });

    group('EmiSolver', () {
      test('calculates correct EMI for valid inputs', () {
        final emi = emiSolver.calculateEmi(
          principal: 1000000,
          annualRate: 8.5,
          tenureMonths: 240,
        );
        expect(emi, closeTo(8678.23, 0.01));
      });

      test('0% interest returns P/n', () {
        final emi = emiSolver.calculateEmi(
          principal: 120000,
          annualRate: 0,
          tenureMonths: 12,
        );
        expect(emi, equals(10000.0));
      });

      test('throws ArgumentError on invalid inputs', () {
        expect(() => emiSolver.calculateEmi(principal: -1, annualRate: 8, tenureMonths: 12), throwsArgumentError);
        expect(() => emiSolver.calculateEmi(principal: 1000, annualRate: -1, tenureMonths: 12), throwsArgumentError);
        expect(() => emiSolver.calculateEmi(principal: 1000, annualRate: 8, tenureMonths: 0), throwsArgumentError);
      });
    });

    group('TenureSolver', () {
      test('calculates correct tenure for valid inputs', () {
        final exactEmi = emiSolver.calculateEmi(principal: 1000000, annualRate: 8.5, tenureMonths: 240);
        final tenure = tenureSolver.calculateTenure(
          principal: 1000000,
          annualRate: 8.5,
          emi: exactEmi,
        );
        expect(tenure, equals(240));
      });

      test('throws ArgumentError if EMI is too small to cover interest', () {
        final firstMonthInterest = 1000000 * (8.5 / 12 / 100);
        expect(
          () => tenureSolver.calculateTenure(
            principal: 1000000,
            annualRate: 8.5,
            emi: firstMonthInterest - 10,
          ),
          throwsArgumentError,
        );
      });
    });

    group('PrincipalSolver', () {
      test('calculates correct principal for valid inputs', () {
        final principal = principalSolver.calculatePrincipal(
          annualRate: 8.5,
          tenureMonths: 240,
          emi: 8678.23,
        );
        expect(principal, closeTo(1000000.0, 1.0)); // Rounding diffs
      });
    });

    group('RateSolver', () {
      test('calculates correct rate via Newton-Raphson/Bisection', () {
        final exactEmi = emiSolver.calculateEmi(principal: 1000000, annualRate: 8.5, tenureMonths: 240);
        final rate = rateSolver.calculateRate(
          principal: 1000000,
          emi: exactEmi,
          tenureMonths: 240,
        );
        expect(rate, closeTo(8.5, 0.001));
      });

      test('handles fallback to bisection smoothly', () {
        // Exaggerated scenario
        final rate = rateSolver.calculateRate(
          principal: 1000,
          emi: 500,
          tenureMonths: 12, // High rate
        );
        expect(rate, greaterThan(1.0));
      });
    });

    group('Amortization', () {
      test('generates accurate schedule the clears balance', () {
        final emi = emiSolver.calculateEmi(
          principal: 100000,
          annualRate: 10,
          tenureMonths: 12,
        );

        final schedule = amortization.generateReport(Loan(
          principal: 100000,
          annualRate: 10,
          tenureMonths: 12,
          emi: emi,
          loanType: LoanType.reducing,
        ));

        expect(schedule.length, equals(12));
        expect(schedule.last.closingBalance, closeTo(0, 0.01));
        
        double totalInterest = schedule.fold(0, (sum, entry) => sum + entry.interest);
        expect(totalInterest, closeTo(100000 * 10 / 100 * (12/12) / 1.8, 5000)); // Just rough bound
      });

      test('throws ArgumentError if emi is less than first month interest', () {
        expect(
          () => amortization.generateReport(Loan(
            principal: 100000,
            annualRate: 10,
            tenureMonths: 12,
            emi: 100, // Very low emi
            loanType: LoanType.reducing,
          )),
          throwsArgumentError,
        );
      });
    });
  });
}
