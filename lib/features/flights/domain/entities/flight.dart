class Flight {
  final String id;
  final String agencyId;
  final String agencyName; // Added agencyName
  final String source;
  final String destination;
  final String date;
  final String airline;
  final String flightNumber;
  final String timing;
  final String baggage;
  final String seats;
  final double marketedPrice;
  final DateTime? parsedDate; // Real date for filtering
  final DateTime? createdAt;
  final String via; // Connecting airport (e.g. "MCT"), empty if direct flight

  Flight({
    required this.id,
    required this.agencyId,
    required this.agencyName,
    required this.source,
    required this.destination,
    required this.date,
    required this.airline,
    required this.flightNumber,
    required this.timing,
    required this.baggage,
    required this.seats,
    required this.marketedPrice,
    this.parsedDate,
    this.createdAt,
    this.via = '',
  });

  Flight copyWith({
    String? id,
    String? agencyId,
    String? agencyName,
    String? source,
    String? destination,
    String? date,
    String? airline,
    String? flightNumber,
    String? timing,
    String? baggage,
    String? seats,
    double? marketedPrice,
    DateTime? parsedDate,
    DateTime? createdAt,
    String? via,
  }) {
    return Flight(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      agencyName: agencyName ?? this.agencyName,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      airline: airline ?? this.airline,
      flightNumber: flightNumber ?? this.flightNumber,
      timing: timing ?? this.timing,
      baggage: baggage ?? this.baggage,
      seats: seats ?? this.seats,
      marketedPrice: marketedPrice ?? this.marketedPrice,
      parsedDate: parsedDate ?? this.parsedDate,
      createdAt: createdAt ?? this.createdAt,
      via: via ?? this.via,
    );
  }
}
