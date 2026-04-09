import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('PrepaymentCalculator', () {
    final calculator = PrepaymentCalculator();
    
    // Setup a basic loan: 100,000 @ 12% for 12 months
    // Standard EMI: 8884.88
    final loan = Loan(
      principal: 100000,
      annualRate: 12,
      tenureMonths: 12,
      emi: 8884.88,
      loanType: LoanType.reducing,
    );

    test('One-time prepayment reduces tenure and interest', () {
      final prepayments = [
        PrepaymentConfig(amount: 20000, month: 3),
      ];

      final result = calculator.calculate(loan: loan, prepayments: prepayments);

      expect(result.monthsSaved, greaterThan(0));
      expect(result.interestSaved, greaterThan(0));
      expect(result.prepaidLoan.tenureMonths, lessThan(12));
      
      // Check if prepayment is recorded in the 3rd month
      final entry = result.prepaidLoan.amortizationSchedule![2];
      expect(entry.month, 3);
      expect(entry.prepayment, 20000);
    });

    test('Recurring prepayment reduces tenure significantly', () {
      final prepayments = [
        PrepaymentConfig(
          amount: 5000, 
          month: 1, 
          type: PrepaymentType.recurring
        ),
      ];

      final result = calculator.calculate(loan: loan, prepayments: prepayments);

      expect(result.monthsSaved, greaterThan(3)); 
      expect(result.prepaidLoan.tenureMonths, lessThanOrEqualTo(8));
    });

    test('Foreclosure closes loan with fees', () {
      final foreclosure = ForeclosureConfig(month: 6, feePercentage: 2.0);

      final result = calculator.calculate(loan: loan, foreclosure: foreclosure);

      expect(result.prepaidLoan.tenureMonths, 6);
      expect(result.prepaidLoan.amortizationSchedule!.last.closingBalance, 0);
      
      // Fees should be 2% of the outstanding balance after 6th EMI
      // Outstanding balance after 5 months is roughly ~60k
      expect(result.foreclosureFees, greaterThan(0));
    });

    test('Calculate Disbursement summary correctly', () {
      final fees = LoanFees(
        processingFee: 1.0, // 1%
        documentationCharges: 500,
        stampDuty: 100,
      );

      final summary = calculator.calculateDisbursement(
        principal: 100000, 
        fees: fees
      );

      expect(summary.totalDeductions, 1000 + 500 + 100);
      expect(summary.netDisbursement, 100000 - 1600);
    });
  });
}
