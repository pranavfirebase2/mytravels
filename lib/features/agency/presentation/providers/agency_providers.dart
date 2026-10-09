import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/agency_remote_datasource.dart';
import '../../data/repositories/agency_repository_impl.dart';
import '../../domain/entities/agency.dart';
import '../../domain/repositories/agency_repository.dart';

final agencyRemoteDataSourceProvider = Provider<AgencyRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AgencyRemoteDataSourceImpl(firestore);
});

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  final dataSource = ref.watch(agencyRemoteDataSourceProvider);
  return AgencyRepositoryImpl(dataSource);
});

final agenciesStreamProvider = StreamProvider<List<Agency>>((ref) {
  final repository = ref.watch(agencyRepositoryProvider);
  return repository.getAgencies();
});

// For interacting with Agency operations from UI
final agencyControllerProvider = Provider<AgencyController>((ref) {
  final repository = ref.watch(agencyRepositoryProvider);
  return AgencyController(repository);
});

class AgencyController {
  final AgencyRepository _repository;

  AgencyController(this._repository);

  Future<void> addAgency(Agency agency) => _repository.addAgency(agency);
  Future<void> updateAgency(Agency agency) => _repository.updateAgency(agency);
  Future<void> deleteAgency(String id) => _repository.deleteAgency(id);
}
