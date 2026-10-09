import '../../domain/entities/flight.dart';

class FlightModel extends Flight {
  FlightModel({
    required super.id,
    required super.agencyId,
    required super.agencyName,
    required super.source,
    required super.destination,
    required super.date,
    required super.airline,
    required super.flightNumber,
    required super.timing,
    required super.baggage,
    required super.seats,
    required super.marketedPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'source': source,
      'destination': destination,
      'date': date,
      'airline': airline,
      'flightNumber': flightNumber,
      'timing': timing,
      'baggage': baggage,
      'seats': seats,
      'marketedPrice': marketedPrice,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      id: json['id'] ?? '',
      agencyId: json['agencyId'] ?? '',
      agencyName: json['agencyName'] ?? 'Unknown Agency',
      source: json['source'] ?? '',
      destination: json['destination'] ?? '',
      date: json['date'] ?? '',
      airline: json['airline'] ?? '',
      flightNumber: json['flightNumber'] ?? '',
      timing: json['timing'] ?? '',
      baggage: json['baggage'] ?? '',
      seats: json['seats'] ?? '',
      marketedPrice: double.tryParse(json['marketedPrice']?.toString() ?? '0') ?? 0.0,
    );
  }
}
