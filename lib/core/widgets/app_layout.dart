import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String activeRoute;
  final bool disableScroll;

  const AppLayout({
    super.key,
    required this.child,
    required this.activeRoute,
    this.disableScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(context),
      body: disableScroll ? Padding(padding: const EdgeInsets.all(16.0), child: child) : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.headerDark,
      titleSpacing: 16,
      title: Row(
        children: [
          const Text(
            'My Travels',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildNavRow(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(BuildContext context) {
    final navItems = {
      'Sectors': '/sectors',
      'Agency Master': '/agency',
      'Import': '/import',
      'AgencyData': '/data',
      'Lowest Fare': '/lowest-fare',
    };

    return Row(
      children: navItems.entries.map((entry) {
        final isActive = entry.value == activeRoute;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: isActive ? AppColors.white.withValues(alpha: 0.15) : Colors.transparent,
              foregroundColor: isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (!isActive) {
                context.go(entry.value);
              }
            },
            child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }
}
