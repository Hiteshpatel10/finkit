import 'package:finkit/src/nps/models/nps_input.dart';
import 'package:finkit/src/nps/models/nps_result.dart';

/// Calculates the maturity value and pension details for an NPS investment.
abstract interface class NpsMaturitySolver {
  /// Calculates NPS returns based on the provided [input].
  ///
  /// Throws an [ArgumentError] if the retirement age is less than or equal to current age,
  /// or if the annuity purchase percentage is less than 40%.
  NpsResult calculateMaturity(NpsInput input);
}
