import 'package:finkit/finkit.dart';

void main() {
  final registry = XirrCalculatorFactory().create(XirrType.standard);
  final solver = registry.require<XirrSolver>();

  // Scenario 1
  final r1 = solver.calculate([
    XirrCashFlow(date: DateTime(2023, 1, 1),  amount: -1000),
    XirrCashFlow(date: DateTime(2023, 3, 15), amount: -2500),
    XirrCashFlow(date: DateTime(2023, 9, 30), amount:  4000),
  ]);
  print('Scenario 1: ${r1.annualizedReturn}% (converged: ${r1.converged})');

  // Scenario 2
  final r2 = solver.calculate([
    XirrCashFlow(date: DateTime(2021, 6, 1),  amount: -5000),
    XirrCashFlow(date: DateTime(2022, 1, 15), amount: -3000),
    XirrCashFlow(date: DateTime(2023, 6, 1),  amount: 10000),
  ]);
  print('Scenario 2: ${r2.annualizedReturn}% (converged: ${r2.converged})');
}
