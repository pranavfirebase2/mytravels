import '../../domain/entities/agency.dart';
import '../../domain/repositories/agency_repository.dart';
import '../datasources/agency_remote_datasource.dart';
import '../models/agency_model.dart';

class AgencyRepositoryImpl implements AgencyRepository {
  final AgencyRemoteDataSource remoteDataSource;

  AgencyRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<Agency>> getAgencies() {
    // Mapping Stream<List<AgencyModel>> to Stream<List<Agency>>
    return remoteDataSource.getAgencies(); 
  }

  @override
  Future<void> addAgency(Agency agency) {
    return remoteDataSource.addAgency(AgencyModel.fromEntity(agency));
  }

  @override
  Future<void> updateAgency(Agency agency) {
    return remoteDataSource.updateAgency(AgencyModel.fromEntity(agency));
  }

  @override
  Future<void> deleteAgency(String id) {
    return remoteDataSource.deleteAgency(id);
  }
}
