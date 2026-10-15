import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../../../fare_broadcast/presentation/providers/fare_broadcast_providers.dart';
import '../providers/flight_providers.dart';
import '../../domain/entities/flight.dart';

class AgencyDataPage extends ConsumerStatefulWidget {
  const AgencyDataPage({super.key});

  @override
  ConsumerState<AgencyDataPage> createState() => _AgencyDataPageState();
}

class _AgencyDataPageState extends ConsumerState<AgencyDataPage> {
  String? _selectedAgencyId;
  String? _selectedSectorFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFlights(String agencyId) async {
    await ref.read(agencyFlightsProvider.notifier).loadFlights(agencyId);
  }

  DateTime? _parseFlightDate(String raw) {
    final clean = raw.trim();
    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    final parts = clean.split(RegExp(r'[\s\-/]+'));
    if (parts.length >= 2) {
      final day = int.tryParse(parts[0]);
      if (day != null) {
        final monthStr = parts[1].toUpperCase();
        const shortMonths = {
          'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
          'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
        };
        final m = shortMonths[monthStr.length >= 3 ? monthStr.substring(0, 3) : monthStr] ?? int.tryParse(parts[1]);
        if (m != null && m >= 1 && m <= 12) {
          int year = DateTime.now().year;
          if (parts.length >= 3) {
            year = int.tryParse(parts[2]) ?? year;
            if (year < 100) year += 2000;
          }
          return DateTime(year, m, day);
        }
      }
    }
    return null;
  }

  Future<void> _deleteFlight(String flightId) async {
    try {
      await ref.read(agencyFlightsProvider.notifier).deleteFlight(flightId, _selectedAgencyId!);
      ref.invalidate(allFlightsProvider);
      ref.invalidate(sectorsProvider);
      ref.invalidate(fareBroadcastProvider);
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

  void _showEditFlightDialog(Flight flight) {
    final formKey = GlobalKey<FormState>();
    final srcController = TextEditingController(text: flight.source);
    final dstController = TextEditingController(text: flight.destination);
    final dateController = TextEditingController(text: flight.date);
    final airlineController = TextEditingController(text: flight.airline);
    final flightNumController = TextEditingController(text: flight.flightNumber);
    final priceController = TextEditingController(text: flight.marketedPrice.toInt().toString());
    final baggageController = TextEditingController(text: flight.baggage);
    final viaController = TextEditingController(text: flight.via);
    final timingController = TextEditingController(text: flight.timing);
    final seatsController = TextEditingController(text: flight.seats);

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (innerCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Flight Rate',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          flight.agencyName,
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textGrey),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sector: Source & Destination
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: srcController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 3,
                                decoration: const InputDecoration(
                                  labelText: 'From (Origin)',
                                  hintText: 'e.g. CCJ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  counterText: '',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().length != 3) {
                                    return '3-letter code';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: dstController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 3,
                                decoration: const InputDecoration(
                                  labelText: 'To (Destination)',
                                  hintText: 'e.g. JED',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  counterText: '',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().length != 3) {
                                    return '3-letter code';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Date & Price
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: dateController,
                                decoration: const InputDecoration(
                                  labelText: 'Travel Date',
                                  hintText: 'e.g. 20 OCT',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Date required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Marketed Fare (₹)',
                                  hintText: 'e.g. 26000',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixText: '₹ ',
                                ),
                                validator: (val) {
                                  if (val == null || double.tryParse(val.trim()) == null) {
                                    return 'Valid price required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Airline & Flight Number
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: airlineController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Airline Code',
                                  hintText: 'e.g. QP or 6E',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.flight_rounded, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: flightNumController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Flight Number',
                                  hintText: 'e.g. 596',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Baggage & Via
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: baggageController,
                                decoration: const InputDecoration(
                                  labelText: 'Baggage Allowance',
                                  hintText: 'e.g. 30+7 KG',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.luggage_rounded, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: viaController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Via (Connecting City)',
                                  hintText: 'e.g. MCT (blank if direct)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.connecting_airports_rounded, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Timing & Seats
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: timingController,
                                decoration: const InputDecoration(
                                  labelText: 'Timing',
                                  hintText: 'e.g. 04:15 or blank',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.schedule_rounded, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: seatsController,
                                decoration: const InputDecoration(
                                  labelText: 'Seats Available',
                                  hintText: 'e.g. 9 or blank',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.event_seat_rounded, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(isSaving ? 'Saving...' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);

                          try {
                            final price = double.tryParse(priceController.text.trim()) ?? flight.marketedPrice;
                            final dateText = dateController.text.trim();
                            final parsed = _parseFlightDate(dateText) ?? flight.parsedDate;

                            final updatedFlight = flight.copyWith(
                              source: srcController.text.trim().toUpperCase(),
                              destination: dstController.text.trim().toUpperCase(),
                              date: dateText,
                              airline: airlineController.text.trim().toUpperCase(),
                              flightNumber: flightNumController.text.trim().toUpperCase(),
                              marketedPrice: price,
                              baggage: baggageController.text.trim(),
                              via: viaController.text.trim().toUpperCase(),
                              timing: timingController.text.trim(),
                              seats: seatsController.text.trim(),
                              parsedDate: parsed,
                            );

                            await ref.read(agencyFlightsProvider.notifier).updateFlight(updatedFlight);
                            ref.invalidate(allFlightsProvider);
                            ref.invalidate(sectorsProvider);
                            ref.invalidate(fareBroadcastProvider);

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Flight rate updated successfully!'),
                                  backgroundColor: AppColors.successGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error updating flight: $e'), backgroundColor: AppColors.errorRed),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAllFlights() async {
    if (_selectedAgencyId == null) return;
    try {
      await ref.read(agencyFlightsProvider.notifier).deleteAllFlights(_selectedAgencyId!);
      ref.invalidate(allFlightsProvider);
      ref.invalidate(sectorsProvider);
      ref.invalidate(fareBroadcastProvider);
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
      final key = '${flight.source} ➝ ${flight.destination}';
      
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
                          initialValue: _selectedAgencyId,
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
                              _selectedSectorFilter = null;
                              _searchQuery = '';
                              _searchController.clear();
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
                    final availableSectors = grouped.keys.toList()..sort();

                    // Apply Sector Filter & Search Query
                    final Map<String, List<Flight>> filteredGrouped = {};
                    for (var entry in grouped.entries) {
                      final sectorKey = entry.key;
                      if (_selectedSectorFilter != null &&
                          _selectedSectorFilter != 'ALL' &&
                          _selectedSectorFilter != sectorKey) {
                        continue;
                      }

                      var sectorFlights = entry.value;
                      if (_searchQuery.isNotEmpty) {
                        sectorFlights = sectorFlights.where((f) {
                          final q = _searchQuery.toLowerCase();
                          return f.date.toLowerCase().contains(q) ||
                              f.airline.toLowerCase().contains(q) ||
                              f.flightNumber.toLowerCase().contains(q) ||
                              f.marketedPrice.toInt().toString().contains(q) ||
                              f.baggage.toLowerCase().contains(q) ||
                              f.via.toLowerCase().contains(q) ||
                              sectorKey.toLowerCase().contains(q);
                        }).toList();
                      }

                      if (sectorFlights.isNotEmpty) {
                        filteredGrouped[sectorKey] = sectorFlights;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sector Filter Toolbar
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.tune_rounded, size: 18, color: AppColors.primaryBlue),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Filter by Sector',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.headerDark,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 240,
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search date, flight no...',
                                        prefixIcon: const Icon(Icons.search, size: 18),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 16),
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                    _searchQuery = '';
                                                  });
                                                },
                                              )
                                            : null,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val.trim().toLowerCase();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FilterChip(
                                      label: Text('All Sectors (${flights.length})'),
                                      selected: _selectedSectorFilter == null || _selectedSectorFilter == 'ALL',
                                      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                                      checkmarkColor: AppColors.primaryBlue,
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: (_selectedSectorFilter == null || _selectedSectorFilter == 'ALL')
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: (_selectedSectorFilter == null || _selectedSectorFilter == 'ALL')
                                            ? AppColors.primaryBlue
                                            : Colors.black87,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedSectorFilter = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ...availableSectors.map((sector) {
                                      final count = grouped[sector]?.length ?? 0;
                                      final isSelected = _selectedSectorFilter == sector;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: FilterChip(
                                          label: Text('$sector ($count)'),
                                          selected: isSelected,
                                          selectedColor: const Color(0xFFDCFCE7),
                                          checkmarkColor: const Color(0xFF166534),
                                          side: BorderSide(
                                            color: isSelected
                                                ? const Color(0xFF22C55E)
                                                : Colors.grey.withValues(alpha: 0.3),
                                          ),
                                          labelStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF166534) : Colors.black87,
                                          ),
                                          onSelected: (selected) {
                                            setState(() {
                                              _selectedSectorFilter = selected ? sector : null;
                                            });
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (filteredGrouped.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No flights match the selected filter',
                                style: TextStyle(color: AppColors.textGrey),
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = ResponsiveLayout.isDesktop(context) ? 3 : ResponsiveLayout.isTablet(context) ? 2 : 1;
                              final spacing = 24.0;
                              final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: filteredGrouped.entries.map((entry) {
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
                                                0: FlexColumnWidth(2.0),
                                                1: FlexColumnWidth(2.3),
                                                2: FlexColumnWidth(2.2),
                                                3: IntrinsicColumnWidth(),
                                              },
                                              children: groupFlights.map((f) {
                                                final hasFlightInfo = (f.airline.isNotEmpty && f.airline != '—') || (f.flightNumber.isNotEmpty && f.flightNumber != '—');
                                                final flightText = [
                                                  if (f.airline.isNotEmpty && f.airline != '—') f.airline,
                                                  if (f.flightNumber.isNotEmpty && f.flightNumber != '—') f.flightNumber,
                                                ].join(' ');

                                                final extraDetails = [
                                                  if (f.timing.isNotEmpty && f.timing != '—') f.timing,
                                                  if (f.baggage.isNotEmpty && f.baggage != '—') f.baggage,
                                                ].join(' • ');

                                                return TableRow(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
                                                      child: Text(f.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            hasFlightInfo ? flightText : '—',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                                                          ),
                                                          if (extraDetails.isNotEmpty)
                                                            Text(
                                                              extraDetails,
                                                              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
                                                      child: Text('₹${f.marketedPrice.toInt()}/-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textBlack, fontSize: 13)),
                                                    ),
                                                    Align(
                                                      alignment: Alignment.centerRight,
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue, size: 18),
                                                            onPressed: () => _showEditFlightDialog(f),
                                                            tooltip: 'Edit Flight Rate',
                                                            visualDensity: VisualDensity.compact,
                                                            padding: const EdgeInsets.all(4),
                                                            constraints: const BoxConstraints(),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 18),
                                                            onPressed: () => _confirmDelete(f),
                                                            tooltip: 'Delete Flight',
                                                            visualDensity: VisualDensity.compact,
                                                            padding: const EdgeInsets.all(4),
                                                            constraints: const BoxConstraints(),
                                                          ),
                                                        ],
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
                          ),
                      ],
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
