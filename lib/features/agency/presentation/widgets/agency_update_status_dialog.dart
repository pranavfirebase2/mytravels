import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/agency_update_status_provider.dart';

class AgencyUpdateStatusDialog extends ConsumerStatefulWidget {
  const AgencyUpdateStatusDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AgencyUpdateStatusDialog(),
    );
  }

  @override
  ConsumerState<AgencyUpdateStatusDialog> createState() => _AgencyUpdateStatusDialogState();
}

class _AgencyUpdateStatusDialogState extends ConsumerState<AgencyUpdateStatusDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All'; // 'All', 'Updated', 'Needs Update'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'No updates recorded yet';
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = !DateTime(local.year, local.month, local.day).isBefore(today);

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final hour24 = local.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    if (isToday) {
      return 'Today at $hour12:$minute $period';
    } else {
      return '$day $month ${local.year}, $hour12:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ref.watch(agencyUpdateStatusesProvider);
    final outdatedCount = statuses.where((s) => !s.isUpdatedToday).length;
    final updatedCount = statuses.where((s) => s.isUpdatedToday).length;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = statuses.where((item) {
      final matchQuery = query.isEmpty || item.agency.name.toLowerCase().contains(query);
      final matchFilter = _filter == 'All' ||
          (_filter == 'Updated' && item.isUpdatedToday) ||
          (_filter == 'Needs Update' && !item.isUpdatedToday);
      return matchQuery && matchFilter;
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: outdatedCount > 0
                  ? Colors.red.withValues(alpha: 0.12)
                  : Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_rounded,
              color: outdatedCount > 0 ? AppColors.errorRed : Colors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agency Update Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Replace All (Daily Reset) Tracker • 10:30 AM Cutoff',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.buttonGrey),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Summary Chips
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _filter = _filter == 'Updated' ? 'All' : 'Updated'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: _filter == 'Updated' ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: _filter == 'Updated' ? 0.8 : 0.3),
                          width: _filter == 'Updated' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            '$updatedCount Updated',
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _filter = _filter == 'Needs Update' ? 'All' : 'Needs Update'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: _filter == 'Needs Update' ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: _filter == 'Needs Update' ? 0.8 : 0.3),
                          width: _filter == 'Needs Update' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.errorRed),
                          const SizedBox(width: 6),
                          Text(
                            '$outdatedCount Needs Update',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search textfield
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search agency by name...',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.buttonGrey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: AppColors.scaffoldBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Agency List
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (MediaQuery.sizeOf(context).height - 300).clamp(160.0, 330.0),
                ),
                child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No agencies found matching your filter.',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final isUpdated = item.isUpdatedToday;
                        final nameColor = isUpdated ? const Color(0xFF1B5E20) : const Color(0xFFC62828);
                        final badgeBg = isUpdated
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12);
                        final badgeBorder = isUpdated
                            ? Colors.green.withValues(alpha: 0.35)
                            : Colors.red.withValues(alpha: 0.35);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              // Agency avatar
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isUpdated
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.red.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isUpdated ? Colors.green : Colors.redAccent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    item.agency.name.isNotEmpty ? item.agency.name[0].toUpperCase() : 'A',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: nameColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Agency details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.agency.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5,
                                              color: nameColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: badgeBorder, width: 0.8),
                                          ),
                                          child: Text(
                                            isUpdated ? 'Updated' : 'Not Updated',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: nameColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 11,
                                          color: isUpdated ? AppColors.textGrey : Colors.redAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(item.lastUpdated),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isUpdated ? AppColors.textGrey : Colors.red.shade700,
                                              fontWeight: isUpdated ? FontWeight.normal : FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Import Button if not updated
                              if (!isUpdated)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryBlue,
                                      side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.go('/import');
                                    },
                                    child: const Text('Import', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () {
            Navigator.pop(context);
            context.go('/import');
          },
          icon: const Icon(Icons.upload_file_rounded, size: 16),
          label: const Text('Go to Import', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}
