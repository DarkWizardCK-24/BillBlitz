import 'package:flutter/material.dart';

enum PaymentMethod {
  cash('Cash', Icons.payments_outlined),
  upi('UPI', Icons.qr_code_2),
  card('Card', Icons.credit_card);

  final String label;
  final IconData icon;

  const PaymentMethod(this.label, this.icon);

  /// Falls back to cash for bills saved before payment methods existed.
  static PaymentMethod fromName(String? name) => PaymentMethod.values
      .firstWhere((m) => m.name == name, orElse: () => PaymentMethod.cash);
}
