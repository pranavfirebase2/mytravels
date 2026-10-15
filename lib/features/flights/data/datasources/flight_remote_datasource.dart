import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/flight_model.dart';

class FlightRemoteDataSource {
  final FirebaseFirestore _firestore;

  FlightRemoteDataSource(this._firestore);

  Future<void> saveFlights(
    List<FlightModel> flights, {
    bool replaceSectorFares = true,
    bool replaceAllAgencyFares = false,
    void Function(int count, int total)? onProgress,
  }) async {
    try {
      if (flights.isEmpty) return;

      // 1. Full Agency Replacement:
      // If enabled, removes ALL previous flights for this agency across ALL sectors (Complete Daily Reset)
      if (replaceAllAgencyFares) {
        final agencyIds = flights.map((f) => f.agencyId).toSet();
        for (final agencyId in agencyIds) {
          final snapshot = await _firestore
              .collection('flights')
              .where('agencyId', isEqualTo: agencyId)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final deleteBatch = _firestore.batch();
            int deleteCount = 0;
            for (var doc in snapshot.docs) {
              deleteBatch.delete(doc.reference);
              deleteCount++;
              if (deleteCount >= 450) {
                await deleteBatch.commit();
                deleteCount = 0;
              }
            }
            if (deleteCount > 0) {
              await deleteBatch.commit();
            }
          }
        }
      }
      // 2. Scoped Sector Replacement:
      // If enabled and NOT full agency replacement, remove old flights belonging to the same agency
      // ONLY in the specific sectors present in this import batch.
      // Other sectors of this agency remain 100% untouched and safe!
      else if (replaceSectorFares) {
        final Map<String, Set<String>> agencySectors = {};
        for (var f in flights) {
          final sectorKey = '${f.source.toUpperCase()}_${f.destination.toUpperCase()}';
          agencySectors.putIfAbsent(f.agencyId, () => {}).add(sectorKey);
        }

        for (var entry in agencySectors.entries) {
          final agencyId = entry.key;
          for (var sector in entry.value) {
            final parts = sector.split('_');
            final src = parts[0];
            final dst = parts[1];

            final snapshot = await _firestore
                .collection('flights')
                .where('agencyId', isEqualTo: agencyId)
                .where('source', isEqualTo: src)
                .where('destination', isEqualTo: dst)
                .get();

            if (snapshot.docs.isNotEmpty) {
              final deleteBatch = _firestore.batch();
              int deleteCount = 0;
              for (var doc in snapshot.docs) {
                deleteBatch.delete(doc.reference);
                deleteCount++;
                if (deleteCount >= 450) {
                  await deleteBatch.commit();
                  deleteCount = 0;
                }
              }
              if (deleteCount > 0) {
                await deleteBatch.commit();
              }
            }
          }
        }
      }

      // 2. Ultra-Fast Batch Insert (up to 450 items per network call)
      int count = 0;
      final total = flights.length;
      final now = DateTime.now();

      for (var i = 0; i < flights.length; i += 450) {
        final batch = _firestore.batch();
        final end = (i + 450 < flights.length) ? i + 450 : flights.length;
        final chunk = flights.sublist(i, end);

        for (var j = 0; j < chunk.length; j++) {
          final flight = chunk[j];
          final globalIndex = i + j;
          final docRef = _firestore.collection('flights').doc();
          final newFlight = FlightModel(
            id: docRef.id,
            agencyId: flight.agencyId,
            agencyName: flight.agencyName,
            source: flight.source.toUpperCase(),
            destination: flight.destination.toUpperCase(),
            date: flight.date,
            airline: flight.airline,
            flightNumber: flight.flightNumber,
            timing: flight.timing,
            baggage: flight.baggage,
            seats: flight.seats,
            marketedPrice: flight.marketedPrice,
            parsedDate: flight.parsedDate,
            createdAt: now.add(Duration(milliseconds: globalIndex)), // Preserves 100% exact WhatsApp order!
            via: flight.via,
          );
          batch.set(docRef, newFlight.toJson());
        }

        await batch.commit();
        count += chunk.length;
        if (onProgress != null) {
          onProgress(count, total);
        }
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
          .get();
      final list = snapshot.docs.map((doc) => FlightModel.fromJson(doc.data())).toList();
      // In-memory sort by createdAt preserves exact WhatsApp order without requiring a Firestore composite index!
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });
      return list;
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
