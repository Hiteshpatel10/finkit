enum ProcessingFeeType { percentage, flat }

/// Models for miscellaneous loan charges and processing fees.
final class LoanFees {
  final double processingFee;
  final ProcessingFeeType feeType;
  final double documentationCharges;
  final double stampDuty;
  final double otherCharges;

  const LoanFees({
    this.processingFee = 0,
    this.feeType = ProcessingFeeType.percentage,
    this.documentationCharges = 0,
    this.stampDuty = 0,
    this.otherCharges = 0,
  });

  /// Calculates total processing fee amount based on principal.
  double calculateProcessingFeeAmount(double principal) {
    return feeType == ProcessingFeeType.percentage
        ? (principal * processingFee / 100)
        : processingFee;
  }

  /// Sum of all upfront deductions.
  double totalDeductions(double principal) {
    return calculateProcessingFeeAmount(principal) +
        documentationCharges +
        stampDuty +
        otherCharges;
  }
}

/// Summary of what the borrower actually receives.
final class DisbursementSummary {
  final double grossLoanAmount;
  final double totalDeductions;
  final double netDisbursement;

  const DisbursementSummary({
    required this.grossLoanAmount,
    required this.totalDeductions,
    required this.netDisbursement,
  });
}
