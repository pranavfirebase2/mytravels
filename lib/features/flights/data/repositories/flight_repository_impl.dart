import '../../domain/entities/flight.dart';
import '../../domain/repositories/flight_repository.dart';
import '../datasources/flight_remote_datasource.dart';
import '../models/flight_model.dart';

class FlightRepositoryImpl implements FlightRepository {
  final FlightRemoteDataSource _remoteDataSource;

  FlightRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Flight>> getAllFlights() {
    return _remoteDataSource.getAllFlights();
  }

  @override
  Future<void> saveFlights(
    List<Flight> flights, {
    bool replaceSectorFares = true,
    bool replaceAllAgencyFares = false,
    void Function(int count, int total)? onProgress,
  }) async {
    final flightModels = flights.map((f) => FlightModel(
      id: f.id,
      agencyId: f.agencyId,
      agencyName: f.agencyName,
      source: f.source,
      destination: f.destination,
      date: f.date,
      airline: f.airline,
      flightNumber: f.flightNumber,
      timing: f.timing,
      baggage: f.baggage,
      seats: f.seats,
      marketedPrice: f.marketedPrice,
      parsedDate: f.parsedDate,
      createdAt: f.createdAt ?? DateTime.now(),
    )).toList();
    return _remoteDataSource.saveFlights(
      flightModels,
      replaceSectorFares: replaceSectorFares,
      replaceAllAgencyFares: replaceAllAgencyFares,
      onProgress: onProgress,
    );
  }

  @override
  Future<List<Flight>> getFlightsByAgency(String agencyId) {
    return _remoteDataSource.getFlightsByAgency(agencyId);
  }

  @override
  Future<void> deleteFlight(String flightId) {
    return _remoteDataSource.deleteFlight(flightId);
  }

  @override
  Future<void> deleteAllFlightsByAgency(String agencyId) {
    return _remoteDataSource.deleteAllFlightsByAgency(agencyId);
  }
}
