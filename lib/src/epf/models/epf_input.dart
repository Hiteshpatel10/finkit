/// Input parameters for an Employees' Provident Fund (EPF) calculation.
final class EpfInput {
  /// The current age of the employee.
  final int currentAge;

  /// The expected retirement age. Typically 58 or 60 in India.
  final int retirementAge;

  /// The current basic salary + dearness allowance (DA) per month.
  final double basicSalaryPerMonth;

  /// The percentage of basic salary the employee contributes to EPF. Default is 12%.
  final double employeeContributionPercent;

  /// The percentage of basic salary the employer contributes to EPF. Default is 3.67%.
  /// (The remaining 8.33% goes to EPS, which is a pension scheme and doesn't compound in the corpus).
  final double employerContributionPercent;

  /// The expected annual percentage increase in the basic salary.
  final double expectedAnnualSalaryIncrease;

  /// Any existing balance in the EPF account. Default is 0.
  final double currentEpfBalance;

  /// The annual interest rate set by the government. Default is typically around 8.1%.
  final double annualInterestRate;

  const EpfInput({
    required this.currentAge,
    this.retirementAge = 58,
    required this.basicSalaryPerMonth,
    this.employeeContributionPercent = 12.0,
    this.employerContributionPercent = 3.67,
    this.expectedAnnualSalaryIncrease = 0.0, // Assuming 0 if not provided
    this.currentEpfBalance = 0.0,
    this.annualInterestRate = 8.1,
  });
}
