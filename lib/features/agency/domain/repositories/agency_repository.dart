import '../entities/agency.dart';

abstract class AgencyRepository {
  Stream<List<Agency>> getAgencies();
  Future<void> addAgency(Agency agency);
  Future<void> updateAgency(Agency agency);
  Future<void> deleteAgency(String id);
}
