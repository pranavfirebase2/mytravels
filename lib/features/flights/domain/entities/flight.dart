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
  });
}
