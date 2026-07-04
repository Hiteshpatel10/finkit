import 'package:finkit/src/compound/calculators/compound_calculator.dart';
import 'package:finkit/src/nps/calculators/nps_calculator.dart';
import 'package:finkit/src/nps/calculators/nps_interfaces.dart';

/// Factory for creating NPS calculator instances.
class NpsCalculatorFactory {
  /// Creates a standard [NpsMaturitySolver].
  static NpsMaturitySolver createMaturitySolver() {
    return NpsCalculator(
      CompoundCalculator(),
    );
  }
}
