import 'package:finkit/finkit.dart';
import 'package:test/test.dart';

void main() {
  group('EpfCalculator', () {
    late EpfMaturitySolver calculator;

    setUp(() {
      calculator = EpfCalculatorFactory.createMaturitySolver();
    });

    test('Standard calculation without salary step up', () {
      final input = EpfInput(
        currentAge: 25,
        retirementAge: 58,
        basicSalaryPerMonth: 50000,
        employeeContributionPercent: 12,
        employerContributionPercent: 3.67,
        expectedAnnualSalaryIncrease: 0,
        annualInterestRate: 8.1,
      );

      final result = calculator.calculateMaturity(input);

      // Monthly total contribution is 50000 * 15.67% = 7835
      // Over 33 years = 396 months * 7835 = 31,02,660 total invested
      expect(result.totalEmployeeContribution + result.totalEmployerContribution, closeTo(3102660, 1));
      
      final yearly = result.yearlyBreakdown;
      expect(yearly.length, 33);
      expect(yearly.last.summary.closingBalance, closeTo(result.maturityAmount, 10));
    });

    test('Standard calculation with 5% salary step up', () {
      final input = EpfInput(
        currentAge: 25,
        retirementAge: 58,
        basicSalaryPerMonth: 50000,
        employeeContributionPercent: 12,
        employerContributionPercent: 3.67,
        expectedAnnualSalaryIncrease: 5, // 5% yearly increase
        annualInterestRate: 8.1,
      );

      final result = calculator.calculateMaturity(input);

      // The final maturity should be significantly higher due to step up
      expect(result.maturityAmount, greaterThan(15000000)); // Should be > 1.5 Cr
    });

    test('Throws error for invalid retirement age', () {
      final input = EpfInput(
        currentAge: 60,
        retirementAge: 58,
        basicSalaryPerMonth: 50000,
      );

      expect(
        () => calculator.calculateMaturity(input),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Retirement age must be greater'))),
      );
    });
  });
}
