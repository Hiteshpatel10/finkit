import 'package:finkit/src/compound/models/compound_frequency.dart';
import 'package:finkit/src/compound/models/compound_input.dart';
import 'package:finkit/src/compound/models/compound_result.dart';

/// Calculates the maturity amount given all inputs.
abstract interface class CompoundMaturitySolver {
  CompoundResult calculate(CompoundInput input);
}

/// Calculates the monthly contribution needed to reach a target corpus.
abstract interface class CompoundContributionSolver {
  double calculateRequiredContribution({
    required double targetAmount,
    required double principal,
    required double annualRate,
    required int tenureMonths,
    ContributionFrequency contributionFrequency,
    CompoundFrequency compoundFrequency,
    double annualContributionGrowthRate,
  });
}

/// Calculates the required annual rate to reach a target corpus.
abstract interface class CompoundRateSolver {
  double calculateRequiredRate({
    required double targetAmount,
    required double principal,
    required double contribution,
    required int tenureMonths,
    ContributionFrequency contributionFrequency,
    CompoundFrequency compoundFrequency,
    double annualContributionGrowthRate,
  });
}

/// Calculates the tenure (months) needed to reach a target corpus.
abstract interface class CompoundTenureSolver {
  int calculateRequiredTenure({
    required double targetAmount,
    required double principal,
    required double annualRate,
    required double contribution,
    ContributionFrequency contributionFrequency,
    CompoundFrequency compoundFrequency,
    double annualContributionGrowthRate,
  });
}
