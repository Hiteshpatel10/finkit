import 'package:finkit/src/compound/calculators/compound_calculator.dart';
import 'package:finkit/src/compound/models/compound_frequency.dart';
import 'package:finkit/src/compound/models/compound_input.dart';
import 'package:finkit/src/compound/models/contribution_config.dart';
import 'package:finkit/src/compound/models/payment_config.dart';
import 'package:finkit/src/ppf/calculators/ppf_interfaces.dart';
import 'package:finkit/src/ppf/models/ppf_input.dart';
import 'package:finkit/src/ppf/models/ppf_result.dart';

final class PpfCalculator implements PpfMaturitySolver {
  final CompoundCalculator _compoundCalculator;

  PpfCalculator(this._compoundCalculator);

  @override
  PpfResult calculateMaturity(PpfInput input) {
    // 1. Validate rules
    final yearlyTotal = input.depositFrequency == PaymentFrequency.monthly
        ? input.depositAmount * 12
        : input.depositAmount;

    if (yearlyTotal > 150000) {
      throw ArgumentError(
          'Maximum allowed PPF investment per financial year is ₹1,50,000. '
          'Attempted: ₹$yearlyTotal');
    }
    if (yearlyTotal < 500) {
      throw ArgumentError(
          'Minimum required PPF investment per financial year is ₹500. '
          'Attempted: ₹$yearlyTotal');
    }

    // 2. Map to CompoundInput
    // PPF interest is calculated monthly (on lowest balance) but credited/compounded yearly.
    // The CompoundCalculator models this accurately if we use CompoundFrequency.yearly
    // and pass the correct payment timing (beginning for <= 5th, end for > 5th).
    final compoundInput = CompoundInput(
      principal: 0,
      annualRate: input.annualInterestRate,
      tenureMonths: input.tenureYears * 12,
      compoundFrequency: CompoundFrequency.yearly,
      contribution: ContributionConfig(
        amount: input.depositAmount,
        frequency: input.depositFrequency,
        timing: input.depositTiming,
      ),
    );

    // 3. Calculate using the core engine
    final compoundResult = _compoundCalculator.calculate(compoundInput);

    // 4. Wrap the result
    return PpfResult(
      maturityAmount: compoundResult.maturityAmount,
      totalInvested: compoundResult.totalInvested,
      totalInterest: compoundResult.totalInterest,
      breakdown: compoundResult.breakdown,
    );
  }
}
