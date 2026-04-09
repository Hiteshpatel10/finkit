import 'package:finkit/src/gst/models/gst_calculation_type.dart';
import 'package:finkit/src/gst/models/gst_result.dart';
import 'package:finkit/src/gst/calculators/gst_interfaces.dart';

/// Core engine for Goods and Services Tax (GST) calculations.
final class GstCalculator implements GstSolver {
  /// Calculates GST for a given amount and rate.
  ///
  /// [amount] is the base amount if [type] is [GstCalculationType.addGst],
  /// or the total amount if [type] is [GstCalculationType.removeGst].
  @override
  GstResult calculate({
    required double amount,
    required double rate,
    required GstCalculationType type,
  }) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be >= 0');
    }
    if (rate < 0) {
      throw ArgumentError.value(rate, 'rate', 'Must be >= 0');
    }

    if (type.isAdd) {
      return _addGst(amount, rate);
    } else {
      return _removeGst(amount, rate);
    }
  }

  GstResult _addGst(double baseAmount, double rate) {
    final gstAmount = (baseAmount * rate) / 100;
    final totalAmount = baseAmount + gstAmount;

    return GstResult(
      baseAmount: baseAmount,
      gstAmount: gstAmount,
      cgst: gstAmount / 2,
      sgst: gstAmount / 2,
      igst: gstAmount,
      totalAmount: totalAmount,
      rate: rate,
      type: GstCalculationType.addGst,
    );
  }

  GstResult _removeGst(double totalAmount, double rate) {
    // totalAmount = baseAmount * (1 + rate / 100)
    // baseAmount = totalAmount / (1 + rate / 100)
    final baseAmount = totalAmount / (1 + (rate / 100));
    final gstAmount = totalAmount - baseAmount;

    return GstResult(
      baseAmount: baseAmount,
      gstAmount: gstAmount,
      cgst: gstAmount / 2,
      sgst: gstAmount / 2,
      igst: gstAmount,
      totalAmount: totalAmount,
      rate: rate,
      type: GstCalculationType.removeGst,
    );
  }
}
