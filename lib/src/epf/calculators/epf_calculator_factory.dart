import 'package:finkit/src/compound/calculators/compound_calculator.dart';
import 'package:finkit/src/epf/calculators/epf_calculator.dart';
import 'package:finkit/src/epf/calculators/epf_interfaces.dart';

/// Factory for creating EPF calculator instances.
class EpfCalculatorFactory {
  /// Creates a standard [EpfMaturitySolver].
  static EpfMaturitySolver createMaturitySolver() {
    return EpfCalculator(
      CompoundCalculator(),
    );
  }
}
