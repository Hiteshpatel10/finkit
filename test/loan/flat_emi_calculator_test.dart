import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('Flat EMI Calculator', () {
    late EmiSolver emiSolver;
    late TenureSolver tenureSolver;
    late PrincipalSolver principalSolver;
    late RateSolver rateSolver;
    late Amortization amortization;

    setUpAll(() {
      final registry = LoanCalculatorFactory().create(LoanType.flat);
      emiSolver = registry.require<EmiSolver>();
      tenureSolver = registry.require<TenureSolver>();
      principalSolver = registry.require<PrincipalSolver>();
      rateSolver = registry.require<RateSolver>();
      amortization = registry.require<Amortization>();
    });

    group('EmiSolver', () {
      test('calculates correct flat EMI for valid inputs', () {
        // P=100k, R=10% flat, N=24 -> Total Interest = 100k * 0.1 * 2 = 20k
        // Total = 120k / 24 = 5k per month
        final emi = emiSolver.calculateEmi(
          principal: 100000,
          annualRate: 10,
          tenureMonths: 24,
        );
        expect(emi, equals(5000.0));
      });

      test('throws ArgumentError on invalid inputs', () {
        expect(() => emiSolver.calculateEmi(principal: -1, annualRate: 10, tenureMonths: 24), throwsArgumentError);
        expect(() => emiSolver.calculateEmi(principal: 100000, annualRate: -1, tenureMonths: 24), throwsArgumentError);
        expect(() => emiSolver.calculateEmi(principal: 100000, annualRate: 10, tenureMonths: 0), throwsArgumentError);
      });
    });

    group('TenureSolver', () {
      test('calculates correct tenure for flat rate', () {
        final tenure = tenureSolver.calculateTenure(
          principal: 100000,
          annualRate: 10,
          emi: 5000,
        );
        expect(tenure, equals(24));
      });

      test('throws ArgumentError if EMI is too small to cover flat interest',
          () {
        // Flat monthly interest is 100k * 0.1 / 12 = 833.33
        expect(
          () => tenureSolver.calculateTenure(
            principal: 100000,
            annualRate: 10,
            emi: 800,
          ),
          throwsArgumentError,
        );
      });
    });

    group('PrincipalSolver', () {
      test('calculates correct principal', () {
        final p = principalSolver.calculatePrincipal(
          annualRate: 10,
          tenureMonths: 24,
          emi: 5000,
        );
        expect(p, closeTo(100000.0, 0.01));
      });
    });

    group('RateSolver', () {
      test('calculates correct rate via closed-form', () {
        final rate = rateSolver.calculateRate(
          principal: 100000,
          emi: 5000,
          tenureMonths: 24,
        );
        expect(rate, closeTo(10.0, 0.001));
      });
    });

    group('Amortization', () {
      test('generates linear flat rate schedule', () {
        final emi = emiSolver.calculateEmi(
          principal: 120000,
          annualRate: 10,
          tenureMonths: 12,
        );

        // Monthy Interest = 120k * 0.1 * 1 year = 12k / 12 = 1000/month
        // EMI = 11000, so Principal = 10000/month

        final schedule = amortization.generateReport(Loan(
          principal: 120000,
          annualRate: 10,
          tenureMonths: 12,
          emi: emi,
          loanType: LoanType.flat,
        ));

        expect(schedule.length, equals(12));
        expect(schedule.first.interest, closeTo(1000.0, 0.01));
        expect(schedule.last.interest, closeTo(1000.0, 0.01)); // It's flat!
        expect(schedule.last.closingBalance, closeTo(0, 0.01));
      });

      test('throws if EMI is less than flat interest', () {
        expect(
          () => amortization.generateReport(Loan(
            principal: 120000,
            annualRate: 10,
            tenureMonths: 12,
            emi: 500, // Very low!
            loanType: LoanType.flat,
          )),
          throwsArgumentError,
        );
      });
    });
  });
}
