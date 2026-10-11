import 'package:billing_system/main.dart';
import 'package:billing_system/services/shop_profile_store.dart';
import 'package:billing_system/screens/view_bills_screen.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

Future<void> pumpApp(WidgetTester tester, FakeBillRepository repo) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MyApp(repository: repo, shopStore: ShopProfileStore()),
  );
  await tester.pumpAndSettle();
}

Future<void> addItem(
  WidgetTester tester, {
  required String name,
  required String price,
  String qty = '1',
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Item name'), name);
  await tester.enterText(find.widgetWithText(TextFormField, 'Price'), price);
  await tester.enterText(find.widgetWithText(TextFormField, 'Qty'), qty);
  await tester.tap(find.widgetWithText(FilledButton, 'Add'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('add form validates before adding an item', (tester) async {
    await pumpApp(tester, FakeBillRepository());

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an item name'), findsOneWidget);
    expect(find.text('Enter a price'), findsOneWidget);
    expect(find.text('No items yet'), findsOneWidget);
  });

  testWidgets('adds items, updates totals and quantity', (tester) async {
    await pumpApp(tester, FakeBillRepository());

    await addItem(tester, name: 'Rice', price: '100', qty: '2');
    await addItem(tester, name: 'Oil', price: '50.50');

    expect(find.text('2 items'), findsNWidgets(2)); // card chip + action bar
    // 250.50 subtotal + 10 % default tax = 275.55 (also shown in the action bar)
    expect(find.text('₹275.55'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Increase quantity').first);
    await tester.pumpAndSettle();
    // 350.50 + 10 % = 385.55
    expect(find.text('₹385.55'), findsNWidgets(2));
  });

  testWidgets('removing an item can be undone', (tester) async {
    await pumpApp(tester, FakeBillRepository());
    await addItem(tester, name: 'Rice', price: '100');

    await tester.tap(find.byTooltip('Remove item'));
    await tester.pumpAndSettle();
    expect(find.text('No items yet'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(find.text('Rice'), findsOneWidget);
  });

  testWidgets('saving stores the bill with its rates and clears the form', (
    tester,
  ) async {
    final repo = FakeBillRepository();
    await pumpApp(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Customer name'),
      'Asha',
    );
    await addItem(tester, name: 'Rice', price: '200');
    await tester.enterText(find.widgetWithText(TextField, 'Discount'), '10');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repo.bills, hasLength(1));
    final bill = repo.bills.single;
    expect(bill.id, 'BILL-00000001');
    expect(bill.customerName, 'Asha');
    expect(bill.discountPercent, 10);
    expect(bill.taxPercent, 10);
    expect(bill.total, 198.0); // 200 - 20 + 10 % of 180
    expect(find.text('No items yet'), findsOneWidget);
  });

  testWidgets('shows the error when saving fails and keeps the bill', (
    tester,
  ) async {
    final repo = FakeBillRepository()
      ..failWith = Exception('Permission denied');
    await pumpApp(tester, repo);
    await addItem(tester, name: 'Rice', price: '200');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(repo.bills, isEmpty);
  });

  testWidgets('saved bills can be searched', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ViewBillsScreen(
          repository: FakeBillRepository(sampleBills()),
          shopStore: ShopProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ananya Sharma'), findsOneWidget);
    expect(find.text('Rahul Verma'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'rahul');
    await tester.pumpAndSettle();
    expect(find.text('Ananya Sharma'), findsNothing);
    expect(find.text('Rahul Verma'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching bills'), findsOneWidget);
  });
}
