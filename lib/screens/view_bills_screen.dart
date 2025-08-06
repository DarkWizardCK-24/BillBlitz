import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/services/firestore_service.dart';
import 'package:billing_system/utils/pdf_bill_generator.dart';

class ViewBillsScreen extends StatelessWidget {
  const ViewBillsScreen({super.key});

  // Predefined list of color pairs for gradients
  static const List<List<Color>> _colorPairs = [
    [Color(0xFF6A1B9A), Color(0xFFAB47BC)], // Purple shades
    [Color(0xFF2E7D32), Color(0xFF66BB6A)], // Green shades
    [Color(0xFF0288D1), Color(0xFF4FC3F7)], // Blue shades
    [Color(0xFFD81B60), Color(0xFFF06292)], // Pink shades
    [Color(0xFFF57C00), Color(0xFFFFB300)], // Orange shades
  ];

  // Generate a persistent color index based on billId
  int _getColorIndex(String billId) {
    int hash = billId.hashCode.abs();
    return hash % _colorPairs.length;
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive crossAxisCount and aspect ratio
    int crossAxisCount;
    double childAspectRatio;
    if (screenWidth < 400) {
      crossAxisCount = 1;
      childAspectRatio = 1.6;
    } else if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.5;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 1.4;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 1.4;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        title: Center(
          child: Text(
            'Saved Bills',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 30,
            ),
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        toolbarHeight: 48,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getBillsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading bills: ${snapshot.error}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Bills Found',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Create a new bill to get started',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final bills = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final billData = bills[index].data() as Map<String, dynamic>;
              final bill = Bill.fromMap(billData);
              final billId = bills[index].id;
              final colorPair = _colorPairs[_getColorIndex(billId)];

              return InkWell(
                onTap: () {
                  PdfBillGenerator.generateAndPrintBill(
                    context: context,
                    billId: billId,
                    items: bill.items,
                    customerName: bill.customerName,
                    customerPhone: bill.customerPhone,
                    taxRate: bill.taxableAmount != 0
                        ? bill.tax / bill.taxableAmount
                        : 0.0,
                    discountRate: bill.subtotal != 0
                        ? bill.discount / bill.subtotal * 100
                        : 0.0,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colorPair,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill ID: $billId',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Customer: ${bill.customerName}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Total: INR  ${bill.total.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Date: ${bill.date.toString().split(' ')[0]} ${bill.date.toString().split(' ')[1].substring(0, 5)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              'View PDF',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
