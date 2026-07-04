import 'package:finkit/finkit.dart';
import 'package:test/test.dart';

void main() {
  group('NpsCalculator', () {
    late NpsMaturitySolver calculator;

    setUp(() {
      calculator = NpsCalculatorFactory.createMaturitySolver();
    });

    test('Standard calculation (5000/mo, 30 yrs, 10% return)', () {
      final input = NpsInput(
        currentAge: 30,
        retirementAge: 60,
        monthlyContribution: 5000,
        expectedReturnRate: 10,
        annuityPurchasePercentage: 40.0,
        expectedAnnuityRate: 6.0,
      );

      final result = calculator.calculateMaturity(input);

      // Total invested = 5000 * 12 * 30 = 18,00,000
      expect(result.totalInvested, closeTo(1800000, 1));
      
      // Total corpus @ 10% monthly compounding is around 1,13,02,439
      expect(result.totalCorpus, closeTo(11302439.62, 10));

      // 40% annuity, 60% lump sum
      expect(result.annuityAmount, closeTo(result.totalCorpus * 0.40, 1));
      expect(result.lumpSumAmount, closeTo(result.totalCorpus * 0.60, 1));

      // Monthly pension = (Annuity * 6%) / 12 = Annuity * 0.06 / 12
      final expectedPension = (result.annuityAmount * 0.06) / 12;
      expect(result.expectedMonthlyPension, closeTo(expectedPension, 1));

      final yearly = result.yearlyBreakdown;
      expect(yearly.length, 30);
      expect(yearly.last.summary.closingBalance, closeTo(result.totalCorpus, 10));
    });

    test('Throws error for invalid retirement age', () {
      final input = NpsInput(
        currentAge: 60,
        retirementAge: 58,
        monthlyContribution: 5000,
        expectedReturnRate: 10,
        expectedAnnuityRate: 6,
      );

      expect(
        () => calculator.calculateMaturity(input),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Retirement age must be greater'))),
      );
    });

    test('Throws error for invalid annuity purchase percentage', () {
      final input = NpsInput(
        currentAge: 30,
        monthlyContribution: 5000,
        expectedReturnRate: 10,
        annuityPurchasePercentage: 30.0, // Below 40%
        expectedAnnuityRate: 6,
      );

      expect(
        () => calculator.calculateMaturity(input),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Annuity purchase percentage must be between 40 and 100'))),
      );
    });
  });
}
