import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_layout.dart';

class LowestFarePage extends StatefulWidget {
  const LowestFarePage({super.key});

  @override
  State<LowestFarePage> createState() => _LowestFarePageState();
}

class _LowestFarePageState extends State<LowestFarePage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Next 7 days';

  final List<String> _filters = [
    'Next 2 days',
    'Next 3 days',
    'Next 7 days',
    'Next 15 days',
    'Next 30 days',
    'This month',
    'Entire data'
  ];

  final List<Map<String, dynamic>> _dummyData = [
    {'rank': 1, 'market': 'CCJ → MCT', 'date': '11 OCT', 'agency': 'Fly Creative', 'isStarred': true, 'airline': 'OV', 'flight': '774', 'fullRoute': 'CCJ → MCT', 'timing': '—', 'baggage': '5 KG', 'seats': '2', 'marketed': '₹10,200', 'deduction': '—', 'adjusted': '₹10,200'},
    {'rank': 2, 'market': 'CCJ → MCT', 'date': '13 OCT', 'agency': 'Fly Creative', 'isStarred': true, 'airline': 'IX', 'flight': '774', 'fullRoute': 'CCJ → MCT', 'timing': '—', 'baggage': '10 KG', 'seats': '—', 'marketed': '₹11,000', 'deduction': '—', 'adjusted': '₹11,000'},
    {'rank': 3, 'market': 'CCJ → MCT', 'date': '12 OCT', 'agency': 'Fly Creative', 'isStarred': true, 'airline': 'WY', 'flight': '774', 'fullRoute': 'CCJ → MCT', 'timing': '—', 'baggage': '10 KG', 'seats': '2', 'marketed': '₹11,200', 'deduction': '—', 'adjusted': '₹11,200'},
    {'rank': 4, 'market': 'CCJ → MCT', 'date': '14 OCT', 'agency': 'Fly Creative', 'isStarred': true, 'airline': 'WY', 'flight': '774', 'fullRoute': 'CCJ → MCT', 'timing': '—', 'baggage': '10 KG', 'seats': '—', 'marketed': '₹11,200', 'deduction': '—', 'adjusted': '₹11,200'},
    {'rank': 5, 'market': 'CCJ → MCT', 'date': '15 OCT', 'agency': 'Fly Creative', 'isStarred': true, 'airline': 'IX', 'flight': '774', 'fullRoute': 'CCJ → MCT', 'timing': '—', 'baggage': '—', 'seats': '—', 'marketed': '₹11,200', 'deduction': '—', 'adjusted': '₹11,200'},
    {'rank': 6, 'market': 'CCJ → MCT', 'date': '15 OCT', 'agency': 'Fly Creative', 'isStarred': true, 'airline': 'WY', 'flight': '774', 'fullRoute': 'CCJ → MCT', 'timing': '—', 'baggage': '10 KG', 'seats': '—', 'marketed': '₹12,200', 'deduction': '—', 'adjusted': '₹12,200'},
    {'rank': 7, 'market': 'CCJ → SLL', 'date': '13 OCT', 'agency': 'Fly Creative', 'isStarred': true, 'airline': 'IX', 'flight': '774', 'fullRoute': 'CCJ → SLL', 'timing': '—', 'baggage': '10 KG', 'seats': '1', 'marketed': '₹15,700', 'deduction': '—', 'adjusted': '₹15,700'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return AppLayout(
      activeRoute: '/lowest-fare',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(context, isMobile),
          const SizedBox(height: 16),
          _buildSearchCard(isMobile),
          const SizedBox(height: 16),
          _buildSummaryCards(isMobile),
          const SizedBox(height: 16),
          _buildDataTableCard(isMobile),
        ],
      ),
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
                    'Searches the complete retained market database. No records are removed by this search.',
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
                          'Searches the complete retained market database. No records are removed by this search.',
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
                  hintText: 'Search DXB, CCJ DXB, DMM...',
                  hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryBlue),
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
                          onChanged: (val) => setState(() => _selectedFilter = val ?? _selectedFilter),
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
                        onPressed: () {},
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
                  hintText: 'Search DXB, CCJ DXB, DMM...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryBlue),
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
                    onChanged: (val) => setState(() => _selectedFilter = val ?? _selectedFilter),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
              child: const Text('Find Lowest', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildMetricCard('Results', '75', Icons.bar_chart_rounded),
              const SizedBox(width: 12),
              _buildMetricCard('View Window', _selectedFilter, Icons.date_range_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard('Lowest Fare', '₹10,200', Icons.trending_down_rounded, valueColor: AppColors.headerDark),
              const SizedBox(width: 12),
              _buildMetricCard('Starred Lowest', '₹10,200', Icons.star_rounded, valueColor: Colors.amber[800]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildMetricCard('Results', '75', Icons.bar_chart_rounded),
        const SizedBox(width: 14),
        _buildMetricCard('View Window', _selectedFilter, Icons.date_range_rounded),
        const SizedBox(width: 14),
        _buildMetricCard('Lowest Fare', '₹10,200', Icons.trending_down_rounded, valueColor: AppColors.headerDark),
        const SizedBox(width: 14),
        _buildMetricCard('Starred Lowest', '₹10,200', Icons.star_rounded, valueColor: Colors.amber[800]),
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

  Widget _buildDataTableCard(bool isMobile) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                columnSpacing: isMobile ? 18 : 24,
                columns: const [
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
                rows: _dummyData.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row['rank'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(row['market'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue))),
                      DataCell(Text(row['date'])),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (row['isStarred'] == true) const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(row['agency'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      DataCell(Text(row['airline'])),
                      DataCell(Text(row['flight'])),
                      DataCell(Text(row['fullRoute'])),
                      DataCell(Text(row['timing'])),
                      DataCell(Text(row['baggage'])),
                      DataCell(Text(row['seats'])),
                      DataCell(Text(row['marketed'])),
                      DataCell(Text(row['deduction'])),
                      DataCell(Text(row['adjusted'], style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
