import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billing_system/models/billing_item_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfBillGenerator {
  static Future<void> generateAndPrintBill({
    required BuildContext context,
    required String billId,
    required List<BillingItem> items,
    required String customerName,
    required String customerPhone,
    required double taxRate,
    required double discountRate,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();

    double subtotal = items.fold(0, (sum, item) => sum + item.total);
    double discount = subtotal * (discountRate / 100);
    double taxableAmount = subtotal - discount;
    double tax = taxableAmount * taxRate;
    double total = taxableAmount + tax;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Your Shop Name',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Your Shop Address | Phone: Your Shop Phone',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill ID: $billId',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Customer: ${customerName.isNotEmpty ? customerName : 'Walk-in Customer'}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.Text(
                      'Phone: ${customerPhone.isNotEmpty ? customerPhone : 'N/A'}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Items',
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: pw.FractionColumnWidth(0.1),
                    1: pw.FractionColumnWidth(0.4),
                    2: pw.FractionColumnWidth(0.2),
                    3: pw.FractionColumnWidth(0.15),
                    4: pw.FractionColumnWidth(0.15),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Center(
                            child: pw.Text(
                              '#',
                              style: pw.TextStyle(font: boldFont, fontSize: 12),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Center(
                            child: pw.Text(
                              'Item',
                              style: pw.TextStyle(font: boldFont, fontSize: 12),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Center(
                            child: pw.Text(
                              'Price',
                              style: pw.TextStyle(font: boldFont, fontSize: 12),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Center(
                            child: pw.Text(
                              'Qty',
                              style: pw.TextStyle(font: boldFont, fontSize: 12),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Center(
                            child: pw.Text(
                              'Total',
                              style: pw.TextStyle(font: boldFont, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (var i = 0; i < items.length; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text(
                                '${i + 1}',
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text(
                                items[i].name,
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text(
                                'INR ${items[i].price.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text(
                                '${items[i].quantity}',
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text(
                                'INR ${items[i].total.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Subtotal',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                        pw.Text(
                          'INR ${subtotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ],
                    ),
                    if (discount > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Discount',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            '-INR ${discount.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                        ],
                      ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Taxable Amount',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                        pw.Text(
                          'INR ${taxableAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Tax (${(taxRate * 100).toStringAsFixed(1)}%)',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                        pw.Text(
                          'INR ${tax.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 14,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          'INR ${total.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 14,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Center(
                  child: pw.Text(
                    'Thank You For Shopping',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bill printed successfully',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
