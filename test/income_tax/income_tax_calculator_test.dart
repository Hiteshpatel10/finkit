import 'package:test/test.dart';
import 'package:finkit/finkit.dart';

void main() {
  group('Income Tax Calculator (FY 2025-26)', () {
    late IncomeTaxSolver solver;

    setUpAll(() {
      final registry =
          IncomeTaxCalculatorFactory().create(IncomeTaxType.fy2025_26);
      solver = registry.require<IncomeTaxSolver>();
    });

    // ── New Regime ───────────────────────────────────────────────────────────

    group('New Regime', () {
      test('₹3L income → zero tax', () {
        final result = solver.calculate(
          grossIncome: 300000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );
        expect(result.totalTax, equals(0));
        expect(result.slabBreakdown.length, equals(1));
      });

      test('₹8L income (non-salaried) → basic slab tax + 87A rebate applies', () {
        // Income = 8,00,000
        // Slab 0-3L = 0
        // Slab 3L-7L (4L @ 5%) = 20,000
        // Slab 7L-10L (1L @ 10%) = 10,000
        // Base Tax = 30,000
        // 87A Rebate = 30,000 (since income ≤ 12L)
        // Total Tax = 0
        final result = solver.calculate(
          grossIncome: 800000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );

        expect(result.baseTax, equals(30000));
        expect(result.rebate87A, equals(30000));
        expect(result.taxAfterRebate, equals(0));
        expect(result.totalTax, equals(0));
      });

      test('₹12L income (non-salaried) → max 87A rebate applies', () {
        // Income = 12,00,000
        // Slab 0-3L = 0
        // Slab 3L-7L (4L @ 5%) = 20,000
        // Slab 7L-10L (3L @ 10%) = 30,000
        // Slab 10L-12L (2L @ 15%) = 30,000
        // Base Tax = 80,000
        // 87A Rebate = 80,000 (income exactly at 12L)
        // Total Tax = 0
        final result = solver.calculate(
          grossIncome: 1200000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );

        expect(result.baseTax, equals(80000));
        expect(result.rebate87A, equals(80000));
        expect(result.totalTax, equals(0));
      });

      test('₹12.1L income (salaried) → standard deduction brings it below 12L', () {
        // Gross = 12,10,000
        // Standard Deduction = 75,000
        // Taxable = 11,35,000 (≤ 12L, so 87A applies)
        final result = solver.calculate(
          grossIncome: 1210000,
          regime: TaxRegime.newRegime,
          isSalaried: true,
        );

        expect(result.taxableIncome, equals(1135000));
        expect(result.totalTax, equals(0));
      });

      test('₹13L income (non-salaried) → no 87A rebate, tax applies', () {
        // Income = 13,00,000
        // Base Tax: 0(3L) + 20k(4L) + 30k(3L) + 30k(2L) + 20k(1L@20%) = 1,00,000
        // Rebate = 0 (income > 12L)
        // Cess = 4,000
        // Total Tax = 1,04,000
        final result = solver.calculate(
          grossIncome: 1300000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );

        expect(result.baseTax, equals(100000));
        expect(result.rebate87A, equals(0)); // 13L is too far past 12L for marginal relief
        expect(result.cess, equals(4000));
        expect(result.totalTax, equals(104000));
      });

      test('₹12,05,000 income (non-salaried) → 87A marginal relief applies', () {
        // Income = 12,05,000 (exceeds threshold by 5,000)
        // Base Tax for 12L = 80,000
        // Tax on extra 5,000 (at 20% slab) = 1,000
        // Base Tax = 81,000
        // Without relief, tax increases from 0 to 81,000 for a 5,000 income jump.
        // With relief, max tax is capped at the excess income = 5,000.
        // Rebate adjusted = 81,000 - 5,000 = 76,000
        // Tax after rebate = 5,000
        // Cess (4%) = 200
        // Total Tax = 5,200
        final result = solver.calculate(
          grossIncome: 1205000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );

        expect(result.baseTax, equals(81000));
        expect(result.rebate87A, equals(76000));
        expect(result.taxAfterRebate, equals(5000));
        expect(result.totalTax, equals(5200));
      });

      test('ignores old regime deductions', () {
        final result1 = solver.calculate(
          grossIncome: 2000000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );
        final result2 = solver.calculate(
          grossIncome: 2000000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
          deductions: const Deductions(section80C: 150000),
        );

        expect(result1.totalTax, equals(result2.totalTax));
      });
    });

    // ── Old Regime ───────────────────────────────────────────────────────────

    group('Old Regime', () {
      test('₹2.5L income → zero tax', () {
        final result = solver.calculate(
          grossIncome: 250000,
          regime: TaxRegime.oldRegime,
          isSalaried: false,
        );
        expect(result.totalTax, equals(0));
      });

      test('₹5L income (non-salaried) → 87A rebate applies', () {
        // Income = 5,00,000
        // Slab 0-2.5L = 0
        // Slab 2.5L-5L (2.5L @ 5%) = 12,500
        // Base Tax = 12,500
        // 87A Rebate = 12,500 (since income ≤ 5L)
        // Total Tax = 0
        final result = solver.calculate(
          grossIncome: 500000,
          regime: TaxRegime.oldRegime,
          isSalaried: false,
        );

        expect(result.baseTax, equals(12500));
        expect(result.rebate87A, equals(12500));
        expect(result.totalTax, equals(0));
      });

      test('₹6L income with ₹1L 80C → taxable ₹5L → 87A applies', () {
        final result = solver.calculate(
          grossIncome: 600000,
          regime: TaxRegime.oldRegime,
          isSalaried: false,
          deductions: const Deductions(section80C: 100000),
        );

        expect(result.taxableIncome, equals(500000));
        expect(result.totalTax, equals(0));
      });

      test('deductions applied correctly (80C capped at 1.5L)', () {
        final result = solver.calculate(
          grossIncome: 1500000,
          regime: TaxRegime.oldRegime,
          isSalaried: true, // 50k standard deduction
          deductions: const Deductions(
            section80C: 200000, // Capped at 150,000
            section80D: 25000,
            hraExemption: 75000,
          ),
        );

        // Deductions = 50k (std) + 150k (80C) + 25k (80D) + 75k (HRA) = 3,00,000
        // Taxable = 15,00,000 - 3,00,000 = 12,00,000
        expect(result.totalDeductions, equals(300000));
        expect(result.taxableIncome, equals(1200000));
      });
    });

    // ── Surcharge ────────────────────────────────────────────────────────────

    group('Surcharge', () {
      test('₹60L income (New) → 10% surcharge applies', () {
        final result = solver.calculate(
          grossIncome: 6000000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );

        // Surcharge threshold 1: > ₹50L -> 10%
        // Base Tax (approx 16L+)
        // Surcharge = Base Tax * 0.10
        expect(result.surcharge, equals(result.taxAfterRebate * 0.10));
      });

      test('₹1.5Cr income (New) → 15% surcharge applies', () {
        final result = solver.calculate(
          grossIncome: 15000000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );
        expect(result.surcharge, equals(result.taxAfterRebate * 0.15));
      });

      test('₹6Cr income (New) → Surcharge capped at 25%', () {
        final result = solver.calculate(
          grossIncome: 60000000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );
        // Under New Regime, surcharge never exceeds 25% even above 5Cr.
        expect(result.surcharge, equals(result.taxAfterRebate * 0.25));
      });

      test('₹6Cr income (Old) → Surcharge hits 37%', () {
        final result = solver.calculate(
          grossIncome: 60000000,
          regime: TaxRegime.oldRegime,
          isSalaried: false,
        );
        // Under Old Regime, surcharge hits 37% above 5Cr.
        expect(result.surcharge, equals(result.taxAfterRebate * 0.37));
      });

      test('Surcharge marginal relief at ₹51L boundary', () {
        // At exactly ₹50L, total tax before cess = ₹11,90,000 (New Regime)
        // At ₹51L, without relief: tax = ₹12,20,000, surcharge (10%) = ₹1,22,000. Total = ₹13,42,000.
        // Tax jumped by ₹1,52,000 for a ₹1,00,000 income increase.
        // Marginal relief caps total tax at: Tax at 50L + Extra Income = ₹11,90,000 + ₹1,00,000 = ₹12,90,000.
        // So surcharge = ₹12,90,000 - ₹12,20,000 = ₹70,000.
        final result = solver.calculate(
          grossIncome: 5100000,
          regime: TaxRegime.newRegime,
          isSalaried: false,
        );
        expect(result.baseTax, equals(1220000));
        expect(result.surcharge, equals(70000)); // Cap applied
        expect(result.taxAfterRebate + result.surcharge, equals(1290000));
      });
    });

    // ── Factory and Edge Cases ───────────────────────────────────────────────

    group('Edge cases and Factory', () {
      test('throws ArgumentError for negative grossIncome', () {
        expect(
          () => solver.calculate(
            grossIncome: -50000,
            regime: TaxRegime.newRegime,
          ),
          throwsArgumentError,
        );
      });

      test('IncomeTaxCalculatorFactory create() resolves solver', () {
        final registry =
            IncomeTaxCalculatorFactory().create(IncomeTaxType.fy2025_26);
        expect(registry.supports<IncomeTaxSolver>(), isTrue);
        expect(registry.require<IncomeTaxSolver>(), isA<IncomeTaxSolver>());
      });
    });
  });
}
