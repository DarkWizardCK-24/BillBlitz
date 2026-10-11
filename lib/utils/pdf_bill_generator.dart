import 'dart:typed_data';

import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/models/shop_profile_model.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds, prints and shares the PDF for a saved [Bill].
///
/// Everything printed comes from the saved bill (id, date, rates and amounts),
/// so reprinting an old bill always produces the original document.
class PdfBillGenerator {
  PdfBillGenerator._();

  static const _brand = PdfColor.fromInt(0xFF5B3FD0);
  static const _brandSoft = PdfColor.fromInt(0xFFEDE9FB);
  static const _muted = PdfColor.fromInt(0xFF6C6785);
  static const _line = PdfColor.fromInt(0xFFE4E1F0);

  static pw.Font? _regular;
  static pw.Font? _medium;
  static pw.Font? _bold;

  // Fonts ship with the app, so printing also works offline.
  static Future<void> _loadFonts() async {
    Future<pw.Font> load(String file) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
    _regular ??= await load('Inter-Regular.ttf');
    _medium ??= await load('Inter-Medium.ttf');
    _bold ??= await load('Inter-Bold.ttf');
  }

  static String fileName(Bill bill) => '${bill.id ?? 'bill'}.pdf';

  static Future<Uint8List> build(Bill bill, ShopProfile shop) async {
    await _loadFonts();
    final regular = _regular!;
    final medium = _medium!;
    final bold = _bold!;

    pw.TextStyle style(
      pw.Font font, {
      double size = 10.5,
      PdfColor color = PdfColors.black,
    }) => pw.TextStyle(font: font, fontSize: size, color: color);

    pw.Widget cell(
      String text, {
      pw.Alignment align = pw.Alignment.centerLeft,
      pw.TextStyle? textStyle,
    }) => pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(text, style: textStyle ?? style(regular)),
    );

    pw.Widget totalRow(
      String label,
      String value, {
      bool strong = false,
      PdfColor? color,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: style(
              strong ? bold : regular,
              size: strong ? 13 : 10.5,
              color: color ?? PdfColors.black,
            ),
          ),
          pw.Text(
            value,
            style: style(
              strong ? bold : medium,
              size: strong ? 13 : 10.5,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );

    final pdf = pw.Document(
      title: bill.id ?? 'Bill',
      author: shop.name,
      creator: 'BillBlitz',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              shop.footerNote,
              style: style(regular, size: 9, color: _muted),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: style(regular, size: 9, color: _muted),
            ),
          ],
        ),
        build: (ctx) => [
          // Header band
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: _brand,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shop.name,
                        style: style(bold, size: 20, color: PdfColors.white),
                      ),
                      if (shop.address.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          shop.address,
                          style: style(
                            regular,
                            size: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                      if (shop.phone.isNotEmpty)
                        pw.Text(
                          'Phone: ${shop.phone}',
                          style: style(
                            regular,
                            size: 10,
                            color: PdfColors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: style(bold, size: 16, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      bill.id ?? 'DRAFT',
                      style: style(medium, size: 10, color: PdfColors.white),
                    ),
                    pw.Text(
                      Fmt.dateTime(bill.date),
                      style: style(regular, size: 10, color: PdfColors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Customer + payment
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILLED TO',
                      style: style(bold, size: 9, color: _muted),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(bill.customerName, style: style(bold, size: 12)),
                    if (bill.customerPhone.isNotEmpty)
                      pw.Text(
                        bill.customerPhone,
                        style: style(regular, color: _muted),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'PAYMENT',
                    style: style(bold, size: 9, color: _muted),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    bill.paymentMethod.label,
                    style: style(bold, size: 12),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Items
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: const pw.BorderSide(color: _line),
              bottom: const pw.BorderSide(color: _line),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(32),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FixedColumnWidth(42),
              4: const pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _brandSoft),
                children: [
                  cell('#', textStyle: style(bold, color: _brand)),
                  cell('Item', textStyle: style(bold, color: _brand)),
                  cell(
                    'Price',
                    align: pw.Alignment.centerRight,
                    textStyle: style(bold, color: _brand),
                  ),
                  cell(
                    'Qty',
                    align: pw.Alignment.center,
                    textStyle: style(bold, color: _brand),
                  ),
                  cell(
                    'Amount',
                    align: pw.Alignment.centerRight,
                    textStyle: style(bold, color: _brand),
                  ),
                ],
              ),
              for (var i = 0; i < bill.items.length; i++)
                pw.TableRow(
                  children: [
                    cell('${i + 1}', textStyle: style(regular, color: _muted)),
                    cell(bill.items[i].name, textStyle: style(medium)),
                    cell(
                      Fmt.money(bill.items[i].price),
                      align: pw.Alignment.centerRight,
                    ),
                    cell(
                      '${bill.items[i].quantity}',
                      align: pw.Alignment.center,
                    ),
                    cell(
                      Fmt.money(bill.items[i].total),
                      align: pw.Alignment.centerRight,
                      textStyle: style(medium),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Totals
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _line),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  totalRow('Subtotal', Fmt.money(bill.subtotal)),
                  if (bill.discount > 0)
                    totalRow(
                      'Discount (${Fmt.percent(bill.discountPercent)}%)',
                      '- ${Fmt.money(bill.discount)}',
                    ),
                  totalRow('Taxable amount', Fmt.money(bill.taxableAmount)),
                  totalRow(
                    'Tax (${Fmt.percent(bill.taxPercent)}%)',
                    Fmt.money(bill.tax),
                  ),
                  pw.Divider(color: _line),
                  totalRow(
                    'Total',
                    Fmt.money(bill.total),
                    strong: true,
                    color: _brand,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Opens the system print / preview dialog.
  static Future<void> printBill(Bill bill, ShopProfile shop) async {
    final bytes = await build(bill, shop);
    await Printing.layoutPdf(
      name: fileName(bill),
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  /// Opens the system share sheet (WhatsApp, e-mail, save to files, ...).
  static Future<void> shareBill(Bill bill, ShopProfile shop) async {
    final bytes = await build(bill, shop);
    await Printing.sharePdf(bytes: bytes, filename: fileName(bill));
  }
}
