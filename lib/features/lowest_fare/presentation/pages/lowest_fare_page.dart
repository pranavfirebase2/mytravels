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

class LowestFarePage extends ConsumerStatefulWidget {
  const LowestFarePage({super.key});

  @override
  ConsumerState<LowestFarePage> createState() => _LowestFarePageState();
}

class _LowestFarePageState extends ConsumerState<LowestFarePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Entire data';
  int _scrollLimit = 25;
  int _totalAvailableRanked = 0;
  bool _isLoadingMore = false;

  final List<String> _filters = [
    'Entire data',
    'Next 2 days',
    'Next 3 days',
    'Next 7 days',
    'Next 15 days',
    'Next 30 days',
    'This month',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _scrollLimit = 25;
        _isLoadingMore = false;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 350) {
        _loadMore();
      }
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    if (_scrollLimit < _totalAvailableRanked) {
      setState(() {
        _isLoadingMore = true;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _scrollLimit = (_scrollLimit + 25).clamp(0, _totalAvailableRanked);
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _parseFlightDate(String dateStr) {
    try {
      final cleaned = dateStr.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').trim();
      final parts = cleaned.split(RegExp(r'\s+'));
      const months = {
        'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
        'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
      };
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
        return DateTime(year ?? DateTime.now().year, month, day);
      }
    } catch (_) {}
    return null;
  }

  bool _isInDateWindow(
    Flight f,
    String filter,
    DateTime today,
    bool hasFutureFlights,
    DateTime? minFlightDate,
  ) {
    if (filter == 'Entire data') return true;

    final flightDate = f.parsedDate ?? _parseFlightDate(f.date);
    if (flightDate == null) return true;

    if (filter == 'This month') {
      return flightDate.month == today.month && flightDate.year == today.year;
    }

    int days = 7;
    if (filter == 'Next 2 days') {
      days = 2;
    } else if (filter == 'Next 3 days') {
      days = 3;
    } else if (filter == 'Next 7 days') {
      days = 7;
    } else if (filter == 'Next 15 days') {
      days = 15;
    } else if (filter == 'Next 30 days') {
      days = 30;
    }

    if (hasFutureFlights) {
      final endWindow = today.add(Duration(days: days));
      return !flightDate.isBefore(today) && !flightDate.isAfter(endWindow);
    } else if (minFlightDate != null) {
      final sampleRef = DateTime(minFlightDate.year, minFlightDate.month, minFlightDate.day);
      final sampleEnd = sampleRef.add(Duration(days: days));
      return !flightDate.isBefore(sampleRef) && !flightDate.isAfter(sampleEnd);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final flightsAsync = ref.watch(allFlightsProvider);
    final agenciesAsync = ref.watch(agenciesStreamProvider);

    return AppLayout(
      activeRoute: '/lowest-fare',
      disableScroll: true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.axis == Axis.vertical) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 350) {
              _loadMore();
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(context, isMobile),
              const SizedBox(height: 16),
              _buildSearchCard(isMobile),
              const SizedBox(height: 16),
              flightsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('Error loading flights: $err', style: const TextStyle(color: AppColors.errorRed)),
                  ),
                ),
                data: (allFlights) {
                  return agenciesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('Error loading agencies: $err', style: const TextStyle(color: AppColors.errorRed)),
                      ),
                    ),
                    data: (allAgencies) {
                      return _buildContent(allFlights, allAgencies, isMobile);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Flight> allFlights, List<dynamic> allAgencies, bool isMobile) {
    if (allFlights.isEmpty) {
      return Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              const Icon(Icons.flight_outlined, size: 54, color: AppColors.textGrey),
              const SizedBox(height: 14),
              const Text(
                'No flight records in database',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack),
              ),
              const SizedBox(height: 6),
              const Text(
                'Import market fare files to start searching lowest fares.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => context.go('/import'),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Go to Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    // Build agency maps
    final Map<String, double> agencyDeductions = {};
    final Map<String, bool> agencyStarredMap = {};
    final Map<String, Agency> agencyMap = {};
    for (var a in allAgencies) {
      if (a is Agency) {
        agencyMap[a.name] = a;
        agencyDeductions[a.name] = a.comparisonDeduction;
        agencyStarredMap[a.name] = a.isStarred;
      }
    }

    // Pre-calculate date references once (O(N) instead of O(N^2))
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool hasFutureFlights = false;
    DateTime? minFlightDate;

    if (_selectedFilter != 'Entire data') {
      for (final fl in allFlights) {
        final d = fl.parsedDate ?? _parseFlightDate(fl.date);
        if (d != null) {
          if (!d.isBefore(today)) {
            hasFutureFlights = true;
          }
          if (minFlightDate == null || d.isBefore(minFlightDate)) {
            minFlightDate = d;
          }
        }
      }
    }

    // Filter by date window and comprehensive multi-token search query
    final rawQuery = _searchQuery.trim().toLowerCase();
    final queryTokens = rawQuery
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final matchingFlights = allFlights.where((f) {
      if (!_isInDateWindow(f, _selectedFilter, today, hasFutureFlights, minFlightDate)) {
        return false;
      }

      if (queryTokens.isNotEmpty) {
        final src = f.source.toLowerCase();
        final dst = f.destination.toLowerCase();
        final agency = f.agencyName.toLowerCase();
        final airline = f.airline.toLowerCase();
        final airlineName = (AppStrings.airlineNames[f.airline] ?? '').toLowerCase();
        final flightNum = f.flightNumber.toLowerCase();
        final date = f.date.toLowerCase();
        final timing = f.timing.toLowerCase();
        final baggage = f.baggage.toLowerCase();
        final seats = f.seats.toLowerCase();
        final price = f.marketedPrice.toInt().toString();

        final airportSrc = (AppStrings.airportNames[f.source] ?? '').toLowerCase();
        final airportDst = (AppStrings.airportNames[f.destination] ?? '').toLowerCase();

        // City & Airport aliases for seamless matching
        String aliases = '';
        if (src == 'ccj' || dst == 'ccj') aliases += ' calicut kozhikode';
        if (src == 'cok' || dst == 'cok') aliases += ' kochi cochin';
        if (src == 'trv' || dst == 'trv') aliases += ' trivandrum thiruvananthapuram';
        if (src == 'dxb' || dst == 'dxb') aliases += ' dubai';
        if (src == 'shj' || dst == 'shj') aliases += ' sharjah';
        if (src == 'auh' || dst == 'auh') aliases += ' abu dhabi';
        if (src == 'bom' || dst == 'bom') aliases += ' mumbai bombay';
        if (src == 'blr' || dst == 'blr') aliases += ' bangalore bengaluru';

        final searchable = '$src $dst $airportSrc $airportDst $src$dst $src $dst $airline $airlineName $airline$flightNum $airline $flightNum $flightNum $agency $date $timing $baggage $seats $price$aliases';

        for (final token in queryTokens) {
          if (!searchable.contains(token)) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Map to ranked items with adjusted fare
    final List<_RankedFlightItem> rankedItems = [];
    for (var f in matchingFlights) {
      final ded = agencyDeductions[f.agencyName] ?? 0.0;
      final adjusted = f.marketedPrice - ded;
      final isStarred = agencyStarredMap[f.agencyName] ?? false;

      rankedItems.add(
        _RankedFlightItem(
          flight: f,
          deduction: ded,
          adjustedPrice: adjusted,
          isStarred: isStarred,
        ),
      );
    }

    // Sort by adjusted price ascending (Lowest fare first)
    rankedItems.sort((a, b) => a.adjustedPrice.compareTo(b.adjustedPrice));

    _totalAvailableRanked = rankedItems.length;

    // Summary metrics
    final totalResults = rankedItems.length;
    final lowestFareStr = rankedItems.isNotEmpty ? '₹${rankedItems.first.adjustedPrice.toInt()}' : '—';
    final starredItems = rankedItems.where((item) => item.isStarred).toList();
    final starredLowestStr = starredItems.isNotEmpty ? '₹${starredItems.first.adjustedPrice.toInt()}' : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCards(isMobile, totalResults, lowestFareStr, starredLowestStr),
        const SizedBox(height: 16),
        _buildDataTableCard(rankedItems, agencyMap, isMobile),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isMobile) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lowest Fare Search',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.buttonLightGrey,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => context.go('/sectors'),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Markets'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Searches the complete database and ranks lowest fares by comparison deduction.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Lowest Fare Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'Searches the complete database and ranks lowest fares by comparison deduction.',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonLightGrey,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.go('/sectors'),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Markets'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchCard(bool isMobile) {
    if (isMobile) {
      return Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search DXB, CCJ DXB, Airline, Agency...',
                  hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryBlue),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          items: _filters
                              .map((filter) => DropdownMenuItem(
                                    value: filter,
                                    child: Text(filter, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedFilter = val;
                                _scrollLimit = 25;
                                _isLoadingMore = false;
                              });
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          // Triggers search refresh
                          setState(() {});
                        },
                        child: const Text('Find Lowest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search DXB, CCJ DXB, Airline, Agency...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryBlue),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    items: _filters
                        .map((filter) => DropdownMenuItem(
                              value: filter,
                              child: Text(filter, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedFilter = val;
                          _scrollLimit = 25;
                          _isLoadingMore = false;
                        });
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Find Lowest', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile, int totalResults, String lowestFare, String starredLowest) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildMetricCard('Results', '$totalResults', Icons.bar_chart_rounded),
              const SizedBox(width: 12),
              _buildMetricCard('View Window', _selectedFilter, Icons.date_range_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard('Lowest Fare', lowestFare, Icons.trending_down_rounded, valueColor: AppColors.headerDark),
              const SizedBox(width: 12),
              _buildMetricCard('Starred Lowest', starredLowest, Icons.star_rounded, valueColor: Colors.amber[800]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildMetricCard('Results', '$totalResults', Icons.bar_chart_rounded),
        const SizedBox(width: 14),
        _buildMetricCard('View Window', _selectedFilter, Icons.date_range_rounded),
        const SizedBox(width: 14),
        _buildMetricCard('Lowest Fare', lowestFare, Icons.trending_down_rounded, valueColor: AppColors.headerDark),
        const SizedBox(width: 14),
        _buildMetricCard('Starred Lowest', starredLowest, Icons.star_rounded, valueColor: Colors.amber[800]),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, {Color? valueColor}) {
    return Expanded(
      child: Card(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.buttonLightGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: AppColors.buttonGrey, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textBlack,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTableCard(List<_RankedFlightItem> items, Map<String, Agency> agencyMap, bool isMobile) {
    final displayedItems = items.take(_scrollLimit).toList();
    final hasMore = displayedItems.length < items.length;

    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textGrey),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No lowest fares matching "$_searchQuery"'
                          : 'No flights found in $_selectedFilter window',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                    ),
                    const SizedBox(height: 6),
                    const Text('Try changing the search keyword or selecting "Entire data"', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedFilter = 'Entire data';
                          _scrollLimit = 25;
                          _isLoadingMore = false;
                        });
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      },
                      child: const Text('Reset Search & Filter'),
                    ),
                  ],
                ),
              )
            else ...[
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: const [
                      Icon(Icons.swipe_left_rounded, size: 16, color: AppColors.textGrey),
                      SizedBox(width: 6),
                      Text(
                        'Swipe horizontally to view all flight columns',
                        style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.tableHeaderLight),
                  columnSpacing: isMobile ? 16 : 22,
                  columns: const [
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Market', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Agency', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Airline', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Flight', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Full Route', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Timing', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Baggage', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Seats', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Marketed', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Deduction', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Adjusted', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: displayedItems.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final item = entry.value;
                    final f = item.flight;
                    final isTop3 = rank <= 3;

                    return DataRow(
                      cells: [
                        DataCell(
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0.5,
                            ),
                            onPressed: () {
                              showFlightInquiryDialog(
                                context: context,
                                ref: ref,
                                flight: f,
                                agency: agencyMap[f.agencyName],
                                adjustedPrice: item.adjustedPrice,
                                deduction: item.deduction,
                                src: f.source,
                                dst: f.destination,
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_rounded, size: 12),
                            label: const Text('Connect', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTop3
                                  ? (rank == 1
                                      ? Colors.amber.withValues(alpha: 0.25)
                                      : Colors.grey.withValues(alpha: 0.15))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rank == 1 ? Colors.amber[900] : AppColors.textBlack,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${f.source} → ${f.destination}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          onTap: () => context.go('/sector/${f.source}/${f.destination}'),
                        ),
                        DataCell(Text(f.date)),
                        DataCell(
                          InkWell(
                            onTap: () {
                              showFlightInquiryDialog(
                                context: context,
                                ref: ref,
                                flight: f,
                                agency: agencyMap[f.agencyName],
                                adjustedPrice: item.adjustedPrice,
                                deduction: item.deduction,
                                src: f.source,
                                dst: f.destination,
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.isStarred) ...[
                                  Icon(Icons.star_rounded, color: Colors.amber[700], size: 18),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  f.agencyName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(f.airline)),
                        DataCell(Text(f.flightNumber)),
                        DataCell(Text('${f.source} → ${f.destination}')),
                        DataCell(Text(f.timing.isNotEmpty ? f.timing : '—')),
                        DataCell(Text(f.baggage.isNotEmpty ? f.baggage : '—')),
                        DataCell(Text(f.seats.isNotEmpty ? f.seats : '—')),
                        DataCell(Text('₹${f.marketedPrice.toInt()}')),
                        DataCell(Text(item.deduction > 0 ? '₹${item.deduction.toInt()}' : '—')),
                        DataCell(
                          Text(
                            '₹${item.adjustedPrice.toInt()}',
                            style: const TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Scroll Loading Footer
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Center(
                  child: _isLoadingMore
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading more flights (${displayedItems.length} of ${items.length})...',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        )
                      : (hasMore
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.35)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _loadMore,
                              icon: const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.primaryBlue),
                              label: Text(
                                'Showing ${displayedItems.length} of ${items.length} flights · Scroll down to load more',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            )
                          : Text(
                              'Showing all ${items.length} lowest fare flights',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankedFlightItem {
  final Flight flight;
  final double deduction;
  final double adjustedPrice;
  final bool isStarred;

  _RankedFlightItem({
    required this.flight,
    required this.deduction,
    required this.adjustedPrice,
    required this.isStarred,
  });
}
