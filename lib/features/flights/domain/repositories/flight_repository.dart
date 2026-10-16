import '../entities/flight.dart';

abstract class FlightRepository {
  Future<List<Flight>> getAllFlights();
  Stream<List<Flight>> watchAllFlights();
  Future<void> saveFlights(
    List<Flight> flights, {
    bool replaceSectorFares = true,
    bool replaceAllAgencyFares = false,
    void Function(int count, int total)? onProgress,
  });
  Future<List<Flight>> getFlightsByAgency(String agencyId);
  Future<void> updateFlight(Flight flight);
  Future<void> deleteFlight(String flightId);
  Future<void> deleteAllFlightsByAgency(String agencyId);
}
