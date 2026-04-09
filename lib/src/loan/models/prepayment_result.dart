import 'package:finkit/src/loan/models/loan.dart';

/// Summary of the impact of prepayments or foreclosure.
final class PrepaymentResult {
  final Loan originalLoan;
  final Loan prepaidLoan;
  
  /// Savings in interest compared to original schedule.
  final double interestSaved;
  
  /// Reduction in tenure (months).
  final int monthsSaved;
  
  /// Total fees paid for foreclosure (if any).
  final double foreclosureFees;
  
  /// netSavings = interestSaved - foreclosureFees.
  final double netSavings;

  const PrepaymentResult({
    required this.originalLoan,
    required this.prepaidLoan,
    required this.interestSaved,
    required this.monthsSaved,
    required this.foreclosureFees,
    required this.netSavings,
  });
}
