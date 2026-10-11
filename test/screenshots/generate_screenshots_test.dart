// Generates the README screenshots from the real widgets using sample data
// (no Firebase needed). Skipped during a normal `flutter test`; run with:
//
//   flutter test test/screenshots --dart-define=SCREENSHOTS=true
//
// PNGs are written to docs/screenshots/. The PDF invoice is written to
// build/screenshots/invoice.pdf and rasterised by tool/pdf_to_png.py.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:billing_system/main.dart';
import 'package:billing_system/models/shop_profile_model.dart';
import 'package:billing_system/services/shop_profile_store.dart';
import 'package:billing_system/utils/pdf_bill_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

const bool _enabled = bool.fromEnvironment('SCREENSHOTS');
final _boundaryKey = GlobalKey();

Future<void> _pump(
  WidgetTester tester,
  FakeBillRepository repo, {
  required Size size,
  double dpr = 2,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: MyApp(repository: repo, shopStore: ShopProfileStore()),
    ),
  );
  // Images decode asynchronously, so load the logo before the first frame
  // is captured (otherwise it would be drawn as an empty box).
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/logo.png'),
      tester.element(find.byType(MaterialApp)),
    );
  });
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name, {double dpr = 2}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
      .clearSnackBars();
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${file.path} (${image.width}x${image.height})');
  });
}

Future<void> _addItem(
  WidgetTester tester,
  String name,
  String price,
  String qty,
) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Item name'), name);
  await tester.enterText(find.widgetWithText(TextFormField, 'Price'), price);
  await tester.enterText(find.widgetWithText(TextFormField, 'Qty'), qty);
  await tester.tap(find.widgetWithText(FilledButton, 'Add'));
  await tester.pumpAndSettle();
}

Future<void> _fillBill(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Customer name'),
    'Ananya Sharma',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Phone (optional)'),
    '+91 98765 43210',
  );
  await _addItem(tester, 'Basmati Rice 5kg', '640', '2');
  await _addItem(tester, 'Sunflower Oil 1L', '185.50', '3');
  await _addItem(tester, 'Toor Dal 1kg', '162', '1');
  // The summary card is below the fold on phones, so scroll to it first.
  final discount = find.widgetWithText(TextField, 'Discount');
  await tester.scrollUntilVisible(
    discount,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(discount, '5');
  await tester.pumpAndSettle();
  await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

/// `flutter test` renders every glyph as a box unless fonts are loaded, so load
/// the bundled Inter weights and the Material icon font from the SDK.
Future<void> _loadFonts() async {
  ByteData bytes(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());

  final inter = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(Future.value(bytes('assets/fonts/Inter-$weight.ttf')));
  }
  await inter.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        bytes(
          '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ),
      ),
    );
  await icons.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'shop.name': 'Sunrise General Store',
      'shop.address': '12 MG Road, Pune, Maharashtra 411001',
      'shop.phone': '+91 20 5555 0123',
    });
  });

  testWidgets('phone screenshots', skip: !_enabled, (tester) async {
    final repo = FakeBillRepository(sampleBills());
    await _pump(tester, repo, size: const Size(430, 932));

    await _shot(tester, '01-new-bill');

    await _fillBill(tester);
    await _shot(tester, '02-bill-items');

    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await _shot(tester, '03-bill-summary');

    await tester.tap(find.byTooltip('Saved bills'));
    await tester.pumpAndSettle();
    await _shot(tester, '04-saved-bills');

    await tester.tap(find.text('Ananya Sharma').first);
    await tester.pumpAndSettle();
    await _shot(tester, '05-bill-details');

    // Close the sheet, go back, open settings.
    await tester.tapAt(const Offset(215, 30));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Shop settings'));
    await tester.pumpAndSettle();
    await _shot(tester, '06-shop-settings');
  });

  testWidgets('desktop screenshot', skip: !_enabled, (tester) async {
    await _pump(
      tester,
      FakeBillRepository(sampleBills()),
      size: const Size(1100, 1180),
      dpr: 1.5,
    );
    await _fillBill(tester);
    await _shot(tester, '07-desktop', dpr: 1.5);
  });

  testWidgets('desktop saved bills', skip: !_enabled, (tester) async {
    await _pump(
      tester,
      FakeBillRepository(sampleBills()),
      size: const Size(1100, 800),
      dpr: 1.5,
    );
    await tester.tap(find.byTooltip('Saved bills'));
    await tester.pumpAndSettle();
    await _shot(tester, '09-desktop-saved-bills', dpr: 1.5);
  });

  testWidgets('pdf invoice', skip: !_enabled, (tester) async {
    // Loading the bundled fonts needs the real (non-fake) async zone.
    final bytes = await tester.runAsync(
      () => PdfBillGenerator.build(
        sampleBills().first,
        const ShopProfile(
          name: 'Sunrise General Store',
          address: '12 MG Road, Pune, Maharashtra 411001',
          phone: '+91 20 5555 0123',
        ),
      ),
    );
    File('build/screenshots/invoice.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });
}
