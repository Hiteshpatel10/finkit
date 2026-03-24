import 'dart:math';
import 'package:finkit/src/loan/calculators/loan_interfaces.dart';
import 'package:finkit/src/loan/models/amortization_entry.dart';
import 'package:finkit/src/loan/models/loan.dart';

// Reducing balance (a.k.a. diminishing balance) means interest is charged
// each month on the OUTSTANDING principal, not the original amount.
// This results in a lower total interest cost compared to flat rate loans.

final class ReducingEmiCalculator
    implements
        EmiSolver,
        TenureSolver,
        PrincipalSolver,
        RateSolver,
        Amortization {
  // ─── helpers ────────────────────────────────────────────────────────────────

  /// Converts annual rate % → monthly rate fraction.
  /// e.g. 12% p.a. → 0.01 per month
  double _monthlyRate(double annualRate) => annualRate / 12 / 100;

  // ─── EMI ────────────────────────────────────────────────────────────────────

  // Standard reducing-balance EMI formula (derived from present value of annuity):
  //   EMI = P × r × (1 + r)^n / ((1 + r)^n − 1)
  //
  // where:
  //   P = principal
  //   r = monthly interest rate (decimal)
  //   n = tenure in months
  //
  // Edge case: r = 0 (zero interest loan) → EMI = P / n
  @override
  double calculateEmi({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    if (principal < 0) {
      throw ArgumentError.value(principal, 'principal', 'Must be >= 0');
    }
    if (annualRate < 0) {
      throw ArgumentError.value(annualRate, 'annualRate', 'Must be >= 0');
    }
    if (tenureMonths <= 0) {
      throw ArgumentError.value(tenureMonths, 'tenureMonths', 'Must be > 0');
    }

    final r = _monthlyRate(annualRate);

    if (r == 0) return principal / tenureMonths;

    return (principal * r * pow(1 + r, tenureMonths)) /
        (pow(1 + r, tenureMonths) - 1);
  }

  // ─── Tenure ─────────────────────────────────────────────────────────────────

  // Algebraic derivation from EMI formula:
  //   n = log(EMI / (EMI − P×r)) / log(1 + r)
  //
  // Guard: if EMI ≤ P×r, the EMI doesn't even cover the first month's interest
  // → loan can never be repaid.
  @override
  int calculateTenure({
    required double principal,
    required double annualRate,
    required double emi,
  }) {
    if (principal < 0) {
      throw ArgumentError.value(principal, 'principal', 'Must be >= 0');
    }
    if (annualRate < 0) {
      throw ArgumentError.value(annualRate, 'annualRate', 'Must be >= 0');
    }
    if (emi <= 0) {
      throw ArgumentError.value(emi, 'emi', 'Must be > 0');
    }

    final r = _monthlyRate(annualRate);

    if (r == 0) return (principal / emi).ceil();

    if (emi <= principal * r) {
      throw ArgumentError('EMI too small for given principal and rate');
    }

    final n = log(emi / (emi - principal * r)) / log(1 + r);

    return n.ceil();
  }

  // ─── Principal ──────────────────────────────────────────────────────────────

  // Algebraic derivation from EMI formula:
  //   P = EMI × ((1+r)^n − 1) / (r × (1+r)^n)
  //
  // This is equivalent to: P = EMI × [present value annuity factor]
  //
  // Edge case: r = 0 → P = EMI × n
  @override
  double calculatePrincipal({
    required double annualRate,
    required int tenureMonths,
    required double emi,
  }) {
    if (annualRate < 0) {
      throw ArgumentError.value(annualRate, 'annualRate', 'Must be >= 0');
    }
    if (tenureMonths <= 0) {
      throw ArgumentError.value(tenureMonths, 'tenureMonths', 'Must be > 0');
    }
    if (emi <= 0) {
      throw ArgumentError.value(emi, 'emi', 'Must be > 0');
    }

    final r = _monthlyRate(annualRate);

    if (r == 0) return emi * tenureMonths;

    return emi *
        (pow(1 + r, tenureMonths) - 1) /
        (r * pow(1 + r, tenureMonths));
  }

  // ─── Rate ───────────────────────────────────────────────────────────────────

  // Reducing balance rate has NO closed-form algebraic solution —
  // r appears both as a base and inside an exponent (transcendental equation).
  // We solve numerically: Newton-Raphson first, bisection as fallback.
  @override
  double calculateRate({
    required double principal,
    required double emi,
    required int tenureMonths,
  }) {
    if (principal <= 0) {
      throw ArgumentError.value(principal, 'principal', 'Must be > 0');
    }
    if (emi <= 0) {
      throw ArgumentError.value(emi, 'emi', 'Must be > 0');
    }
    if (tenureMonths <= 0) {
      throw ArgumentError.value(tenureMonths, 'tenureMonths', 'Must be > 0');
    }

    try {
      return _newtonRaphson(principal, emi, tenureMonths);
    } catch (_) {
      return _bisection(principal, emi, tenureMonths);
    }
  }

  /// Newton-Raphson: converges in ~10 iterations using tangent line approximation.
  ///
  ///   f(r)  = P × r × (1+r)^n / ((1+r)^n − 1) − EMI  →  want f(r) = 0
  ///   f'(r) = d/dr [ P × r × (1+r)^n / ((1+r)^n − 1) ]  (via quotient rule)
  ///   r₁    = r₀ − f(r₀) / f'(r₀)
  double _newtonRaphson(double principal, double emi, int tenureMonths) {
    final n = tenureMonths;
    double r = emi / principal; // initial guess: rough monthly rate

    for (int i = 0; i < 50; i++) {
      final factor = pow(1 + r, n).toDouble();

      // f(r): difference between EMI at current guess and the target EMI
      final f = (principal * r * factor) / (factor - 1) - emi;

      // f'(r): derivative via quotient rule
      final numerator =
          factor * (n * r - (1 + r) * ((factor - 1) / factor)) + n * r;
      final denominator = pow(factor - 1, 2).toDouble();
      final fPrime = principal * numerator / denominator;

      // Guard 1: derivative near zero → step would blow up
      if (fPrime.abs() < 1e-12) {
        throw StateError('Derivative too small, switching to bisection');
      }

      final next = r - f / fPrime;

      // Guard 2: guess left valid monthly rate range (0, 50%]
      if (next <= 0 || next > 0.5) {
        throw StateError('Newton-Raphson diverged, switching to bisection');
      }

      if ((next - r).abs() < 1e-12) {
        r = next;
        break;
      }

      r = next;
    }

    return r * 12 * 100; // monthly fraction → annual %
  }

  /// Bisection fallback: guaranteed to converge but slower (~100 iterations).
  ///
  /// Valid because EMI is monotonically increasing with rate.
  /// After 100 iterations precision ≈ 4×10⁻³¹ — far beyond practical need.
  double _bisection(double principal, double emi, int tenureMonths) {
    double low = 0.0;
    double high = 0.5; // 50% monthly cap
    double mid = 0.0;

    for (int i = 0; i < 100; i++) {
      mid = (low + high) / 2;

      final calculatedEmi =
          (principal * mid * pow(1 + mid, tenureMonths)) /
          (pow(1 + mid, tenureMonths) - 1);

      if (calculatedEmi > emi) {
        high = mid; // rate too high → search lower half
      } else {
        low = mid; // rate too low  → search upper half
      }
    }

    return mid * 12 * 100; // monthly fraction → annual %
  }

  // ─── Amortization ───────────────────────────────────────────────────────────

  // Reducing balance: interest each month is charged on the OUTSTANDING balance,
  // so interest shrinks and principal repaid grows with every payment.
  //
  //   interest  = opening balance × monthly rate
  //   principal = EMI − interest
  //   closing   = opening − principal
  @override
  List<AmortizationEntry> generateReport(Loan loan) {
    if (loan.principal <= 0) {
      throw ArgumentError.value(
        loan.principal, 'loan.principal', 'Must be > 0');
    }
    if (loan.tenureMonths <= 0) {
      throw ArgumentError.value(
        loan.tenureMonths, 'loan.tenureMonths', 'Must be > 0');
    }

    final r = _monthlyRate(loan.annualRate);
    final firstMonthInterest = loan.principal * r;
    if (loan.emi <= firstMonthInterest) {
      throw ArgumentError(
        'EMI (${loan.emi}) must exceed the first month\'s interest '
        '(${firstMonthInterest.toStringAsFixed(2)}) to repay the loan');
    }

    final entries = <AmortizationEntry>[];
    double balance = loan.principal;

    for (int i = 1; i <= loan.tenureMonths; i++) {
      final interest = balance * r;
      final principal = loan.emi - interest;
      balance -= principal;

      entries.add(
        AmortizationEntry(
          month: i,
          openingBalance: balance + principal,
          emi: loan.emi,
          interest: interest,
          principal: principal,
          closingBalance: balance < 0 ? 0 : balance,
        ),
      );
    }

    return entries;
  }
}
