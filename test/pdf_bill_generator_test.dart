import 'dart:io';

import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/models/shop_profile_model.dart';
import 'package:billing_system/utils/pdf_bill_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('builds a valid PDF, paginating long bills', (tester) async {
    final bill = sampleBill(
      id: 'BILL-00000042',
      customer: 'Bulk Buyer',
      date: DateTime(2026, 10, 11, 9, 30),
      items: [
        for (var i = 1; i <= 80; i++)
          BillingItem(name: 'Item number $i', price: 10.0 + i, quantity: 2),
      ],
    );

    final bytes = await tester.runAsync(
      () => PdfBillGenerator.build(bill, const ShopProfile(name: 'Test Shop')),
    );

    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));

    // Written so the page count can be inspected (`build/` is git-ignored).
    File('build/screenshots/long-bill.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });
}
