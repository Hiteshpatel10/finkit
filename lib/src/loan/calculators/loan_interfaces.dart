import 'package:finkit/src/loan/models/amortization_entry.dart';
import 'package:finkit/src/loan/models/loan.dart';

abstract interface class EmiSolver {
  double calculateEmi({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  });
}

abstract interface class TenureSolver {
  int calculateTenure({
    required double principal,
    required double annualRate,
    required double emi,
  });
}

abstract interface class PrincipalSolver {
  double calculatePrincipal({
    required double annualRate,
    required int tenureMonths,
    required double emi,
  });
}

abstract interface class RateSolver {
  double calculateRate({
    required double principal,
    required double emi,
    required int tenureMonths,
  });
}

abstract interface class Amortization {
  List<AmortizationEntry> generateReport(Loan loan);
}
