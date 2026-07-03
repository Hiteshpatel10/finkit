import 'package:finkit/finkit.dart';
void main() {
  final input = CompoundInput(
    principal: 0,
    annualRate: 7,
    tenureMonths: 12,
    compoundFrequency: CompoundFrequency.monthly,
    contribution: ContributionConfig(
      amount: 5000,
      frequency: PaymentFrequency.monthly,
    ),
  );
  final res = CompoundCalculatorFactory().create(CompoundType.sip).get<CompoundMaturitySolver>()!.calculate(input);
  print(res.maturityAmount);
  print(res.totalInvested);
}
