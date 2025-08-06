import 'package:billing_system/screens/view_bills_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/services/firestore_service.dart';
import 'package:billing_system/utils/pdf_bill_generator.dart';
import 'package:billing_system/widgets/customer_info_widget.dart';
import 'package:billing_system/widgets/add_item_widget.dart';
import 'package:billing_system/widgets/billing_items_widget.dart';
import 'package:billing_system/widgets/bill_summary_widget.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<BillingItem> items = [];
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemPriceController = TextEditingController();
  TextEditingController itemQuantityController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  double taxRate = 0.10;
  double discountRate = 0.0;

  final FirestoreService _firestoreService = FirestoreService();

  void addItem() {
    if (itemNameController.text.isNotEmpty &&
        itemPriceController.text.isNotEmpty &&
        itemQuantityController.text.isNotEmpty) {
      try {
        final price = double.parse(itemPriceController.text);
        final quantity = int.parse(itemQuantityController.text);
        if (price <= 0 || quantity <= 0) {
          throw FormatException('Price and quantity must be positive');
        }
        setState(() {
          items.add(
            BillingItem(
              name: itemNameController.text.trim(),
              price: price,
              quantity: quantity,
            ),
          );
          itemNameController.clear();
          itemPriceController.clear();
          itemQuantityController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item added successfully',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter valid price and quantity',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all fields',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item removed successfully',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  void clearAll() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Clear All Items',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to clear all information?',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  items.clear();
                  itemNameController.clear();
                  itemPriceController.clear();
                  itemQuantityController.clear();
                  customerNameController.clear();
                  customerPhoneController.clear();
                  taxRate = 0.10;
                  discountRate = 0.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All items cleared',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void saveBill() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No items to save',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      double subtotal = items.fold(0, (sum, item) => sum + item.total);
      double discount = subtotal * (discountRate / 100);
      double taxableAmount = subtotal - discount;
      double tax = taxableAmount * taxRate;
      double total = taxableAmount + tax;

      String billId = DateTime.now().millisecondsSinceEpoch.toString();
      Bill bill = Bill(
        customerName: customerNameController.text.isEmpty
            ? 'Walk-in Customer'
            : customerNameController.text.trim(),
        customerPhone: customerPhoneController.text.isEmpty
            ? 'Walk-in Customer'
            : customerPhoneController.text.trim(),
        items: items,
        subtotal: subtotal,
        discount: discount,
        taxableAmount: taxableAmount,
        tax: tax,
        total: total,
        date: DateTime.now(),
      );

      await _firestoreService.saveBill(billId, bill);
      setState(() {
        items.clear();
        itemNameController.clear();
        itemPriceController.clear();
        itemQuantityController.clear();
        customerNameController.clear();
        customerPhoneController.clear();
        taxRate = 0.10;
        discountRate = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bill saved successfully',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save bill: $e',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void printBill() {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No items to print',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    PdfBillGenerator.generateAndPrintBill(
      context: context,
      billId: DateTime.now().millisecondsSinceEpoch.toString(),
      items: items,
      customerName: customerNameController.text.isEmpty
          ? 'Walk-in Customer'
          : customerNameController.text.trim(),
      customerPhone: customerPhoneController.text.isEmpty
          ? 'Walk-in Customer'
          : customerPhoneController.text.trim(),
      taxRate: taxRate,
      discountRate: discountRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = items.fold(0, (sum, item) => sum + item.total);
    double discount = subtotal * (discountRate / 100);
    double taxableAmount = subtotal - discount;
    double tax = taxableAmount * taxRate;
    double total = taxableAmount + tax;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Billing System',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              CustomerInfoWidget(
                customerNameController: customerNameController,
                customerPhoneController: customerPhoneController,
              ),
              SizedBox(height: 8),
              AddItemWidget(
                itemNameController: itemNameController,
                itemPriceController: itemPriceController,
                itemQuantityController: itemQuantityController,
                onAddItem: addItem,
              ),
              SizedBox(height: 8),
              BillingItemsWidget(items: items, onRemoveItem: removeItem),
              SizedBox(height: 8),
              BillSummaryWidget(
                subtotal: subtotal,
                discount: discount,
                taxableAmount: taxableAmount,
                tax: tax,
                total: total,
                taxRate: taxRate,
                discountRate: discountRate,
                onDiscountChanged: (value) {
                  setState(() {
                    discountRate = double.tryParse(value) ?? 0.0;
                  });
                },
                onTaxRateChanged: (value) {
                  setState(() {
                    taxRate = (double.tryParse(value) ?? 0.0) / 100;
                  });
                },
              ),
              SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: clearAll,
                          icon: Icon(Icons.clear_all, size: 20),
                          label: Text(
                            'Clear All',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: items.isEmpty ? null : printBill,
                          icon: Icon(Icons.print, size: 20),
                          label: Text(
                            'Print Bill',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: items.isEmpty
                                ? Colors.grey
                                : Colors.deepPurple,
                            foregroundColor: items.isEmpty
                                ? Colors.black
                                : Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewBillsScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.receipt_long, size: 20),
                          label: Text(
                            'View Saved Bills',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      if (items.isNotEmpty) SizedBox(width: 8),
                      if (items.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: saveBill,
                            icon: Icon(Icons.save, size: 20),
                            label: Text(
                              'Save Bill',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
