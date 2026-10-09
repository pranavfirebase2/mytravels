import '../entities/flight.dart';

abstract class FlightRepository {
  Future<void> saveFlights(List<Flight> flights);
  Future<List<Flight>> getFlightsByAgency(String agencyId);
  Future<void> deleteFlight(String flightId);
  Future<void> deleteAllFlightsByAgency(String agencyId);
}
