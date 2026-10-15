import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/agency_update_status_provider.dart';
import 'agency_update_status_dialog.dart';

class AgencyUpdateStatusBadge extends ConsumerWidget {
  final bool compact;

  const AgencyUpdateStatusBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outdatedCount = ref.watch(outdatedAgenciesCountProvider);
    final hasOutdated = outdatedCount > 0;

    return Tooltip(
      message: hasOutdated
          ? '$outdatedCount agencies have not updated today (10:30 AM cutoff)'
          : 'All agencies are updated today!',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AgencyUpdateStatusDialog.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 10,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: hasOutdated
                  ? Colors.red.withValues(alpha: 0.08)
                  : Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasOutdated
                    ? Colors.red.withValues(alpha: 0.35)
                    : Colors.green.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: compact ? 16 : 18,
                  color: hasOutdated ? AppColors.errorRed : Colors.green.shade700,
                ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    hasOutdated ? 'Agencies' : 'All Updated',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasOutdated ? Colors.red.shade900 : Colors.green.shade800,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: hasOutdated ? AppColors.errorRed : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      hasOutdated ? '$outdatedCount' : '✓',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
