import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/import_history_datasource.dart';
import '../../domain/entities/import_history.dart';

final importHistoryDataSourceProvider = Provider<ImportHistoryDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ImportHistoryDataSource(firestore);
});

final importHistoryStreamProvider = StreamProvider<List<ImportHistory>>((ref) {
  final dataSource = ref.watch(importHistoryDataSourceProvider);
  return dataSource.getImportHistoryStream();
});
