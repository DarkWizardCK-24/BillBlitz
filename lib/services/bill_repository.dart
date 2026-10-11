import 'package:billing_system/models/bill_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Storage contract for bills. The UI only talks to this interface, which keeps
/// the screens testable without Firebase.
abstract class BillRepository {
  /// Saves [bill] and returns it with its newly assigned id.
  Future<Bill> saveBill(Bill bill);

  /// All bills, newest first.
  Stream<List<Bill>> watchBills();

  Future<void> deleteBill(String id);
}

class FirestoreBillRepository implements BillRepository {
  FirestoreBillRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bills =>
      _db.collection('bills');

  DocumentReference<Map<String, dynamic>> get _counter =>
      _db.collection('counters').doc('bills');

  /// Assigns the next sequential id (`BILL-00000001`, ...) inside a transaction,
  /// so two devices saving at the same moment can never receive the same id.
  @override
  Future<Bill> saveBill(Bill bill) async {
    try {
      // First run after upgrading: start counting after the highest id that
      // already exists. Afterwards the counter document is the source of truth.
      int seed = 0;
      if (!(await _counter.get()).exists) {
        seed = await _highestExistingNumber();
      }

      final id = await _db.runTransaction<String>((tx) async {
        final snap = await tx.get(_counter);
        final last = snap.exists
            ? (snap.data()?['last'] as num?)?.toInt() ?? seed
            : seed;
        final next = last + 1;
        final newId = 'BILL-${next.toString().padLeft(8, '0')}';

        tx.set(_counter, {'last': next});
        tx.set(_bills.doc(newId), bill.toMap());
        return newId;
      });

      return bill.copyWith(id: id);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied: check your Firestore rules for the '
          '"bills" and "counters" collections.',
        );
      }
      throw Exception('Failed to save bill: ${e.message}');
    }
  }

  Future<int> _highestExistingNumber() async {
    final snapshot = await _bills.get();
    int highest = 0;
    for (final doc in snapshot.docs) {
      if (!doc.id.startsWith('BILL-')) continue;
      final number = int.tryParse(doc.id.substring(5));
      if (number != null && number > highest) highest = number;
    }
    return highest;
  }

  @override
  Stream<List<Bill>> watchBills() {
    return _bills.orderBy('date', descending: true).snapshots().map((snap) {
      final bills = <Bill>[];
      for (final doc in snap.docs) {
        try {
          bills.add(Bill.fromMap(doc.data(), id: doc.id));
        } catch (_) {
          // Skip malformed documents instead of breaking the whole list.
        }
      }
      return bills;
    });
  }

  @override
  Future<void> deleteBill(String id) => _bills.doc(id).delete();
}
