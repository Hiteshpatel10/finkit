import 'package:finkit/src/compound/models/compound_frequency.dart';
import 'package:finkit/src/compound/models/compound_input.dart';
import 'package:finkit/src/compound/models/compound_result.dart';
import 'package:finkit/src/compound/models/contribution_config.dart';
import 'package:finkit/src/compound/models/withdrawal_config.dart';

/// Calculates the maturity value for a given [CompoundInput].
abstract interface class CompoundMaturitySolver {
  CompoundResult calculate(CompoundInput input);
}

/// Solves for the periodic contribution amount needed to hit a target maturity.
///
/// Accepts a [contributionTemplate] — all fields (frequency, timing, stepUp)
/// are preserved; only [ContributionConfig.amount] is varied by the solver.
abstract interface class CompoundContributionSolver {
  double calculateRequiredContribution({
    required double targetAmount,
    required double principal,
    required double annualRate,
    required int tenureMonths,
    required ContributionConfig contributionTemplate,
    CompoundFrequency compoundFrequency,
    WithdrawalConfig? withdrawal,
  });
}

/// Solves for the annual rate needed to hit a target maturity.
abstract interface class CompoundRateSolver {
  double calculateRequiredRate({
    required double targetAmount,
    required double principal,
    required int tenureMonths,
    CompoundFrequency compoundFrequency,
    ContributionConfig? contribution,
    WithdrawalConfig? withdrawal,
  });
}

/// Solves for the tenure (in months) needed to hit a target maturity.
abstract interface class CompoundTenureSolver {
  int calculateRequiredTenure({
    required double targetAmount,
    required double principal,
    required double annualRate,
    CompoundFrequency compoundFrequency,
    ContributionConfig? contribution,
    WithdrawalConfig? withdrawal,
  });
}
