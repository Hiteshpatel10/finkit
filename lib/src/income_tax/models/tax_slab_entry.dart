/// A single row in the income tax slab computation breakdown.
///
/// [IncomeTaxResult.slabBreakdown] contains one entry per slab that the
/// taxpayer's income falls into, including zero-tax slabs (for transparency).
final class TaxSlabEntry {
  /// Lower boundary of this slab (inclusive), in ₹.
  final double slabFrom;

  /// Upper boundary of this slab (inclusive), in ₹.
  /// `double.infinity` for the top (unlimited) slab.
  final double slabTo;

  /// Tax rate for this slab, expressed as a **percentage**.
  /// e.g. `5.0` means 5%.
  final double ratePercent;

  /// The portion of taxable income that falls within this slab, in ₹.
  final double taxableInThisSlab;

  /// Tax charged on [taxableInThisSlab] at [ratePercent], in ₹.
  final double taxInThisSlab;

  const TaxSlabEntry({
    required this.slabFrom,
    required this.slabTo,
    required this.ratePercent,
    required this.taxableInThisSlab,
    required this.taxInThisSlab,
  });

  @override
  String toString() =>
      'TaxSlabEntry(${ratePercent.toStringAsFixed(0)}%: ₹$taxableInThisSlab → ₹$taxInThisSlab)';
}
