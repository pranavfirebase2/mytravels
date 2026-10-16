import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../agency/domain/entities/agency.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../../../flights/domain/entities/flight.dart';
import '../../../flights/presentation/providers/flight_providers.dart';
import '../../../flights/presentation/widgets/flight_inquiry_dialog.dart';
import '../widgets/flight_date_picker_dialog.dart';
import '../widgets/sector_comparison_table.dart';

class SectorDetailsPage extends ConsumerStatefulWidget {
  final String src;
  final String dst;
  final DateTime? initialDate;

  const SectorDetailsPage({
    super.key,
    required this.src,
    required this.dst,
    this.initialDate,
  });

  @override
  ConsumerState<SectorDetailsPage> createState() => _SectorDetailsPageState();
}

class _SectorDetailsPageState extends ConsumerState<SectorDetailsPage> {
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant SectorDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate && widget.initialDate != null) {
      setState(() {
        _selectedDate = widget.initialDate;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flightsAsync = ref.watch(allFlightsProvider);
    final agenciesAsync = ref.watch(agenciesStreamProvider);
    final src = widget.src;
    final dst = widget.dst;

    return AppLayout(
      activeRoute: '/sectors',
      disableScroll: true,
      child: flightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (allFlights) {
          return agenciesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (allAgencies) {
              final sectorFlights = allFlights
                  .where((f) => f.source == src && f.destination == dst)
                  .toList();

              if (sectorFlights.isEmpty) {
                return const Center(child: Text('No flights found for this sector.'));
              }

              // Create a map for quick agency deduction lookup
              final Map<String, double> agencyDeductions = {};
              for (var agency in allAgencies) {
                agencyDeductions[agency.name] = agency.comparisonDeduction;
              }

              // Unique agencies operating in this sector
              final sectorAgencies = sectorFlights
                  .map((f) => f.agencyName)
                  .where((a) => a.trim().isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              // Filter flights based on selected date & search query
              var filteredFlights = List<Flight>.from(sectorFlights);
              if (_selectedDate != null) {
                filteredFlights = filteredFlights
                    .where((f) => _matchesDate(f, _selectedDate!))
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                filteredFlights = filteredFlights.where((f) {
                  return f.airline.toLowerCase().contains(_searchQuery) ||
                      f.flightNumber.toLowerCase().contains(_searchQuery) ||
                      f.agencyName.toLowerCase().contains(_searchQuery) ||
                      f.date.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              final Set<String> uniqueDates = {};
              for (var f in filteredFlights) {
                uniqueDates.add(f.date);
              }

              final sortedDates = uniqueDates.toList()..sort(_compareDates);

              // Sort filteredFlights by date as well for the full records table
              filteredFlights.sort((a, b) => _compareDates(a.date, b.date));

              final Map<String, Agency> agencyMap = {for (var a in allAgencies) a.name: a};

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildComparisonCard(
                      context,
                      src,
                      dst,
                      sortedDates,
                      sectorAgencies,
                      filteredFlights,
                      sectorFlights,
                      agencyDeductions,
                      agencyMap,
                    ),
                    const SizedBox(height: 16),
                    _buildFullRecordsCard(filteredFlights, agencyDeductions, agencyMap, src, dst),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime? _parseFlightDate(String d) {
    const months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12
    };

    try {
      final cleaned = d.trim().replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ');
      final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      int? day;
      int? month;
      int? year;

      for (var p in parts) {
        final upper = p.toUpperCase();
        if (months.containsKey(upper)) {
          month = months[upper];
        } else {
          final val = int.tryParse(p);
          if (val != null) {
            if (val > 31) {
              year = val;
            } else if (day == null) {
              day = val;
            } else if (month == null && val <= 12) {
              month = val;
            } else {
              year ??= val;
            }
          }
        }
      }

      if (day != null && month != null) {
        return DateTime(year ?? 2024, month, day);
      }
    } catch (_) {}
    return null;
  }

  int _compareDates(String d1, String d2) {
    final dt1 = _parseFlightDate(d1) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dt2 = _parseFlightDate(d2) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return dt1.compareTo(dt2);
  }

  bool _matchesDate(Flight f, DateTime selected) {
    if (f.parsedDate != null) {
      if (f.parsedDate!.day == selected.day && f.parsedDate!.month == selected.month) {
        return true;
      }
    }

    final parsed = _parseFlightDate(f.date);
    if (parsed != null) {
      if (parsed.day == selected.day && parsed.month == selected.month) {
        return true;
      }
    }

    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final monthStr = months[selected.month - 1];
    final dateUpper = f.date.toUpperCase();
    final hasDay = dateUpper.contains(RegExp('\\b0?${selected.day}\\b'));
    final hasMonth = dateUpper.contains(monthStr);

    return hasDay && hasMonth;
  }

  Future<void> _pickDate(List<Flight> allSectorFlights) async {
    final picked = await FlightDatePickerDialog.show(
      context: context,
      selectedDate: _selectedDate,
      sectorFlights: allSectorFlights,
      matchesDate: _matchesDate,
      parseFlightDate: _parseFlightDate,
    );

    if (picked != null) {
      if (picked.year == 1970) {
        setState(() {
          _selectedDate = null;
        });
      } else {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }

  String _formatDateDisplay(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String? _getAirlineLogoPath(String airlineCode) {
    final code = airlineCode.trim().toUpperCase();
    if (code == 'IX') return 'assets/LOGO/IX.jpg';
    if (code == 'OV') return 'assets/LOGO/OV.jpg';
    if (code == '6E') return 'assets/LOGO/6E.png';
    if (code == 'FZ') return 'assets/LOGO/FZ.png';
    if (code == 'GF') return 'assets/LOGO/GF.png';
    if (code == 'J9') return 'assets/LOGO/J9.png';
    if (code == 'KU') return 'assets/LOGO/KU.png';
    if (code == 'QP') return 'assets/LOGO/QP.png';
    if (code == 'WY') return 'assets/LOGO/WY.png';
    if (code == 'XY') return 'assets/LOGO/XY.jpg';
    if (code == 'SV') return 'assets/LOGO/SV.png';
    if (code == 'SG') return 'assets/LOGO/SG.png';
    if (code == '3L' || code == 'G9') return 'assets/LOGO/3L and G9.png';
    return null;
  }

  Widget _buildFallbackLogo(String airline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        airline.isNotEmpty ? airline : 'FL',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildDatePickerButton(List<Flight> allSectorFlights) {
    final hasSelectedDate = _selectedDate != null;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: hasSelectedDate ? AppColors.primaryBlue.withValues(alpha: 0.08) : AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSelectedDate ? AppColors.primaryBlue : Colors.transparent,
          width: hasSelectedDate ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _pickDate(allSectorFlights),
            child: Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: hasSelectedDate ? 6 : 14,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: hasSelectedDate ? AppColors.primaryBlue : AppColors.iconBlueAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasSelectedDate
                        ? _formatDateDisplay(_selectedDate!)
                        : 'Select Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasSelectedDate ? FontWeight.bold : FontWeight.w500,
                      color: hasSelectedDate ? AppColors.primaryBlue : AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasSelectedDate)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, size: 16, color: Colors.redAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    String src,
    String dst,
    List<String> dates,
    List<String> agencies,
    List<Flight> displayFlights,
    List<Flight> allSectorFlights,
    Map<String, double> agencyDeductions,
    Map<String, Agency> agencyMap,
  ) {
    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                      onPressed: () => context.go('/sectors'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$src - $dst',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppStrings.airportNames[src] ?? src} - ${AppStrings.airportNames[dst] ?? dst}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.primaryBlue),
                      tooltip: 'Sync latest fares',
                      onPressed: () {
                        ref.invalidate(allFlightsProvider);
                      },
                    ),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDatePickerButton(allSectorFlights),
                    SizedBox(
                      width: 220,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.scaffoldBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search, color: AppColors.iconBlueAccent, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? InkWell(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.close, size: 16, color: AppColors.textGrey),
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (_selectedDate != null || _searchQuery.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Filter', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (displayFlights.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flight_takeoff, size: 48, color: AppColors.textGrey),
                    const SizedBox(height: 12),
                    Text(
                      _selectedDate != null
                          ? 'No flights found on ${_formatDateDisplay(_selectedDate!)} for this sector.'
                          : 'No flights found matching your filter.',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Show All Dates'),
                    ),
                  ],
                ),
              )
            else
              SectorComparisonTable(
                key: ValueKey('${_selectedDate?.toIso8601String()}_${dates.join(',')}_${displayFlights.length}'),
                dates: dates,
                agencies: agencies,
                flights: displayFlights,
                agencyDeductions: agencyDeductions,
                src: src,
                dst: dst,
                getAirlineLogoPath: _getAirlineLogoPath,
                buildFallbackLogo: _buildFallbackLogo,
                onFlightTap: (flight, adjustedPrice, ded) {
                  showFlightInquiryDialog(
                    context: context,
                    ref: ref,
                    flight: flight,
                    agency: agencyMap[flight.agencyName],
                    adjustedPrice: adjustedPrice,
                    deduction: ded,
                    src: src,
                    dst: dst,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullRecordsCard(
    List<Flight> flights,
    Map<String, double> agencyDeductions,
    Map<String, Agency> agencyMap,
    String src,
    String dst,
  ) {
    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text('Full market records (${flights.length} records)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(AppColors.cardBackground),
              columns: const [
                DataColumn(label: Text('Trust', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Agency', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Airline', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Flight', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Baggage', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Timing', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Marketed Fare', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Comparison Fare', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('B2B', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Seats', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: flights.map((f) {
                final deduction = agencyDeductions[f.agencyName] ?? 0.0;
                final comparisonFare = f.marketedPrice - deduction;

                return DataRow(
                  onSelectChanged: (_) {
                    showFlightInquiryDialog(
                      context: context,
                      ref: ref,
                      flight: f,
                      agency: agencyMap[f.agencyName],
                      adjustedPrice: comparisonFare,
                      deduction: deduction,
                      src: src,
                      dst: dst,
                    );
                  },
                  cells: [
                    const DataCell(Icon(Icons.star, color: Colors.green, size: 16)),
                    DataCell(Text(f.agencyName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(f.date)),
                    DataCell(Text(f.airline)),
                    DataCell(
                      f.via.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(f.flightNumber),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Via ${f.via}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Text(f.flightNumber),
                    ),
                    DataCell(Text(f.baggage)),
                    DataCell(Text(f.timing)),
                    DataCell(Text('₹${f.marketedPrice.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${comparisonFare.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    const DataCell(Text('—', style: TextStyle(color: AppColors.textGrey))),
                    const DataCell(Text('—', style: TextStyle(color: AppColors.textGrey))),
                    DataCell(Text(f.seats)),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

}

