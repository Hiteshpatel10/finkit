import 'package:finkit/src/compound/calculators/compound_calculator.dart';
import 'package:finkit/src/compound/models/compound_frequency.dart';
import 'package:finkit/src/compound/models/compound_input.dart';
import 'package:finkit/src/compound/models/contribution_config.dart';
import 'package:finkit/src/compound/models/payment_config.dart';
import 'package:finkit/src/epf/calculators/epf_interfaces.dart';
import 'package:finkit/src/epf/models/epf_input.dart';
import 'package:finkit/src/epf/models/epf_result.dart';

final class EpfCalculator implements EpfMaturitySolver {
  final CompoundCalculator _compoundCalculator;

  EpfCalculator(this._compoundCalculator);

  @override
  EpfResult calculateMaturity(EpfInput input) {
    if (input.retirementAge <= input.currentAge) {
      throw ArgumentError(
          'Retirement age must be greater than current age. '
          'Attempted: ${input.retirementAge} <= ${input.currentAge}');
    }

    final tenureYears = input.retirementAge - input.currentAge;
    
    // Monthly EPF contribution (employee + employer EPF portion)
    final totalContributionPercent = input.employeeContributionPercent + input.employerContributionPercent;
    final initialMonthlyContribution = input.basicSalaryPerMonth * (totalContributionPercent / 100);

    // Setup CompoundInput
    // EPF interest is calculated monthly on opening balance and credited annually.
    // CompoundFrequency.yearly with PaymentTiming.end correctly models this.
    final compoundInput = CompoundInput(
      principal: input.currentEpfBalance,
      annualRate: input.annualInterestRate,
      tenureMonths: tenureYears * 12,
      compoundFrequency: CompoundFrequency.yearly,
      contribution: ContributionConfig(
        amount: initialMonthlyContribution,
        frequency: PaymentFrequency.monthly,
        timing: PaymentTiming.end,
        stepUp: input.expectedAnnualSalaryIncrease > 0 
            ? PercentageStepUp(input.expectedAnnualSalaryIncrease) 
            : null,
      ),
    );

    // Calculate using the core engine
    final compoundResult = _compoundCalculator.calculate(compoundInput);

    // Calculate splits
    final totalNewContributions = compoundResult.totalInvested - input.currentEpfBalance;
    
    double totalEmployeeCont = 0;
    double totalEmployerCont = 0;
    
    if (totalContributionPercent > 0) {
      final employeeRatio = input.employeeContributionPercent / totalContributionPercent;
      final employerRatio = input.employerContributionPercent / totalContributionPercent;
      
      totalEmployeeCont = totalNewContributions * employeeRatio;
      totalEmployerCont = totalNewContributions * employerRatio;
    }

    return EpfResult(
      maturityAmount: compoundResult.maturityAmount,
      totalEmployeeContribution: totalEmployeeCont,
      totalEmployerContribution: totalEmployerCont,
      totalInterest: compoundResult.totalInterest,
      breakdown: compoundResult.breakdown,
    );
  }
}
