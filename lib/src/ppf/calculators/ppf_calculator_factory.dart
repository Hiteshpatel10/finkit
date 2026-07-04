import 'package:finkit/src/compound/calculators/compound_calculator.dart';
import 'package:finkit/src/ppf/calculators/ppf_calculator.dart';
import 'package:finkit/src/ppf/calculators/ppf_interfaces.dart';

/// Factory for creating PPF calculator instances.
class PpfCalculatorFactory {
  /// Creates a standard [PpfMaturitySolver].
  static PpfMaturitySolver createMaturitySolver() {
    return PpfCalculator(
      CompoundCalculator(),
    );
  }
}
