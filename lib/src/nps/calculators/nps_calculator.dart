import 'package:finkit/src/compound/calculators/compound_calculator.dart';
import 'package:finkit/src/compound/models/compound_frequency.dart';
import 'package:finkit/src/compound/models/compound_input.dart';
import 'package:finkit/src/compound/models/contribution_config.dart';
import 'package:finkit/src/compound/models/payment_config.dart';
import 'package:finkit/src/nps/calculators/nps_interfaces.dart';
import 'package:finkit/src/nps/models/nps_input.dart';
import 'package:finkit/src/nps/models/nps_result.dart';

final class NpsCalculator implements NpsMaturitySolver {
  final CompoundCalculator _compoundCalculator;

  NpsCalculator(this._compoundCalculator);

  @override
  NpsResult calculateMaturity(NpsInput input) {
    if (input.retirementAge <= input.currentAge) {
      throw ArgumentError(
          'Retirement age must be greater than current age. '
          'Attempted: ${input.retirementAge} <= ${input.currentAge}');
    }

    if (input.annuityPurchasePercentage < 40.0 || input.annuityPurchasePercentage > 100.0) {
      throw ArgumentError(
          'Annuity purchase percentage must be between 40 and 100. '
          'Attempted: ${input.annuityPurchasePercentage}');
    }

    final tenureYears = input.retirementAge - input.currentAge;

    // NPS is market-linked, so we typically compound monthly
    final compoundInput = CompoundInput(
      principal: input.currentNpsBalance,
      annualRate: input.expectedReturnRate,
      tenureMonths: tenureYears * 12,
      compoundFrequency: CompoundFrequency.monthly,
      contribution: ContributionConfig(
        amount: input.monthlyContribution,
        frequency: PaymentFrequency.monthly,
        timing: PaymentTiming.end,
      ),
    );

    final compoundResult = _compoundCalculator.calculate(compoundInput);
    final totalCorpus = compoundResult.maturityAmount;

    final annuityAmount = totalCorpus * (input.annuityPurchasePercentage / 100.0);
    final lumpSumAmount = totalCorpus - annuityAmount;

    // Simple interest for monthly pension based on expected annuity rate
    final expectedMonthlyPension = (annuityAmount * (input.expectedAnnuityRate / 100.0)) / 12.0;

    return NpsResult(
      totalCorpus: totalCorpus,
      totalInvested: compoundResult.totalInvested,
      totalInterest: compoundResult.totalInterest,
      lumpSumAmount: lumpSumAmount,
      annuityAmount: annuityAmount,
      expectedMonthlyPension: expectedMonthlyPension,
      breakdown: compoundResult.breakdown,
    );
  }
}
