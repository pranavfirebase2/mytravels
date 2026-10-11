import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../flights/presentation/providers/flight_providers.dart';
import '../../../flights/domain/entities/flight.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../widgets/sector_comparison_table.dart';

class SectorDetailsPage extends ConsumerWidget {
  final String src;
  final String dst;

  const SectorDetailsPage({super.key, required this.src, required this.dst});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightsAsync = ref.watch(allFlightsProvider);
    final agenciesAsync = ref.watch(agenciesStreamProvider);

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

              // Extract unique agencies and dates
              final Set<String> uniqueAgencies = {};
              final Set<String> uniqueDates = {};
              
              double? lowestFare;

              for (var f in sectorFlights) {
                uniqueAgencies.add(f.agencyName);
                uniqueDates.add(f.date);
                
                final deduction = agencyDeductions[f.agencyName] ?? 0.0;
                final comparisonFare = f.marketedPrice - deduction;

                if (lowestFare == null || comparisonFare < lowestFare) {
                  lowestFare = comparisonFare;
                }
              }

              final sortedDates = uniqueDates.toList()..sort(_compareDates);
              final sortedAgencies = uniqueAgencies.where((a) => a.trim().isNotEmpty).toList()..sort();
              
              // Sort sectorFlights by date as well for the full records table
              sectorFlights.sort((a, b) => _compareDates(a.date, b.date));

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    _buildComparisonCard(context, src, dst, sortedDates, sortedAgencies, sectorFlights, agencyDeductions),
                    const SizedBox(height: 16),
                    _buildFullRecordsCard(sectorFlights, agencyDeductions),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  int _compareDates(String d1, String d2) {
    const months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12
    };

    DateTime parseDate(String d) {
      try {
        final parts = d.trim().split(' ');
        if (parts.length >= 2) {
          final day = int.parse(parts[0]);
          final month = months[parts[1].toUpperCase()] ?? 1;
          return DateTime(2024, month, day); // Dummy year for sorting
        }
      } catch (_) {}
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return parseDate(d1).compareTo(parseDate(d2));
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



  Widget _buildComparisonCard(BuildContext context, String src, String dst, List<String> dates, List<String> agencies, List<Flight> flights, Map<String, double> agencyDeductions) {
    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                      onPressed: () => context.go('/sectors'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () => context.go('/sectors'),
                      child: const Text('All Sectors'),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$src - $dst',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            '(${AppStrings.airportNames[src] ?? src} - ${AppStrings.airportNames[dst] ?? dst})',
                            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: 250,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.scaffoldBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: AppColors.iconBlueAccent, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectorComparisonTable(
              dates: dates,
              agencies: agencies,
              flights: flights,
              agencyDeductions: agencyDeductions,
              src: src,
              dst: dst,
              getAirlineLogoPath: _getAirlineLogoPath,
              buildFallbackLogo: _buildFallbackLogo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullRecordsCard(List<Flight> flights, Map<String, double> agencyDeductions) {
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
                  cells: [
                    const DataCell(Icon(Icons.star, color: Colors.green, size: 16)),
                    DataCell(Text(f.agencyName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(f.date)),
                    DataCell(Text(f.airline)),
                    DataCell(Text(f.flightNumber)),
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
