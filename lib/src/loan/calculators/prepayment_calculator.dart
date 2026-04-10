import 'dart:math';
import 'package:finkit/src/loan/models/amortization_entry.dart';
import 'package:finkit/src/loan/models/loan.dart';
import 'package:finkit/src/loan/models/prepayment_config.dart';
import 'package:finkit/src/loan/models/prepayment_result.dart';
import 'package:finkit/src/loan/models/loan_fees.dart';

final class PrepaymentCalculator {
  /// Calculates the impact of prepayments and/or foreclosure on a loan.
  ///
  /// This simulation assumes "Tenure Reduction" strategy — the monthly EMI
  /// remains constant, and extra payments directly reduce the principal balance,
  /// shortening the loan duration.
  PrepaymentResult calculate({
    required Loan loan,
    List<PrepaymentConfig> prepayments = const [],
    ForeclosureConfig? foreclosure,
  }) {
    final annualRate = loan.annualRate;
    final r = annualRate / 12 / 100;
    final entries = <AmortizationEntry>[];

    double balance = loan.principal;
    double currentEmi = loan.emi;
    int month = 1;

    // We simulate month by month until balance is zero or tenure is reached.
    while (balance > 0.01 && month <= 1000) {
      final interest = balance * r;

      // Regular EMI part
      double principalRepaid = currentEmi - interest;

      // Edge case: if remaining balance + interest is LESS than EMI
      if (balance + interest < currentEmi) {
        principalRepaid = balance;
      }

      // Prepayment part
      double extraPaid = 0;
      bool shouldRecalculateEmi = false;

      for (final config in prepayments) {
        bool isTriggered = false;
        if (config.type == PrepaymentType.oneTime) {
          if (config.month == month) isTriggered = true;
        } else {
          // Recurring
          if (month >= config.month) {
            if (config.durationMonths == null ||
                month < (config.month + config.durationMonths!)) {
              isTriggered = true;
            }
          }
        }

        if (isTriggered) {
          extraPaid += config.amount;
          if (config.strategy == PrepaymentStrategy.emiReduction) {
            shouldRecalculateEmi = true;
          }
        }
      }

      // Foreclosure part
      double extraCharges = 0;
      bool isForeclosed = false;
      if (foreclosure != null && month == foreclosure.month) {
        extraPaid = (balance - principalRepaid);
        extraCharges = extraPaid * (foreclosure.feePercentage / 100);
        isForeclosed = true;
      }

      // Cap extra payment to remaining balance
      if (extraPaid > (balance - principalRepaid)) {
        extraPaid = (balance - principalRepaid);
      }

      final openingBalance = balance;
      balance -= (principalRepaid + extraPaid);

      entries.add(
        AmortizationEntry(
          month: month,
          openingBalance: openingBalance,
          emi: (principalRepaid + interest),
          interest: interest,
          principal: principalRepaid,
          prepayment: extraPaid,
          extraCharges: extraCharges,
          closingBalance: balance < 0.01 ? 0 : balance,
        ),
      );

      if (isForeclosed) break;
      if (balance < 0.01) break;

      // If strategy is EMI reduction, recalculate EMI for NEXT month.
      // Remaining tenure = original tenure minus months already paid.
      // EMI drops so the loan still finishes around the original end date.
      if (shouldRecalculateEmi && balance > 0) {
        final remainingTenure = loan.tenureMonths - month;
        if (remainingTenure > 0) {
          currentEmi = _recalculateEmi(balance, r, remainingTenure);
        } else {
          // Safety: if somehow we're past original tenure, just pay off balance
          currentEmi = balance + (balance * r);
        }
      }

      month++;
    }

    final prepaidLoan = loan.copyWith(
      tenureMonths: entries.length,
      amortizationSchedule: entries,
    );

    final double totalForeclosureFees =
        entries.fold(0.0, (sum, e) => sum + e.extraCharges);

    // IMPORTANT: For EMI reduction strategy the EMI changes each month, so
    // `prepaidLoan.totalInterest` (which uses emi × n) would be wrong.
    // Always derive actual interest from the amortization schedule entries.
    final double actualInterestPaid =
        entries.fold(0.0, (sum, e) => sum + e.interest);
    final double interestSaved = loan.totalInterest - actualInterestPaid;
    final int monthsSaved = loan.tenureMonths - entries.length;

    return PrepaymentResult(
      originalLoan: loan,
      prepaidLoan: prepaidLoan,
      interestSaved: interestSaved,
      monthsSaved: monthsSaved,
      foreclosureFees: totalForeclosureFees,
      netSavings: interestSaved - totalForeclosureFees,
    );
  }

  double _recalculateEmi(double p, double r, int n) {
    if (r == 0) return p / n;
    return (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  /// Calculates net disbursement after deducting fees.
  DisbursementSummary calculateDisbursement({
    required double principal,
    required LoanFees fees,
  }) {
    final deductions = fees.totalDeductions(principal);
    return DisbursementSummary(
      grossLoanAmount: principal,
      totalDeductions: deductions,
      netDisbursement: principal - deductions,
    );
  }
}
