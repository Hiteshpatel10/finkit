import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('GstCalculator', () {
    late GstSolver calculator;

    setUpAll(() {
      final registry = GstCalculatorFactory().create(GstType.standard);
      calculator = registry.require<GstSolver>();
    });

    group('Add GST (Exclusive)', () {
      test('calculates 18% GST on 1000 correctly', () {
        final result = calculator.calculate(
          amount: 1000,
          rate: 18,
          type: GstCalculationType.addGst,
        );

        expect(result.baseAmount, equals(1000));
        expect(result.gstAmount, equals(180));
        expect(result.totalAmount, equals(1180));
        expect(result.cgst, equals(90));
        expect(result.sgst, equals(90));
        expect(result.igst, equals(180));
        expect(result.rate, equals(18));
      });

      test('calculates 5% GST on 500 correctly', () {
        final result = calculator.calculate(
          amount: 500,
          rate: 5,
          type: GstCalculationType.addGst,
        );

        expect(result.baseAmount, equals(500));
        expect(result.gstAmount, equals(25));
        expect(result.totalAmount, equals(525));
      });

      test('0% GST returns same amount', () {
        final result = calculator.calculate(
          amount: 1000,
          rate: 0,
          type: GstCalculationType.addGst,
        );

        expect(result.gstAmount, equals(0));
        expect(result.totalAmount, equals(1000));
      });
    });

    group('Remove GST (Inclusive)', () {
      test('calculates 18% GST from 1180 correctly', () {
        final result = calculator.calculate(
          amount: 1180,
          rate: 18,
          type: GstCalculationType.removeGst,
        );

        expect(result.baseAmount, closeTo(1000, 0.001));
        expect(result.gstAmount, closeTo(180, 0.001));
        expect(result.totalAmount, equals(1180));
        expect(result.cgst, closeTo(90, 0.001));
        expect(result.sgst, closeTo(90, 0.001));
      });

      test('calculates 12% GST from 1120 correctly', () {
        final result = calculator.calculate(
          amount: 1120,
          rate: 12,
          type: GstCalculationType.removeGst,
        );

        expect(result.baseAmount, closeTo(1000, 0.001));
        expect(result.gstAmount, closeTo(120, 0.001));
      });
    });

    group('Edge Cases', () {
      test('throws ArgumentError for negative amount', () {
        expect(
          () => calculator.calculate(amount: -1, rate: 18, type: GstCalculationType.addGst),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for negative rate', () {
        expect(
          () => calculator.calculate(amount: 1000, rate: -1, type: GstCalculationType.addGst),
          throwsArgumentError,
        );
      });

      test('handles 0 amount correctly', () {
        final result = calculator.calculate(
          amount: 0,
          rate: 18,
          type: GstCalculationType.addGst,
        );
        expect(result.totalAmount, equals(0));
        expect(result.gstAmount, equals(0));
      });
    });
  });
}
