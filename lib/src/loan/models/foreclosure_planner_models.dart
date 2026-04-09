import 'package:finkit/src/loan/models/prepayment_config.dart';
import 'package:finkit/src/loan/models/prepayment_result.dart';

/// One-time analysis of a specific strategy at a specific timing.
final class ForeclosureStrategyComparison {
  final Map<PrepaymentStrategy, PrepaymentResult> strategyResults;
  final int atMonth;
  final String timingLabel; // "Early", "Mid", "Late"

  ForeclosureStrategyComparison({
    required this.strategyResults,
    required this.atMonth,
    required this.timingLabel,
  });

  PrepaymentResult? getResult(PrepaymentStrategy strategy) =>
      strategyResults[strategy];
}

/// The final report from the Foreclosure Planner.
final class ForeclosurePlan {
  /// Comparisons at various stages (e.g. 25%, 50%, 75%).
  final List<ForeclosureStrategyComparison> stageComparisons;

  /// The absolute best scenario (highest netSavings) found.
  final (PrepaymentStrategy, int) recommendedScenario;

  const ForeclosurePlan({
    required this.stageComparisons,
    required this.recommendedScenario,
  });
}
