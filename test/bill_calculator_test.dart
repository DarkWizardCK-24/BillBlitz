import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/models/payment_method.dart';
import 'package:billing_system/utils/bill_calculator.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = [
    BillingItem(name: 'A', price: 100, quantity: 2),
    BillingItem(name: 'B', price: 49.99, quantity: 3),
  ];

  group('BillCalculator', () {
    test('computes discount before tax', () {
      final t = BillCalculator.compute(
        items,
        taxPercent: 10,
        discountPercent: 10,
      );
      expect(t.subtotal, 349.97);
      expect(t.discount, 35.0); // 34.997 -> 35.00
      expect(t.taxableAmount, 314.97);
      expect(t.tax, 31.5); // 31.497 -> 31.50
      expect(t.total, 346.47);
    });

    test('empty bill is all zeros', () {
      final t = BillCalculator.compute(
        const [],
        taxPercent: 18,
        discountPercent: 5,
      );
      expect(t.total, 0);
      expect(t.tax, 0);
    });

    test('rates are clamped to 0-100', () {
      final over = BillCalculator.compute(
        items,
        taxPercent: 0,
        discountPercent: 250,
      );
      expect(over.total, 0);

      final negative = BillCalculator.compute(
        items,
        taxPercent: -5,
        discountPercent: -5,
      );
      expect(negative.total, negative.subtotal);
    });
  });

  group('Bill.fromMap', () {
    final base = {
      'customerName': 'Asha',
      'items': [
        {'name': 'Pen', 'price': 10, 'quantity': 2},
      ],
      'subtotal': 200.0,
      'discount': 20.0,
      'taxableAmount': 180.0,
      'tax': 18.0,
      'total': 198.0,
      'date': Timestamp.fromDate(DateTime(2026, 1, 2, 3, 4)),
    };

    test('derives rates for bills saved by older versions', () {
      final bill = Bill.fromMap({
        ...base,
        'customerPhone': 'Walk-in Customer',
      }, id: 'BILL-00000009');

      expect(bill.id, 'BILL-00000009');
      expect(bill.taxPercent, closeTo(10, 1e-9));
      expect(bill.discountPercent, closeTo(10, 1e-9));
      expect(bill.customerPhone, isEmpty);
      expect(bill.paymentMethod, PaymentMethod.cash);
    });

    test('round-trips through toMap', () {
      final bill = Bill.fromMap({
        ...base,
        'customerPhone': '9876543210',
        'taxPercent': 10,
        'discountPercent': 10,
        'paymentMethod': 'upi',
      });
      final again = Bill.fromMap(bill.toMap());
      expect(again.paymentMethod, PaymentMethod.upi);
      expect(again.total, 198.0);
      expect(again.items.single.name, 'Pen');
    });
  });

  test('Fmt.money uses Indian digit grouping', () {
    expect(Fmt.money(1234567.5), '₹12,34,567.50');
    expect(Fmt.percent(10), '10');
    expect(Fmt.percent(7.5), '7.5');
  });
}
