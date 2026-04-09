enum GstCalculationType {
  /// GST is added to the base amount (Exclusive).
  ///
  /// Formula: Total = Base + (Base * Rate / 100)
  addGst,

  /// GST is already included in the total amount (Inclusive).
  ///
  /// Formula: Base = Total / (1 + Rate / 100)
  removeGst;

  bool get isAdd => this == GstCalculationType.addGst;
  bool get isRemove => this == GstCalculationType.removeGst;
}
