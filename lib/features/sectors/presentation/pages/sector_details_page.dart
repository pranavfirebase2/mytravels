import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../flights/presentation/providers/flight_providers.dart';
import '../../../flights/domain/entities/flight.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../../../agency/domain/entities/agency.dart';

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
              final sortedAgencies = uniqueAgencies.toList()..sort();
              
              // Sort sectorFlights by date as well for the full records table
              sectorFlights.sort((a, b) => _compareDates(a.date, b.date));

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildSummaryCards(lowestFare, uniqueAgencies.length, uniqueDates.length),
                    const SizedBox(height: 16),
                    _buildComparisonCard(context, sortedDates, sortedAgencies, sectorFlights, agencyDeductions),
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

  Widget _buildHeader(BuildContext context) {
    return Card(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/sectors'),
                      tooltip: 'Back to Sectors',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Text(src, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward_outlined, color: AppColors.textGrey, size: 20),
                    ),
                    Text(dst, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Market comparison by origin + final destination', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  onPressed: () => context.pop(),
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
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double? lowestFare, int agenciesCount, int datesCount) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Lowest comparison fare', lowestFare != null ? '₹${lowestFare.toInt()}' : '—')),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Agencies compared', '$agenciesCount')),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Dates checked', '$datesCount')),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('View', 'Starred')),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, List<String> dates, List<String> agencies, List<Flight> flights, Map<String, double> agencyDeductions) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Agency comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Text('Dates', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    const SizedBox(width: 8),
                    _buildDatePicker(context),
                    const SizedBox(width: 16),
                    _buildToggleButton('Compare', isSelected: true),
                    const SizedBox(width: 8),
                    _buildToggleButton('Starred', isSelected: false),
                    const SizedBox(width: 8),
                    _buildToggleButton('All', isSelected: false),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Lowest comparison fare is placed first. Agency-specific comparison deductions are applied below; original marketed fares remain unchanged.', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
            const SizedBox(height: 16),
            
            // Agency Adjustments Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  const Text('Agency Master adjustments:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  ...agencies.map((agency) {
                    final ded = agencyDeductions[agency] ?? 0;
                    if (ded == 0) return const SizedBox.shrink();
                    return Text('$agency - ₹${ded.toInt()}', style: const TextStyle(fontSize: 13, color: AppColors.textBlack));
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Table(
                border: TableBorder.symmetric(inside: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1))),
                columnWidths: {
                  0: const FlexColumnWidth(1),
                  for (var i = 1; i <= agencies.length; i++) i: const FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.cardBackground),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('Travel date', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...agencies.map((agency) => Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Flexible(child: Text(agency, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )),
                    ],
                  ),
                  ...dates.map((date) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...agencies.map((agency) {
                          // Find flights for this date and agency
                          final flightOptions = flights.where((f) => f.date == date && f.agencyName == agency).toList();
                          if (flightOptions.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(child: Text('—', style: TextStyle(color: AppColors.textGrey))),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: flightOptions.map((f) {
                                final ded = agencyDeductions[f.agencyName] ?? 0;
                                final adjustedPrice = f.marketedPrice - ded;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Logo or fallback
                                            Builder(
                                              builder: (context) {
                                                final logoPath = _getAirlineLogoPath(f.airline);
                                                if (logoPath != null) {
                                                  return Image.asset(
                                                    logoPath,
                                                    width: 40,
                                                    height: 24,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return _buildFallbackLogo(f.airline);
                                                    },
                                                  );
                                                }
                                                return _buildFallbackLogo(f.airline);
                                              },
                                            ),
                                            // Price
                                            Text(
                                              '₹${adjustedPrice.toInt()}',
                                              style: TextStyle(color: Colors.purple.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text('$src - $dst', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBlack)),
                                        const SizedBox(height: 2),
                                        Text('${f.airline} - ${f.flightNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                        const SizedBox(height: 2),
                                        Text(f.baggage.isNotEmpty ? f.baggage : 'No baggage info', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
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

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        await showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryBlue,
                  onPrimary: AppColors.white,
                  onSurface: AppColors.textBlack,
                ),
              ),
              child: child!,
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryBlue),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.calendar_today, size: 14, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Select Date Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue : AppColors.textGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? AppColors.white : AppColors.textBlack,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
