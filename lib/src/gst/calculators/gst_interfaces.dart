import 'package:finkit/src/gst/models/gst_calculation_type.dart';
import 'package:finkit/src/gst/models/gst_result.dart';

/// Contract for calculating Goods and Services Tax (GST).
abstract interface class GstSolver {
  /// Calculates [GstResult] for a given [amount] and [rate].
  GstResult calculate({
    required double amount,
    required double rate,
    required GstCalculationType type,
  });
}
