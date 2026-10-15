import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/agency.dart';
import 'agency_providers.dart';
import '../../../import/presentation/providers/import_history_providers.dart';
import '../../../flights/presentation/providers/flight_providers.dart';

class AgencyUpdateStatus {
  final Agency agency;
  final DateTime? lastUpdated;
  final bool isUpdatedToday;
  final String? lastImportMode;
  final int? lastFlightCount;

  const AgencyUpdateStatus({
    required this.agency,
    required this.lastUpdated,
    required this.isUpdatedToday,
    this.lastImportMode,
    this.lastFlightCount,
  });
}

final agencyUpdateStatusesProvider = Provider<List<AgencyUpdateStatus>>((ref) {
  final agenciesAsync = ref.watch(agenciesStreamProvider);
  final historyAsync = ref.watch(importHistoryStreamProvider);
  final allFlightsAsync = ref.watch(allFlightsProvider);

  final agencies = agenciesAsync.value ?? [];
  final historyList = historyAsync.value ?? [];
  final allFlights = allFlightsAsync.value ?? [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final List<AgencyUpdateStatus> statuses = [];

  for (final agency in agencies) {
    // 1. Check latest 'Full Agency Reset' (Replace All) import history for this agency
    final fullResetHistory = historyList
        .where((h) =>
            h.agencyName.trim().toLowerCase() == agency.name.trim().toLowerCase() &&
            h.importMode.toLowerCase().contains('full'))
        .toList();

    final latestFullReset = fullResetHistory.isNotEmpty ? fullResetHistory.first : null;

    // 2. Check latest flight createdAt for this agency (fallback for flights imported before import_history)
    final agencyFlights = allFlights
        .where((f) => f.agencyName.trim().toLowerCase() == agency.name.trim().toLowerCase() && f.createdAt != null)
        .toList();

    DateTime? latestFlightTime;
    if (agencyFlights.isNotEmpty) {
      agencyFlights.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      latestFlightTime = agencyFlights.first.createdAt;
    }

    // Determine the Replace All timestamp:
    // If a 'Full Agency Reset' history exists, use its timestamp.
    // If no history exists at all for the app yet (legacy data), fallback to flight createdAt.
    DateTime? lastResetTime = latestFullReset?.timestamp;
    if (lastResetTime == null && fullResetHistory.isEmpty && historyList.isEmpty && agencyFlights.isNotEmpty) {
      lastResetTime = latestFlightTime;
    }

    // Determine if full reset occurred today with 10:30 AM cutoff rule
    bool updatedToday = false;
    if (lastResetTime != null) {
      final updatedLocal = lastResetTime.toLocal();
      final updatedDay = DateTime(updatedLocal.year, updatedLocal.month, updatedLocal.day);

      if (!updatedDay.isBefore(today)) {
        // Full Reset completed today!
        updatedToday = true;
      } else {
        // Full Reset was yesterday or earlier
        final isAfterCutoff = now.hour > 10 || (now.hour == 10 && now.minute >= 30);
        if (isAfterCutoff) {
          // After 10:30 AM cutoff: strictly outdated if no Full Reset today
          updatedToday = false;
        } else {
          // Before 10:30 AM: if Full Reset was done yesterday late (within 24 hours), still active
          updatedToday = now.difference(updatedLocal).inHours < 24;
        }
      }
    }

    statuses.add(AgencyUpdateStatus(
      agency: agency,
      lastUpdated: lastResetTime,
      isUpdatedToday: updatedToday,
      lastImportMode: latestFullReset?.importMode ?? 'Full Agency Reset',
      lastFlightCount: latestFullReset?.flightCount,
    ));
  }

  // Sort: Outdated (Needs update) first, then alphabetical
  statuses.sort((a, b) {
    if (a.isUpdatedToday != b.isUpdatedToday) {
      return a.isUpdatedToday ? 1 : -1; // false (outdated) comes first
    }
    return a.agency.name.toLowerCase().compareTo(b.agency.name.toLowerCase());
  });

  return statuses;
});

final outdatedAgenciesCountProvider = Provider<int>((ref) {
  final statuses = ref.watch(agencyUpdateStatusesProvider);
  return statuses.where((s) => !s.isUpdatedToday).length;
});
