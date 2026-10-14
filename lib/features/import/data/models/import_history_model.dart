import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/import_history.dart';

class ImportHistoryModel extends ImportHistory {
  const ImportHistoryModel({
    required super.id,
    required super.agencyName,
    required super.agencyId,
    required super.importMode,
    required super.flightCount,
    required super.sectors,
    required super.timestamp,
  });

  factory ImportHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parsedTime = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      parsedTime = (data['timestamp'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedTime = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    final rawSectors = data['sectors'];
    final sectorsList = (rawSectors is List)
        ? rawSectors.map((e) => e.toString()).toList()
        : <String>[];

    return ImportHistoryModel(
      id: doc.id,
      agencyName: data['agencyName']?.toString() ?? 'Unknown Agency',
      agencyId: data['agencyId']?.toString() ?? '',
      importMode: data['importMode']?.toString() ?? 'Standard Import',
      flightCount: (data['flightCount'] is num) ? (data['flightCount'] as num).toInt() : 0,
      sectors: sectorsList,
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agencyName': agencyName,
      'agencyId': agencyId,
      'importMode': importMode,
      'flightCount': flightCount,
      'sectors': sectors,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': timestamp.toIso8601String(),
    };
  }
}
