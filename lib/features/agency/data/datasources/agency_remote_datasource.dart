import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/agency_model.dart';

abstract class AgencyRemoteDataSource {
  Stream<List<AgencyModel>> getAgencies();
  Future<void> addAgency(AgencyModel agency);
  Future<void> updateAgency(AgencyModel agency);
  Future<void> deleteAgency(String id);
}

class AgencyRemoteDataSourceImpl implements AgencyRemoteDataSource {
  final FirebaseFirestore _firestore;

  AgencyRemoteDataSourceImpl(this._firestore);

  @override
  Stream<List<AgencyModel>> getAgencies() {
    return _firestore.collection('agencies').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AgencyModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  @override
  Future<void> addAgency(AgencyModel agency) async {
    try {
      final docRef = _firestore.collection('agencies').doc();
      final agencyWithId = AgencyModel(
        id: docRef.id,
        name: agency.name,
        comparisonDeduction: agency.comparisonDeduction,
        isStarred: agency.isStarred,
        whatsappNumber: agency.whatsappNumber,
      );
      await docRef.set(agencyWithId.toJson());
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> updateAgency(AgencyModel agency) async {
    try {
      await _firestore.collection('agencies').doc(agency.id).update(agency.toJson());
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteAgency(String id) async {
    try {
      await _firestore.collection('agencies').doc(id).delete();
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }
}
