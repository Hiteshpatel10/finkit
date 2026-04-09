import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('ForeclosurePlanner', () {
    final planner = ForeclosurePlanner();

    test('generates a comprehensive plan with multiple stages', () {
      final loan = Loan(
        principal: 1000000,
        annualRate: 10,
        tenureMonths: 240,
        emi: 9650.22,
        loanType: LoanType.reducing,
      );

      final plan = planner.generatePlan(
        loan: loan,
        prepaymentAmount: 50000,
      );

      expect(plan.stageComparisons.length, equals(3));
      
      // Verify timing labels
      expect(plan.stageComparisons[0].timingLabel, equals("Early"));
      expect(plan.stageComparisons[1].timingLabel, equals("Mid"));
      expect(plan.stageComparisons[2].timingLabel, equals("Late"));

      // Verify that Tenure Reduction generally saves more than EMI Reduction
      for (final stage in plan.stageComparisons) {
        final tenureSaved = stage.getResult(PrepaymentStrategy.tenureReduction)!.interestSaved;
        final emiSaved = stage.getResult(PrepaymentStrategy.emiReduction)!.interestSaved;
        
        expect(tenureSaved, greaterThan(emiSaved));
      }
    });

    test('recommends early prepayment for maximum savings', () {
      final loan = Loan(
        principal: 1000000,
        annualRate: 10,
        tenureMonths: 120, // 10 years
        emi: 13215.07,
        loanType: LoanType.reducing,
      );

      final plan = planner.generatePlan(
        loan: loan,
        prepaymentAmount: 100000,
      );

      // Early prepayment (Month 30 for 120 months) should be the recommendation
      expect(plan.recommendedScenario.$2, equals(30)); 
      expect(plan.recommendedScenario.$1, equals(PrepaymentStrategy.tenureReduction));
    });
  });
}
