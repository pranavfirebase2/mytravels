class ImportHistory {
  final String id;
  final String agencyName;
  final String agencyId;
  final String importMode;
  final int flightCount;
  final List<String> sectors;
  final DateTime timestamp;

  const ImportHistory({
    required this.id,
    required this.agencyName,
    required this.agencyId,
    required this.importMode,
    required this.flightCount,
    required this.sectors,
    required this.timestamp,
  });
}
