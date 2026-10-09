import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../providers/flight_providers.dart';
import '../../domain/entities/flight.dart';

class AgencyDataPage extends ConsumerStatefulWidget {
  const AgencyDataPage({super.key});

  @override
  ConsumerState<AgencyDataPage> createState() => _AgencyDataPageState();
}

class _AgencyDataPageState extends ConsumerState<AgencyDataPage> {
  String? _selectedAgencyId;

  Future<void> _fetchFlights(String agencyId) async {
    await ref.read(agencyFlightsProvider.notifier).loadFlights(agencyId);
  }

  Future<void> _deleteFlight(String flightId) async {
    try {
      await ref.read(agencyFlightsProvider.notifier).deleteFlight(flightId, _selectedAgencyId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flight deleted successfully'), backgroundColor: AppColors.successGreen));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting flight', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed));
      }
    }
  }

  void _confirmDelete(Flight flight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flight', style: TextStyle(color: AppColors.errorRed)),
        content: Text('Are you sure you want to delete flight from ${flight.source} to ${flight.destination} on ${flight.date}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFlight(flight.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllFlights() async {
    if (_selectedAgencyId == null) return;
    try {
      await ref.read(agencyFlightsProvider.notifier).deleteAllFlights(_selectedAgencyId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All flights for this agency deleted successfully'), backgroundColor: AppColors.successGreen));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting all flights', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed));
      }
    }
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Flights', style: TextStyle(color: AppColors.errorRed)),
        content: const Text('Note: This will delete ALL flights for the currently selected agency. This action cannot be undone. Are you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllFlights();
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Map<String, List<Flight>> _groupFlights(List<Flight> flights) {
    final grouped = <String, List<Flight>>{};
    for (var flight in flights) {
      final airline = flight.airline.isNotEmpty ? flight.airline : '';
      final flightNum = flight.flightNumber.isNotEmpty && flight.flightNumber != '—' ? flight.flightNumber : '';
      final baggage = flight.baggage.isNotEmpty ? '(${flight.baggage})' : '';
      
      final key = '${flight.source} ${flight.destination} $airline $flightNum $baggage'.trim().replaceAll(RegExp(r'\s+'), ' ');
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(flight);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      activeRoute: '/data',
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Agency-wise Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Select an agency to view and manage their flight data.', style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ref.watch(agenciesStreamProvider).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text('Error: $e'),
                      data: (agencies) {
                        return DropdownButtonFormField<String>(
                          value: _selectedAgencyId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            labelText: 'Select Agency',
                          ),
                          items: agencies.map((agency) {
                            return DropdownMenuItem(
                              value: agency.id,
                              child: Text(agency.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedAgencyId = val;
                            });
                            if (val != null) {
                              _fetchFlights(val);
                            }
                          },
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedAgencyId != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep, color: AppColors.white),
                      label: const Text('Clear All Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _confirmDeleteAll,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedAgencyId == null)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Please select an agency to view flights', style: TextStyle(color: AppColors.textGrey))))
              else
                ref.watch(agencyFlightsProvider).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                  data: (flights) {
                    if (flights.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No flights found for this agency', style: TextStyle(color: AppColors.textGrey))));
                    }
                    final grouped = _groupFlights(flights);
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = ResponsiveLayout.isDesktop(context) ? 3 : ResponsiveLayout.isTablet(context) ? 2 : 1;
                        final spacing = 24.0;
                        final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: grouped.entries.map((entry) {
                            final title = entry.key;
                            final groupFlights = entry.value;
                            
                            return SizedBox(
                              width: itemWidth,
                              child: Card(
                                margin: EdgeInsets.zero,
                                color: AppColors.cardBackground,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                                      ),
                                      child: Text(
                                        title,
                                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Table(
                                        columnWidths: const {
                                          0: FlexColumnWidth(2),
                                          1: FlexColumnWidth(3),
                                          2: IntrinsicColumnWidth(),
                                        },
                                        children: groupFlights.map((f) {
                                          return TableRow(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
                                                child: Text(f.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
                                                child: Text('₹${f.marketedPrice.toInt()}/-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textBlack, fontSize: 15)),
                                              ),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 22),
                                                  onPressed: () => _confirmDelete(f),
                                                  tooltip: 'Delete Flight',
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    );
                  }
                ),
            ],
          ),
        ),
      ),
    );
  }
}
