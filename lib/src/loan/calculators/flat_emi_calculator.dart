import 'package:finkit/src/loan/calculators/loan_interfaces.dart';
import 'package:finkit/src/loan/models/amortization_entry.dart';
import 'package:finkit/src/loan/models/loan.dart';

// Flat rate: interest is always calculated on the ORIGINAL principal.
// Total interest = P × r × years is fixed upfront and divided equally
// across all months — simpler but more expensive than reducing balance.

class FlatEmiCalculator
    implements
        EmiSolver,
        TenureSolver,
        PrincipalSolver,
        RateSolver,
        Amortization {
  // ─── helpers ────────────────────────────────────────────────────────────────

  double _years(int tenureMonths) => tenureMonths / 12;
  double _rate(double annualRate) => annualRate / 100;

  // ─── EMI ────────────────────────────────────────────────────────────────────

  // Formula: EMI = P × (1 + r × years) / months
  @override
  double calculateEmi({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final years = _years(tenureMonths);
    final interest = principal * _rate(annualRate) * years;
    return (principal + interest) / tenureMonths;
  }

  // ─── Tenure ─────────────────────────────────────────────────────────────────

  // Algebraic derivation:
  //   m = P / (EMI - P×r/12)
  @override
  int calculateTenure({
    required double principal,
    required double annualRate,
    required double emi,
  }) {
    final r = _rate(annualRate);
    final denominator = emi - (principal * r / 12);

    if (denominator <= 0) {
      throw ArgumentError(
        'EMI too small to ever repay the principal at this rate',
      );
    }

    return (principal / denominator).ceil();
  }

  // ─── Principal ──────────────────────────────────────────────────────────────

  // Algebraic derivation:
  //   P = EMI × months / (1 + r × years)
  @override
  double calculatePrincipal({
    required double annualRate,
    required int tenureMonths,
    required double emi,
  }) {
    final years = _years(tenureMonths);
    final r = _rate(annualRate);
    return emi * tenureMonths / (1 + r * years);
  }

  // ─── Rate ───────────────────────────────────────────────────────────────────

  // Primary: closed-form (flat formula is linear in r → algebraically solvable).
  // Fallback chain: Newton-Raphson → bisection (mirrors ReducingEmiCalculator).
  @override
  double calculateRate({
    required double principal,
    required double emi,
    required int tenureMonths,
  }) {
    try {
      return _closedForm(principal, emi, tenureMonths);
    } catch (_) {
      try {
        return _newtonRaphson(principal, emi, tenureMonths);
      } catch (_) {
        return _bisection(principal, emi, tenureMonths);
      }
    }
  }

  /// Closed-form: r = ((EMI × months / P) − 1) / years
  double _closedForm(double principal, double emi, int tenureMonths) {
    final years = _years(tenureMonths);

    if (years <= 0) throw ArgumentError('Tenure must be > 0');

    final r = ((emi * tenureMonths) / principal - 1) / years;

    if (r < 0) throw StateError('Negative rate computed, falling back');

    return r * 100; // → annual %
  }

  /// Newton-Raphson on flat EMI function.
  /// f(r) is linear → converges in exactly 1 iteration.
  double _newtonRaphson(double principal, double emi, int tenureMonths) {
    final years = _years(tenureMonths);
    double r = emi / principal;

    for (int i = 0; i < 50; i++) {
      final f = principal * (1 + r * years) / tenureMonths - emi;
      final fPrime = principal * years / tenureMonths; // constant

      if (fPrime.abs() < 1e-12) {
        throw StateError('Derivative too small, switching to bisection');
      }

      final next = r - f / fPrime;

      if (next < 0 || next > 100) {
        throw StateError('Newton-Raphson diverged, switching to bisection');
      }

      if ((next - r).abs() < 1e-12) {
        r = next;
        break;
      }

      r = next;
    }

    return r * 100; // annual %
  }

  /// Bisection fallback.
  double _bisection(double principal, double emi, int tenureMonths) {
    final years = _years(tenureMonths);
    double low = 0.0;
    double high = 100.0;
    double mid = 0.0;

    for (int i = 0; i < 100; i++) {
      mid = (low + high) / 2;

      final calculatedEmi = principal * (1 + mid * years) / tenureMonths;

      if (calculatedEmi > emi) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return mid * 100; // → annual %
  }

  // ─── Amortization ───────────────────────────────────────────────────────────

  // Flat rate: monthly interest is FIXED (always based on original principal).
  // Principal repaid each month = EMI − fixed monthly interest.
  @override
  List<AmortizationEntry> generateReport(Loan loan) {
    final entries = <AmortizationEntry>[];
    final r = _rate(loan.annualRate);
    final monthlyInterest = loan.principal * r / 12; // fixed every month
    final monthlyPrincipal = loan.emi - monthlyInterest;
    double balance = loan.principal;

    for (int i = 1; i <= loan.tenureMonths; i++) {
      final opening = balance;
      balance -= monthlyPrincipal;

      entries.add(
        AmortizationEntry(
          month: i,
          openingBalance: opening,
          emi: loan.emi,
          interest: monthlyInterest,
          principal: monthlyPrincipal,
          closingBalance: balance < 0 ? 0 : balance,
        ),
      );
    }

    return entries;
  }
}
