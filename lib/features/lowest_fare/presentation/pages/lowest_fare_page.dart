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
    return AppLayout(
      activeRoute: '/lowest-fare',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          _buildSearchCard(),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildDataTableCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Lowest Fare Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Searches the complete retained market database. No records are removed by this search.', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonLightGrey,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => context.go('/sectors'),
              child: const Text('← Back to Markets'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search DXB, CCJ DXB, DMM...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textGrey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    items: _filters.map((filter) => DropdownMenuItem(value: filter, child: Text(filter))).toList(),
                    onChanged: (val) => setState(() => _selectedFilter = val ?? _selectedFilter),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              onPressed: () {},
              child: const Text('Find Lowest'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildMetricCard('Results', '75'),
        const SizedBox(width: 16),
        _buildMetricCard('View', 'Next 7 days'),
        const SizedBox(width: 16),
        _buildMetricCard('Lowest', '₹10,200'),
        const SizedBox(width: 16),
        _buildMetricCard('Starred lowest', '₹10,200'),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Expanded(
      child: Card(
        color: AppColors.tableHeader,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textBlack, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTableCard() {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.tableHeaderLight),
          columnSpacing: 24,
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
                DataCell(Text(row['market'], style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(row['date'])),
                DataCell(Row(
                  children: [
                    if (row['isStarred'] == true) const Icon(Icons.star, color: AppColors.successGreen, size: 16),
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
    );
  }
}
