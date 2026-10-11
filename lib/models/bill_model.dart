import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/models/payment_method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  /// Firestore document id (e.g. `BILL-00000007`). `null` until the bill is saved.
  final String? id;
  final String customerName;
  final String customerPhone;
  final List<BillingItem> items;
  final double subtotal;
  final double discount;
  final double taxableAmount;
  final double tax;
  final double total;

  /// The rates the bill was created with (percentages, e.g. `10` for 10 %).
  final double taxPercent;
  final double discountPercent;
  final PaymentMethod paymentMethod;
  final DateTime date;

  const Bill({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
    required this.total,
    required this.taxPercent,
    required this.discountPercent,
    this.paymentMethod = PaymentMethod.cash,
    required this.date,
  });

  Bill copyWith({String? id}) => Bill(
    id: id ?? this.id,
    customerName: customerName,
    customerPhone: customerPhone,
    items: items,
    subtotal: subtotal,
    discount: discount,
    taxableAmount: taxableAmount,
    tax: tax,
    total: total,
    taxPercent: taxPercent,
    discountPercent: discountPercent,
    paymentMethod: paymentMethod,
    date: date,
  );

  // Convert Bill to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'taxableAmount': taxableAmount,
      'tax': tax,
      'total': total,
      'taxPercent': taxPercent,
      'discountPercent': discountPercent,
      'paymentMethod': paymentMethod.name,
      'date': Timestamp.fromDate(date),
    };
  }

  // Create Bill from Firestore Map
  factory Bill.fromMap(Map<String, dynamic> map, {String? id}) {
    final subtotal = (map['subtotal'] as num).toDouble();
    final discount = (map['discount'] as num).toDouble();
    final taxable = (map['taxableAmount'] as num).toDouble();
    final tax = (map['tax'] as num).toDouble();

    // Bills saved before rates were stored: derive them from the amounts.
    final taxPercent =
        (map['taxPercent'] as num?)?.toDouble() ??
        (taxable != 0 ? tax / taxable * 100 : 0.0);
    final discountPercent =
        (map['discountPercent'] as num?)?.toDouble() ??
        (subtotal != 0 ? discount / subtotal * 100 : 0.0);

    // Older versions stored the customer name in the phone field for walk-ins.
    final rawPhone = (map['customerPhone'] as String?) ?? '';
    final phone = rawPhone == 'Walk-in Customer' || rawPhone == 'N/A'
        ? ''
        : rawPhone;

    return Bill(
      id: id,
      customerName: map['customerName'] ?? 'Walk-in Customer',
      customerPhone: phone,
      items: ((map['items'] as List<dynamic>?) ?? const [])
          .map((item) => BillingItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: subtotal,
      discount: discount,
      taxableAmount: taxable,
      tax: tax,
      total: (map['total'] as num).toDouble(),
      taxPercent: taxPercent,
      discountPercent: discountPercent,
      paymentMethod: PaymentMethod.fromName(map['paymentMethod'] as String?),
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}
