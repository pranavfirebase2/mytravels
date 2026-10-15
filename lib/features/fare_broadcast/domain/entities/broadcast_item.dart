class BroadcastDateItem {
  final String rawDate;
  final String displayDate;
  double lowestPrice;
  final String agencyName;
  String flightNumber;
  String baggage;
  String via;
  final DateTime? parsedDate;
  bool isSelected;

  BroadcastDateItem({
    required this.rawDate,
    required this.displayDate,
    required this.lowestPrice,
    required this.agencyName,
    required this.flightNumber,
    required this.baggage,
    this.via = '',
    this.parsedDate,
    this.isSelected = true,
  });
}

class BroadcastSectorItem {
  final String source;
  final String destination;
  String flightNumber;
  String baggage;
  bool isSelected;
  List<BroadcastDateItem> dates;

  BroadcastSectorItem({
    required this.source,
    required this.destination,
    required this.flightNumber,
    required this.baggage,
    this.isSelected = true,
    required this.dates,
  });

  String get sectorKey => '$source-$destination';
}
