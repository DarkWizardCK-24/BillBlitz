import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billing_system/models/billing_item_model.dart';

class BillingItemsWidget extends StatelessWidget {
  final List<BillingItem> items;
  final Function(int) onRemoveItem;

  const BillingItemsWidget({
    super.key,
    required this.items,
    required this.onRemoveItem,
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
                Icon(Icons.list_alt, size: 20, color: Colors.deepPurple),
                SizedBox(width: 4),
                Text(
                  'Billing Items',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                    fontSize: 20,
                  ),
                ),
                Spacer(),
                if (items.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${items.length} items',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No Items Added Yet',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Add items to create your bill',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'INR ${item.price.toStringAsFixed(2)} X ${item.quantity}',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'INR ${item.total.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          IconButton(
                            onPressed: () => onRemoveItem(index),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
