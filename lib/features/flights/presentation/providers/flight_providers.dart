import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/flight_remote_datasource.dart';
import '../../data/repositories/flight_repository_impl.dart';
import '../../domain/repositories/flight_repository.dart';
import '../../domain/entities/flight.dart';

final flightRemoteDataSourceProvider = Provider<FlightRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FlightRemoteDataSource(firestore);
});

final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  final dataSource = ref.watch(flightRemoteDataSourceProvider);
  return FlightRepositoryImpl(dataSource);
});

class AgencyFlightsNotifier extends AsyncNotifier<List<Flight>> {
  @override
  FutureOr<List<Flight>> build() {
    return [];
  }

  Future<void> loadFlights(String agencyId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(flightRepositoryProvider);
      final flights = await repository.getFlightsByAgency(agencyId);
      state = AsyncValue.data(flights);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFlight(String flightId, String agencyId) async {
    try {
      final repository = ref.read(flightRepositoryProvider);
      await repository.deleteFlight(flightId);
      await loadFlights(agencyId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllFlights(String agencyId) async {
    try {
      final repository = ref.read(flightRepositoryProvider);
      await repository.deleteAllFlightsByAgency(agencyId);
      state = const AsyncValue.data([]);
    } catch (e) {
      rethrow;
    }
  }
}

final agencyFlightsProvider = AsyncNotifierProvider<AgencyFlightsNotifier, List<Flight>>(() {
  return AgencyFlightsNotifier();
});

final allFlightsProvider = FutureProvider<List<Flight>>((ref) async {
  final repository = ref.watch(flightRepositoryProvider);
  return repository.getAllFlights();
});

class SectorData {
  final String src;
  final String dst;
  final List<String> airlines;
  
  SectorData({required this.src, required this.dst, required this.airlines});
}

final sectorsProvider = FutureProvider<List<SectorData>>((ref) async {
  final flights = await ref.watch(allFlightsProvider.future);
  
  final Map<String, Set<String>> sectorMap = {};
  for (var flight in flights) {
    final key = '${flight.source}-${flight.destination}';
    if (!sectorMap.containsKey(key)) {
      sectorMap[key] = {};
    }
    if (flight.airline.isNotEmpty) {
      sectorMap[key]!.add(flight.airline);
    }
  }

  final List<SectorData> sectors = sectorMap.entries.map((entry) {
    final parts = entry.key.split('-');
    return SectorData(
      src: parts[0],
      dst: parts[1],
      airlines: entry.value.toList()..sort(),
    );
  }).toList();
  
  sectors.sort((a, b) => a.src.compareTo(b.src) == 0 ? a.dst.compareTo(b.dst) : a.src.compareTo(b.src));

  return sectors;
});
