import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('Compound Calculator Engine', () {
    late CompoundCalculator calc;

    setUpAll(() {
      calc = CompoundCalculator();
    });

    group('MaturitySolver (calculate)', () {
      test('Pure Lumpsum calculation', () {
        final result = calc.calculate(CompoundInput.lumpsum(
          principal: 100000,
          annualRate: 12, // 1% per month
          tenureMonths: 120, // 10 years
        ));

        // 100,000 * (1.01)^120
        expect(result.maturityAmount, closeTo(310584.82, 1.0));
        expect(result.totalInvested, equals(100000));
        expect(result.isCorpusExhausted, isFalse);
        expect(result.breakdown.length, equals(120));
      });

      test('Pure SIP calculation (end of period)', () {
        final result = calc.calculate(CompoundInput.sip(
          monthlyAmount: 5000,
          annualRate: 12,
          tenureMonths: 120,
        ));

        expect(result.totalInvested, equals(600000));
        expect(result.maturityAmount,
            closeTo(1150193.45, 1.0)); // Ordinary annuity
      });

      test('SWP exhausts corpus correctly', () {
        final result = calc.calculate(CompoundInput.swp(
          principal: 1000000, // 1M
          monthlyWithdrawal: 15000, // Very high withdrawal
          annualRate: 8,
          tenureMonths: 120,
        ));

        expect(result.isCorpusExhausted, isTrue);
        expect(result.maturityAmount, equals(0));
        expect(result.breakdown.last.closingBalance, equals(0));
      });

      test('Step-up SIP calculation', () {
        final result = calc.calculate(CompoundInput.stepUpSip(
          monthlyAmount: 5000,
          annualRate: 12,
          tenureMonths: 120,
          annualStepUpPercent: 10,
        ));

        // Invested should be higher than pure SIP
        expect(result.totalInvested, greaterThan(600000));
        expect(result.maturityAmount, greaterThan(1161695));
      });

      test('Validation guards throw ArgumentError', () {
        expect(
            () => calc.calculate(CompoundInput.lumpsum(
                principal: -100, annualRate: 12, tenureMonths: 12)),
            throwsArgumentError);
        expect(
            () => calc.calculate(CompoundInput.lumpsum(
                principal: 100, annualRate: -1, tenureMonths: 12)),
            throwsArgumentError);
        expect(
            () => calc.calculate(CompoundInput.lumpsum(
                principal: 100, annualRate: 12, tenureMonths: 0)),
            throwsArgumentError);
      });
    });

    group('Solvers', () {
      test('Contribution solver hits target', () {
        final req = calc.calculateRequiredContribution(
          targetAmount: 1150193.45,
          principal: 0,
          annualRate: 12,
          tenureMonths: 120,
          contributionTemplate: ContributionConfig(amount: 0), // Base
        );

        expect(req, closeTo(5000.0, 1.0));
      });

      test('Rate solver hits target', () {
        final rate = calc.calculateRequiredRate(
          targetAmount: 330038.68,
          principal: 100000,
          tenureMonths: 120,
        );

        expect(rate, closeTo(12.0, 0.1));
      });

      test('Tenure solver hits target', () {
        final tenure = calc.calculateRequiredTenure(
          targetAmount: 330038.68,
          principal: 100000,
          annualRate: 12,
        );

        expect(tenure, equals(120));
      });

      test('Unreachable tenure throws ArgumentError', () {
        expect(
          () => calc.calculateRequiredTenure(
            targetAmount: 200000,
            principal: 100000,
            annualRate: 0,
            contribution: null,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
