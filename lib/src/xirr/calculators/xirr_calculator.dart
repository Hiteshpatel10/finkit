import 'dart:math';

import 'package:finkit/src/xirr/calculators/xirr_interfaces.dart';
import 'package:finkit/src/xirr/models/xirr_cash_flow.dart';
import 'package:finkit/src/xirr/models/xirr_result.dart';

/// Core engine for XIRR (Extended Internal Rate of Return) calculations.
///
/// ## Algorithm
///
/// XIRR solves for the annualized rate `r` such that:
///
/// ```
/// Σ  Cᵢ / (1 + r)^tᵢ  =  0
/// ```
///
/// where:
/// - `Cᵢ` is the cash flow amount (negative = outflow, positive = inflow).
/// - `tᵢ = (dateᵢ − date₀).inDays / 365.0` is the year-fraction from the
///   first cash flow date, using the **ACT/365** day-count convention
///   (identical to Excel / Google Sheets XIRR).
///
/// ## Solver Strategy
///
/// 1. **Newton-Raphson** (primary): fast quadratic convergence from an
///    initial guess of 10% (r = 0.10). Runs for up to [_maxIterations]
///    steps or until |f(r)| < [_tolerance].
///
/// 2. **Bisection fallback**: activated when Newton-Raphson diverges
///    (produces NaN/Infinity or overshoots). Searches the bracket
///    [−0.9999, +100.0] for a sign change, then bisects down to
///    [_tolerance] precision.
///
/// Returns an [XirrResult] with `converged: false` only when both methods
/// fail to find a root (degenerate inputs that somehow pass validation).
final class XirrCalculator implements XirrSolver {
  static const double _tolerance = 1e-7;
  static const int _maxIterations = 200;

  @override
  XirrResult calculate(List<XirrCashFlow> cashFlows) {
    _validate(cashFlows);

    // Sort ascending by date so t₀ = 0 is always the earliest flow.
    final sorted = List<XirrCashFlow>.from(cashFlows)
      ..sort((a, b) => a.date.compareTo(b.date));

    final date0 = sorted.first.date;
    final t = sorted
        .map((cf) => cf.date.difference(date0).inDays / 365.0)
        .toList(growable: false);
    final c = sorted.map((cf) => cf.amount).toList(growable: false);

    // ── Newton-Raphson ──────────────────────────────────────────────────────
    double r = 0.10; // initial guess: 10%
    int iterations = 0;

    for (; iterations < _maxIterations; iterations++) {
      final fVal = _npv(r, c, t);
      final dfVal = _dnpv(r, c, t);

      if (dfVal.abs() < 1e-12) break; // avoid division by near-zero derivative

      final rNext = r - fVal / dfVal;

      // Guard against divergence: if the step produces an invalid value or
      // pushes r below −1 (undefined for (1+r)^t), fall through to bisection.
      if (rNext.isNaN || rNext.isInfinite || rNext <= -1.0) break;

      if ((rNext - r).abs() < _tolerance) {
        return XirrResult(
          annualizedReturn: rNext * 100,
          iterations: iterations + 1,
          converged: true,
        );
      }

      r = rNext;
    }

    // ── Bisection fallback ──────────────────────────────────────────────────
    const double lo = -0.9999;
    const double hi = 100.0; // 10 000% upper bound — covers any realistic case

    final fLo = _npv(lo, c, t);
    final fHi = _npv(hi, c, t);

    // If there is no sign change in [lo, hi] the root is not bracketed.
    if (fLo * fHi > 0) {
      return XirrResult(
        annualizedReturn: r * 100,
        iterations: iterations,
        converged: false,
      );
    }

    double bisLo = lo;
    double bisHi = hi;
    double bisMid = bisLo;

    for (int i = 0; i < _maxIterations; i++) {
      iterations++;
      bisMid = (bisLo + bisHi) / 2.0;
      final fMid = _npv(bisMid, c, t);

      if (fMid.abs() < _tolerance || (bisHi - bisLo) / 2.0 < _tolerance) {
        return XirrResult(
          annualizedReturn: bisMid * 100,
          iterations: iterations,
          converged: true,
        );
      }

      if (_npv(bisLo, c, t) * fMid < 0) {
        bisHi = bisMid;
      } else {
        bisLo = bisMid;
      }
    }

    // Exhausted both methods — return best bisection estimate.
    return XirrResult(
      annualizedReturn: bisMid * 100,
      iterations: iterations,
      converged: false,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Net Present Value function:  Σ Cᵢ / (1 + r)^tᵢ
  double _npv(double r, List<double> c, List<double> t) {
    double sum = 0.0;
    for (int i = 0; i < c.length; i++) {
      sum += c[i] / pow(1.0 + r, t[i]);
    }
    return sum;
  }

  /// Derivative of NPV with respect to r:  −Σ tᵢ × Cᵢ / (1 + r)^(tᵢ + 1)
  double _dnpv(double r, List<double> c, List<double> t) {
    double sum = 0.0;
    for (int i = 0; i < c.length; i++) {
      sum -= t[i] * c[i] / pow(1.0 + r, t[i] + 1.0);
    }
    return sum;
  }

  /// Validates the cash flow list before computation.
  void _validate(List<XirrCashFlow> cashFlows) {
    if (cashFlows.length < 2) {
      throw ArgumentError.value(
        cashFlows.length,
        'cashFlows',
        'Must contain at least 2 cash flows.',
      );
    }

    final hasNegative = cashFlows.any((cf) => cf.amount < 0);
    final hasPositive = cashFlows.any((cf) => cf.amount > 0);

    if (!hasNegative) {
      throw ArgumentError(
        'cashFlows must contain at least one negative amount (outflow / investment).',
      );
    }
    if (!hasPositive) {
      throw ArgumentError(
        'cashFlows must contain at least one positive amount (inflow / redemption).',
      );
    }

    final firstDate = cashFlows.first.date;
    final allSameDate = cashFlows.every((cf) => cf.date == firstDate);
    if (allSameDate) {
      throw ArgumentError(
        'cashFlows must span more than one date.',
      );
    }
  }
}
