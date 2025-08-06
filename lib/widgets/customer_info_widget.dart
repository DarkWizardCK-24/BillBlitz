import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerInfoWidget extends StatelessWidget {
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;

  const CustomerInfoWidget({
    super.key,
    required this.customerNameController,
    required this.customerPhoneController,
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
                Icon(Icons.person, size: 20, color: Colors.deepPurple),
                SizedBox(width: 4),
                Text(
                  'Customer Information',
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
                            controller: customerNameController,
                            decoration: InputDecoration(
                              labelText: 'Customer Name',
                              hintText: 'Enter customer name',
                              prefixIcon: Icon(Icons.person_outline, size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          TextField(
                            controller: customerPhoneController,
                            decoration: InputDecoration(
                              labelText: 'Customer Phone',
                              hintText: 'Enter customer phone',
                              prefixIcon: Icon(Icons.phone_outlined, size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customerNameController,
                              decoration: InputDecoration(
                                labelText: 'Customer Name',
                                hintText: 'Enter customer name',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 24,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: customerPhoneController,
                              decoration: InputDecoration(
                                labelText: 'Customer Phone',
                                hintText: 'Enter customer phone',
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  size: 24,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.inter(fontSize: 14),
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
