import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddItemWidget extends StatelessWidget {
  final TextEditingController itemNameController;
  final TextEditingController itemPriceController;
  final TextEditingController itemQuantityController;
  final VoidCallback onAddItem;

  const AddItemWidget({
    super.key,
    required this.itemNameController,
    required this.itemPriceController,
    required this.itemQuantityController,
    required this.onAddItem,
  });

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
                Icon(
                  Icons.add_shopping_cart,
                  size: 20,
                  color: Colors.deepPurple,
                ),
                SizedBox(width: 4),
                Text(
                  'Add Item',
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
                          TextField(
                            controller: itemNameController,
                            decoration: InputDecoration(
                              labelText: 'Item Name',
                              hintText: 'Enter Item Name',
                              prefixIcon: Icon(Icons.inventory_2, size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            style: GoogleFonts.inter(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          TextField(
                            controller: itemPriceController,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.currency_rupee, size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: GoogleFonts.inter(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          TextField(
                            controller: itemQuantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              hintText: '1',
                              prefixIcon: Icon(Icons.numbers, size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: onAddItem,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 2,
                            ),
                            icon: Icon(Icons.add, size: 24),
                            label: Text(
                              'Add Item',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: itemNameController,
                              decoration: InputDecoration(
                                labelText: 'Item Name',
                                hintText: 'Enter Item Name',
                                prefixIcon: Icon(Icons.inventory_2, size: 24),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              style: GoogleFonts.inter(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: itemPriceController,
                              decoration: InputDecoration(
                                labelText: 'Price',
                                hintText: '0.00',
                                prefixIcon: Icon(
                                  Icons.currency_rupee,
                                  size: 24,
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
                              style: GoogleFonts.inter(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: itemQuantityController,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                hintText: '1',
                                prefixIcon: Icon(Icons.numbers, size: 24),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: onAddItem,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 2,
                              ),
                              icon: Icon(Icons.add, size: 24),
                              label: Text(
                                'Add Item',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
