import 'package:finkit/src/gst/models/gst_calculation_type.dart';

/// The final output of a GST calculation.
final class GstResult {
  /// The amount before GST is applied.
  final double baseAmount;

  /// The total amount of GST calculated.
  final double gstAmount;

  /// Central Goods and Services Tax (50% of [gstAmount]).
  final double cgst;

  /// State Goods and Services Tax (50% of [gstAmount]).
  final double sgst;

  /// Integrated Goods and Services Tax (100% of [gstAmount]).
  final double igst;

  /// The final amount after GST (Base + GST).
  final double totalAmount;

  /// The tax rate used for the calculation (percentage).
  final double rate;

  /// Whether GST was added or removed.
  final GstCalculationType type;

  const GstResult({
    required this.baseAmount,
    required this.gstAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
    required this.rate,
    required this.type,
  });

  @override
  String toString() {
    return 'GstResult(baseAmount: $baseAmount, gstAmount: $gstAmount, totalAmount: $totalAmount)';
  }
}
