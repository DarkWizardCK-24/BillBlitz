import 'dart:async';

import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/models/payment_method.dart';
import 'package:billing_system/services/bill_repository.dart';
import 'package:billing_system/utils/bill_calculator.dart';

/// In-memory [BillRepository] so screens can be tested without Firebase.
class FakeBillRepository implements BillRepository {
  FakeBillRepository([List<Bill> seed = const []])
    : bills = List.of(seed),
      _counter = seed.length;

  final List<Bill> bills;
  final _controller = StreamController<List<Bill>>.broadcast();
  int _counter;

  /// When set, [saveBill] throws it (to test the error path).
  Object? failWith;

  @override
  Future<Bill> saveBill(Bill bill) async {
    if (failWith != null) throw failWith!;
    _counter++;
    final saved = bill.copyWith(
      id: 'BILL-${_counter.toString().padLeft(8, '0')}',
    );
    bills.insert(0, saved);
    _controller.add(List.unmodifiable(bills));
    return saved;
  }

  @override
  Stream<List<Bill>> watchBills() async* {
    yield List.unmodifiable(bills);
    yield* _controller.stream;
  }

  @override
  Future<void> deleteBill(String id) async {
    bills.removeWhere((b) => b.id == id);
    _controller.add(List.unmodifiable(bills));
  }
}

/// Builds a fully-populated bill using the real calculator.
Bill sampleBill({
  required String id,
  required String customer,
  String phone = '',
  required DateTime date,
  required List<BillingItem> items,
  double taxPercent = 10,
  double discountPercent = 0,
  PaymentMethod paymentMethod = PaymentMethod.cash,
}) {
  final t = BillCalculator.compute(
    items,
    taxPercent: taxPercent,
    discountPercent: discountPercent,
  );
  return Bill(
    id: id,
    customerName: customer,
    customerPhone: phone,
    items: items,
    subtotal: t.subtotal,
    discount: t.discount,
    taxableAmount: t.taxableAmount,
    tax: t.tax,
    total: t.total,
    taxPercent: taxPercent,
    discountPercent: discountPercent,
    paymentMethod: paymentMethod,
    date: date,
  );
}

/// A few realistic bills used by tests and the README screenshots.
List<Bill> sampleBills() => [
  sampleBill(
    id: 'BILL-00000003',
    customer: 'Ananya Sharma',
    phone: '+91 98765 43210',
    date: DateTime(2026, 10, 11, 16, 20),
    paymentMethod: PaymentMethod.upi,
    discountPercent: 5,
    items: const [
      BillingItem(name: 'Basmati Rice 5kg', price: 640, quantity: 2),
      BillingItem(name: 'Sunflower Oil 1L', price: 185.5, quantity: 3),
      BillingItem(name: 'Toor Dal 1kg', price: 162, quantity: 1),
    ],
  ),
  sampleBill(
    id: 'BILL-00000002',
    customer: 'Rahul Verma',
    phone: '98200 11223',
    date: DateTime(2026, 10, 11, 12, 5),
    paymentMethod: PaymentMethod.card,
    items: const [
      BillingItem(name: 'Notebook A4 (Pack of 5)', price: 250, quantity: 2),
      BillingItem(name: 'Gel Pen Blue', price: 20, quantity: 10),
    ],
  ),
  sampleBill(
    id: 'BILL-00000001',
    customer: 'Walk-in Customer',
    date: DateTime(2026, 10, 10, 18, 45),
    items: const [
      BillingItem(name: 'Cold Drink 600ml', price: 40, quantity: 3),
    ],
  ),
];
