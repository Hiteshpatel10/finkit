/// The output of an XIRR computation.
///
/// [annualizedReturn] is expressed as a **percentage** — e.g. `14.5` means 14.5% p.a.
/// A negative value indicates a loss (e.g. `-5.2` means −5.2% p.a.).
///
/// [converged] is `true` when the solver reached the tolerance target within
/// [maxIterations]. It is `false` for degenerate / ill-conditioned inputs where
/// neither Newton-Raphson nor bisection reached a solution — treat such results
/// with caution.
///
/// [iterations] reflects how many Newton-Raphson steps were taken; useful for
/// performance profiling and debugging convergence behaviour.
final class XirrResult {
  /// Annualized internal rate of return, expressed as a percentage.
  ///
  /// Example: `14.52` means 14.52% per annum.
  final double annualizedReturn;

  /// Number of Newton-Raphson iterations executed before convergence (or max hit).
  final int iterations;

  /// Whether the solver converged within the tolerance threshold.
  ///
  /// If `false`, [annualizedReturn] is the best estimate reached and may be inaccurate.
  final bool converged;

  const XirrResult({
    required this.annualizedReturn,
    required this.iterations,
    required this.converged,
  });

  @override
  String toString() =>
      'XirrResult(annualizedReturn: ${annualizedReturn.toStringAsFixed(4)}%, '
      'iterations: $iterations, converged: $converged)';
}
