import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/flight_model.dart';

class FlightRemoteDataSource {
  final FirebaseFirestore _firestore;

  FlightRemoteDataSource(this._firestore);

  Future<void> saveFlights(List<FlightModel> flights, {void Function(int count, int total)? onProgress}) async {
    try {
      if (onProgress != null) {
        int count = 0;
        final total = flights.length;
        for (var flight in flights) {
          final docRef = _firestore.collection('flights').doc();
          final newFlight = FlightModel(
            id: docRef.id,
            agencyId: flight.agencyId,
            agencyName: flight.agencyName,
            source: flight.source,
            destination: flight.destination,
            date: flight.date,
            airline: flight.airline,
            flightNumber: flight.flightNumber,
            timing: flight.timing,
            baggage: flight.baggage,
            seats: flight.seats,
            marketedPrice: flight.marketedPrice,
            parsedDate: flight.parsedDate,
          );
          await docRef.set(newFlight.toJson());
          count++;
          onProgress(count, total);
        }
      } else {
        final batch = _firestore.batch();
        for (var flight in flights) {
          final docRef = _firestore.collection('flights').doc();
          final newFlight = FlightModel(
            id: docRef.id,
            agencyId: flight.agencyId,
            agencyName: flight.agencyName,
            source: flight.source,
            destination: flight.destination,
            date: flight.date,
            airline: flight.airline,
            flightNumber: flight.flightNumber,
            timing: flight.timing,
            baggage: flight.baggage,
            seats: flight.seats,
            marketedPrice: flight.marketedPrice,
            parsedDate: flight.parsedDate,
          );
          batch.set(docRef, newFlight.toJson());
        }
        await batch.commit();
      }
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }

  Future<List<FlightModel>> getAllFlights() async {
    try {
      final snapshot = await _firestore.collection('flights').get();
      return snapshot.docs
          .map((doc) => FlightModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }

  Future<List<FlightModel>> getFlightsByAgency(String agencyId) async {
    try {
      final snapshot = await _firestore
          .collection('flights')
          .where('agencyId', isEqualTo: agencyId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => FlightModel.fromJson(doc.data())).toList();
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }

  Future<void> deleteFlight(String flightId) async {
    try {
      await _firestore.collection('flights').doc(flightId).delete();
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }

  Future<void> deleteAllFlightsByAgency(String agencyId) async {
    try {
      final snapshot = await _firestore
          .collection('flights')
          .where('agencyId', isEqualTo: agencyId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw FirebaseExceptionHandler.handleException(e);
    }
  }
}
