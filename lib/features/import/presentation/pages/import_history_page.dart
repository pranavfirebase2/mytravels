import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../domain/entities/import_history.dart';
import '../providers/import_history_providers.dart';

class ImportHistoryPage extends ConsumerStatefulWidget {
  const ImportHistoryPage({super.key});

  @override
  ConsumerState<ImportHistoryPage> createState() => _ImportHistoryPageState();
}

class _ImportHistoryPageState extends ConsumerState<ImportHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedModeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hour24 = local.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour12:$minute $period';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '';
  }

  void _showDeleteConfirmDialog(ImportHistory item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text('Delete History Entry', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to remove the import record for "${item.agencyName}"? (Flight data will remain unaffected).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: AppColors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(importHistoryDataSourceProvider).deleteHistoryItem(item.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History entry deleted'), duration: Duration(seconds: 2)),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text('Clear All History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to clear the entire import history? (Imported flights in the system will NOT be deleted).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: AppColors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(importHistoryDataSourceProvider).clearAllHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import history cleared'), duration: Duration(seconds: 2)),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final historyAsync = ref.watch(importHistoryStreamProvider);

    return AppLayout(
      activeRoute: '/import',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          _buildHeaderCard(context, isMobile),
          const SizedBox(height: 16),

          historyAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Card(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text('Error loading history: $err', style: const TextStyle(color: AppColors.errorRed)),
                ),
              ),
            ),
            data: (allHistory) {
              if (allHistory.isEmpty) {
                return _buildEmptyState(context);
              }

              // Filter history
              final filtered = allHistory.where((item) {
                final matchQuery = _searchQuery.isEmpty ||
                    item.agencyName.toLowerCase().contains(_searchQuery) ||
                    item.importMode.toLowerCase().contains(_searchQuery) ||
                    item.sectors.any((s) => s.toLowerCase().contains(_searchQuery));

                final matchMode = _selectedModeFilter == 'All' ||
                    (_selectedModeFilter == 'Sector' && item.importMode.toLowerCase().contains('sector')) ||
                    (_selectedModeFilter == 'Full Reset' && item.importMode.toLowerCase().contains('full')) ||
                    (_selectedModeFilter == 'Append' && item.importMode.toLowerCase().contains('append'));

                return matchQuery && matchMode;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick stats
                  _buildStatsRow(allHistory, isMobile),
                  const SizedBox(height: 16),

                  // Search and Mode filters
                  _buildFilterBar(isMobile),
                  const SizedBox(height: 16),

                  // History list
                  if (filtered.isEmpty)
                    Card(
                      color: AppColors.cardBackground,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text('No import logs match your filter criteria.', style: TextStyle(color: AppColors.textGrey)),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _buildHistoryCard(filtered[i], isMobile),
                    ),
                ],
              );
            },
          ),
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
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.buttonGrey),
              tooltip: 'Back to Import',
              onPressed: () => context.go('/import'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Import History',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Audit log of agency imports, replace modes, and flight counts',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showClearAllConfirmDialog,
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text(isMobile ? 'Clear' : 'Clear History', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<ImportHistory> list, bool isMobile) {
    final now = DateTime.now();
    final todayCount = list.where((h) {
      final t = h.timestamp.toLocal();
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).length;

    final totalFlights = list.fold<int>(0, (sum, item) => sum + item.flightCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 24) / 3;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Total Imports',
              value: '${list.length}',
              subtitle: '$totalFlights flights processed',
              icon: Icons.history_rounded,
              color: AppColors.primaryBlue,
              width: cardWidth,
            ),
            _buildStatCard(
              title: "Today's Imports",
              value: '$todayCount',
              subtitle: todayCount > 0 ? 'Active updates today' : 'No imports today yet',
              icon: Icons.today_rounded,
              color: Colors.green,
              width: cardWidth,
            ),
            if (!isMobile)
              _buildStatCard(
                title: 'Latest Agency',
                value: list.first.agencyName,
                subtitle: _timeAgo(list.first.timestamp),
                icon: Icons.business_rounded,
                color: Colors.indigo,
                width: cardWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by agency or sector...',
                      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.buttonGrey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.scaffoldBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Sector', 'Full Reset', 'Append'].map((mode) {
                        final isSelected = _selectedModeFilter == mode;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(mode),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedModeFilter = mode);
                            },
                            selectedColor: AppColors.primaryBlue.withValues(alpha: 0.18),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryBlue : AppColors.textBlack,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by agency or sector...',
                        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.buttonGrey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppColors.scaffoldBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: ['All', 'Sector', 'Full Reset', 'Append'].map((mode) {
                      final isSelected = _selectedModeFilter == mode;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: ChoiceChip(
                          label: Text(mode),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedModeFilter = mode);
                          },
                          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primaryBlue : AppColors.textBlack,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryCard(ImportHistory item, bool isMobile) {
    // Mode color & icon
    final Color modeBgColor;
    final Color modeTextColor;
    final IconData modeIcon;
    final String modeLabel;

    final lowerMode = item.importMode.toLowerCase();
    if (lowerMode.contains('full')) {
      modeBgColor = Colors.orange.withValues(alpha: 0.12);
      modeTextColor = Colors.deepOrange.shade800;
      modeIcon = Icons.refresh_rounded;
      modeLabel = 'Full Agency Reset';
    } else if (lowerMode.contains('sector')) {
      modeBgColor = AppColors.primaryBlue.withValues(alpha: 0.12);
      modeTextColor = AppColors.primaryBlue;
      modeIcon = Icons.swap_horiz_rounded;
      modeLabel = 'Sector-wise Replace';
    } else {
      modeBgColor = Colors.green.withValues(alpha: 0.12);
      modeTextColor = const Color(0xFF1B5E20);
      modeIcon = Icons.add_circle_outline_rounded;
      modeLabel = 'Append Only';
    }

    final ago = _timeAgo(item.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Agency Avatar + Name + Mode Chip + Delete Icon
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.agencyName.isNotEmpty ? item.agencyName[0].toUpperCase() : 'A',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.agencyName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textBlack),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(item.timestamp),
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                        ),
                        if (ago.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(ago, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textGrey),
                tooltip: 'Delete entry',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showDeleteConfirmDialog(item),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Row 2: Mode Badge & Flight Count
          Row(
            children: [
              // Mode badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: modeBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(modeIcon, size: 13, color: modeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      modeLabel,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: modeTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Flight count chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flight_takeoff_rounded, size: 13, color: AppColors.buttonGrey),
                    const SizedBox(width: 4),
                    Text(
                      '${item.flightCount} Flights',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.buttonGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Sectors chips if available
          if (item.sectors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.sectors.map((sec) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    sec,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.buttonGrey),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Import History Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Whenever an agency flight message is imported, a history record with agency name, mode, and count will be logged here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => context.go('/import'),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Go to Import Page', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
