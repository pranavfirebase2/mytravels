import '../entities/flight.dart';

abstract class FlightRepository {
  Future<List<Flight>> getAllFlights();
  Future<void> saveFlights(List<Flight> flights, {void Function(int count, int total)? onProgress});
  Future<List<Flight>> getFlightsByAgency(String agencyId);
  Future<void> deleteFlight(String flightId);
  Future<void> deleteAllFlightsByAgency(String agencyId);
}
