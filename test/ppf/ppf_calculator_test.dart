import 'package:finkit/finkit.dart';
import 'package:test/test.dart';

void main() {
  group('PpfCalculator', () {
    late PpfMaturitySolver calculator;

    setUp(() {
      calculator = PpfCalculatorFactory.createMaturitySolver();
    });

    test('Standard yearly investment (₹1,50,000) for 15 years', () {
      final input = PpfInput(
        depositAmount: 150000,
        depositFrequency: PaymentFrequency.yearly,
        depositTiming: PaymentTiming.beginning, // At the start of the year
        tenureYears: 15,
        annualInterestRate: 7.1,
      );

      final result = calculator.calculateMaturity(input);

      // Verify overall totals
      expect(result.totalInvested, closeTo(2250000, 1));
      // Standard PPF maturity for 1.5L yearly @ 7.1% is around 40,68,209
      expect(result.maturityAmount, closeTo(4068209, 10));

      final yearly = result.yearlyBreakdown;
      expect(yearly.length, 15);
      expect(yearly.last.summary.closingBalance, closeTo(result.maturityAmount, 10));
    });

    test('Monthly investment (₹12,500) before 5th', () {
      final input = PpfInput(
        depositAmount: 12500,
        depositFrequency: PaymentFrequency.monthly,
        depositTiming: PaymentTiming.beginning,
        tenureYears: 15,
        annualInterestRate: 7.1,
      );

      final result = calculator.calculateMaturity(input);

      // Monthly investment of 12500 * 12 = 1.5L yearly
      expect(result.totalInvested, closeTo(2250000, 1));
      // Because it's monthly, it will be slightly less than yearly deposit at start of year
      // But more than yearly deposit at end of year.
      // E.g., 40,68,209 is for yearly at start.
      expect(result.maturityAmount, lessThan(4068209));
      expect(result.maturityAmount, greaterThan(2250000));
    });

    test('Throws error for exceeding maximum limit', () {
      final input = PpfInput(
        depositAmount: 200000, // Exceeds 1.5L limit
        depositFrequency: PaymentFrequency.yearly,
      );

      expect(
        () => calculator.calculateMaturity(input),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Maximum allowed'))),
      );
    });

    test('Throws error for being below minimum limit', () {
      final input = PpfInput(
        depositAmount: 400, // Below 500 limit
        depositFrequency: PaymentFrequency.yearly,
      );

      expect(
        () => calculator.calculateMaturity(input),
        throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Minimum required'))),
      );
    });
  });
}
