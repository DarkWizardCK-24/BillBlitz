import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:billing_system/models/bill_model.dart';

class FirestoreService {
  final CollectionReference _billsCollection = FirebaseFirestore.instance
      .collection('bills');

  Future<void> saveBill(String billId, Bill bill) async {
    try {
      // Fetch all bill IDs to find the highest sequential number
      final querySnapshot = await _billsCollection.get();
      int maxIdNumber = 0;
      for (var doc in querySnapshot.docs) {
        final id = doc.id;
        if (id.startsWith('BILL-')) {
          try {
            final number = int.parse(id.substring(5));
            if (number > maxIdNumber) {
              maxIdNumber = number;
            }
          } catch (e) {
            // Skip invalid IDs
            continue;
          }
        }
      }

      // Generate the next ID (e.g., BILL-00000001)
      final nextIdNumber = maxIdNumber + 1;
      final customId = 'BILL-${nextIdNumber.toString().padLeft(8, '0')}';

      // Save the bill with the custom ID
      await _billsCollection.doc(customId).set(bill.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied: Please ensure you are authenticated and have write access to the bills collection.',
        );
      }
      throw Exception('Failed to save bill: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while saving bill: $e');
    }
  }

  Stream<QuerySnapshot> getBillsStream() {
    return _billsCollection.orderBy('date', descending: true).snapshots();
  }
}
