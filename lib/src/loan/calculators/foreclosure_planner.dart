import 'package:finkit/src/loan/calculators/prepayment_calculator.dart';
import 'package:finkit/src/loan/models/foreclosure_planner_models.dart';
import 'package:finkit/src/loan/models/loan.dart';
import 'package:finkit/src/loan/models/prepayment_config.dart';
import 'package:finkit/src/loan/models/prepayment_result.dart';

/// Analyzes and compares various foreclosure and prepayment scenarios.
final class ForeclosurePlanner {
  final PrepaymentCalculator _calculator;

  ForeclosurePlanner({PrepaymentCalculator? calculator})
      : _calculator = calculator ?? PrepaymentCalculator();

  /// Generates a comparison report for a given loan and prepayment amount.
  ForeclosurePlan generatePlan({
    required Loan loan,
    required double prepaymentAmount,
    ForeclosureConfig? sampleForeclosure,
  }) {
    final stages = [
      (0.25, "Early"),
      (0.50, "Mid"),
      (0.75, "Late"),
    ];

    final comparisons = <ForeclosureStrategyComparison>[];

    for (final (percentage, label) in stages) {
      final month = (loan.tenureMonths * percentage).round();
      if (month <= 0) continue;

      final strategyResults = <PrepaymentStrategy, PrepaymentResult>{};

      // Scenario A: Tenure Reduction
      strategyResults[PrepaymentStrategy.tenureReduction] = _calculator.calculate(
        loan: loan,
        prepayments: [
          PrepaymentConfig(
            amount: prepaymentAmount,
            month: month,
            strategy: PrepaymentStrategy.tenureReduction,
          ),
        ],
      );

      // Scenario B: EMI Reduction
      strategyResults[PrepaymentStrategy.emiReduction] = _calculator.calculate(
        loan: loan,
        prepayments: [
          PrepaymentConfig(
            amount: prepaymentAmount,
            month: month,
            strategy: PrepaymentStrategy.emiReduction,
          ),
        ],
      );

      comparisons.add(
        ForeclosureStrategyComparison(
          strategyResults: strategyResults,
          atMonth: month,
          timingLabel: label,
        ),
      );
    }

    // Find the best scenario
    PrepaymentStrategy bestStrategy = PrepaymentStrategy.tenureReduction;
    int bestMonth = comparisons.first.atMonth;
    double maxSavings = -double.infinity;

    for (final comp in comparisons) {
      for (final strategy in PrepaymentStrategy.values) {
        final res = comp.getResult(strategy);
        if (res != null && res.netSavings > maxSavings) {
          maxSavings = res.netSavings;
          bestStrategy = strategy;
          bestMonth = comp.atMonth;
        }
      }
    }

    return ForeclosurePlan(
      stageComparisons: comparisons,
      recommendedScenario: (bestStrategy, bestMonth),
    );
  }
}
