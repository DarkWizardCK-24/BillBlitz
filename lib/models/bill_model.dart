import 'package:billing_system/models/billing_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  final String customerName;
  final String customerPhone;
  final List<BillingItem> items;
  final double subtotal;
  final double discount;
  final double taxableAmount;
  final double tax;
  final double total;
  final DateTime date;

  Bill({
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
    required this.total,
    required this.date,
  });

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
      'date': Timestamp.fromDate(date),
    };
  }

  // Create Bill from Firestore Map
  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      customerName: map['customerName'] ?? 'Walk-in Customer',
      customerPhone: map['customerPhone'] ?? 'N/A',
      items: (map['items'] as List<dynamic>)
          .map((item) => BillingItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      taxableAmount: (map['taxableAmount'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}