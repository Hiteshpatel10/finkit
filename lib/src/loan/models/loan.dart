import 'amortization_entry.dart';

enum LoanType { reducing, flat }

/// Immutable value object representing a fully configured loan.
///
/// Use [copyWith] to produce updated instances — never mutate directly.
final class Loan {
  final double principal;
  final double annualRate;
  final int tenureMonths;
  final double emi;
  final LoanType loanType;
  final List<AmortizationEntry>? amortizationSchedule;

  const Loan({
    required this.principal,
    required this.annualRate,
    required this.tenureMonths,
    required this.emi,
    required this.loanType,
    this.amortizationSchedule,
  });

  /// Total amount paid over the loan tenure.
  double get totalPayment => emi * tenureMonths;

  /// Total interest paid = total payment − original principal.
  double get totalInterest => totalPayment - principal;

  Loan copyWith({
    double? principal,
    double? annualRate,
    int? tenureMonths,
    double? emi,
    LoanType? loanType,
    List<AmortizationEntry>? amortizationSchedule,
  }) {
    return Loan(
      principal: principal ?? this.principal,
      annualRate: annualRate ?? this.annualRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      emi: emi ?? this.emi,
      loanType: loanType ?? this.loanType,
      amortizationSchedule: amortizationSchedule != null
          ? List.unmodifiable(amortizationSchedule)
          : this.amortizationSchedule,
    );
  }
}
