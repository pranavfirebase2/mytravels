import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/import_history_model.dart';

class ImportHistoryDataSource {
  final FirebaseFirestore _firestore;

  ImportHistoryDataSource(this._firestore);

  Future<void> recordImport({
    required String agencyName,
    required String agencyId,
    required String importMode,
    required int flightCount,
    required List<String> sectors,
  }) async {
    final docRef = _firestore.collection('import_history').doc();
    final model = ImportHistoryModel(
      id: docRef.id,
      agencyName: agencyName,
      agencyId: agencyId,
      importMode: importMode,
      flightCount: flightCount,
      sectors: sectors,
      timestamp: DateTime.now(),
    );
    await docRef.set(model.toMap());
  }

  Stream<List<ImportHistoryModel>> getImportHistoryStream() {
    return _firestore.collection('import_history').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ImportHistoryModel.fromFirestore(doc)).toList();
      // Sort in memory newest first
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> deleteHistoryItem(String id) async {
    await _firestore.collection('import_history').doc(id).delete();
  }

  Future<void> clearAllHistory() async {
    final snapshot = await _firestore.collection('import_history').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
