import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BillSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double taxableAmount;
  final double tax;
  final double total;
  final double taxRate;
  final double discountRate;
  final ValueChanged<String> onDiscountChanged;
  final ValueChanged<String> onTaxRateChanged;

  const BillSummaryWidget({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
    required this.total,
    required this.taxRate,
    required this.discountRate,
    required this.onDiscountChanged,
    required this.onTaxRateChanged,
  });

  Widget buildSummaryRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.deepPurple : Colors.blueGrey.shade700,
            ),
          ),
          Text(
            'INR ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.deepPurple : Colors.blueGrey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 20, color: Colors.deepPurple),
                SizedBox(width: 4),
                Text(
                  'Bill Summary',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth < 600
                    ? Column(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Discount %',
                                hintText: '0.0',
                                prefixIcon: Icon(
                                  Icons.local_offer_outlined,
                                  size: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: onDiscountChanged,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                          SizedBox(height: 4),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Tax Rate',
                                hintText: '10.0',
                                prefixIcon: Icon(Icons.percent, size: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: onTaxRateChanged,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Discount %',
                                  hintText: '0.0',
                                  prefixIcon: Icon(
                                    Icons.local_offer_outlined,
                                    size: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: onDiscountChanged,
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Tax Rate',
                                  hintText: '10.0',
                                  prefixIcon: Icon(Icons.percent, size: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: onTaxRateChanged,
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      );
              },
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  buildSummaryRow(context, 'Subtotal', subtotal),
                  if (discount > 0)
                    buildSummaryRow(context, 'Discount', -discount),
                  buildSummaryRow(context, 'Taxable Amount', taxableAmount),
                  buildSummaryRow(
                    context,
                    'Tax (${(taxRate * 100).toStringAsFixed(1)}%)',
                    tax,
                  ),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  buildSummaryRow(context, 'Total', total, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
