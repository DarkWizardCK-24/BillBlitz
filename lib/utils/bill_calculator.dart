import 'package:billing_system/models/billing_item_model.dart';

/// The computed money fields of a bill.
class BillTotals {
  final double subtotal;
  final double discount;
  final double taxableAmount;
  final double tax;
  final double total;

  const BillTotals({
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
    required this.total,
  });

  static const BillTotals zero = BillTotals(
    subtotal: 0,
    discount: 0,
    taxableAmount: 0,
    tax: 0,
    total: 0,
  );
}

/// Single source of truth for bill maths (screen, save and PDF all use it).
///
/// Both rates are percentages (`10` means 10 %) and are clamped to 0-100.
/// Every amount is rounded to 2 decimals so that what is shown on screen is
/// exactly what is saved and printed.
class BillCalculator {
  BillCalculator._();

  static BillTotals compute(
    List<BillingItem> items, {
    required double taxPercent,
    required double discountPercent,
  }) {
    final tax = taxPercent.clamp(0, 100).toDouble();
    final disc = discountPercent.clamp(0, 100).toDouble();

    final subtotal = _round(items.fold<double>(0, (sum, i) => sum + i.total));
    final discount = _round(subtotal * disc / 100);
    final taxable = _round(subtotal - discount);
    final taxAmount = _round(taxable * tax / 100);
    final total = _round(taxable + taxAmount);

    return BillTotals(
      subtotal: subtotal,
      discount: discount,
      taxableAmount: taxable,
      tax: taxAmount,
      total: total,
    );
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}
