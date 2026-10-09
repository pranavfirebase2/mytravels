import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String activeRoute;

  const AppLayout({
    super.key,
    required this.child,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavRow(context),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.headerDark, 
      title: const Text(
        'MyTravels Market Fare Intelligence',
        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search sector / destination',
                hintStyle: const TextStyle(color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.iconBlueAccent),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildNavRow(BuildContext context) {
    final navItems = {
      'Sectors': '/sectors',
      'Agency Master': '/agency',
      'Import': '/import',
      'AgencyData': '/data',
      'Lowest Fare': '/lowest-fare',
      // 'Backup': '/backup',
      // 'Restore': '/restore',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: navItems.entries.map((entry) {
        final isActive = entry.value == activeRoute;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? AppColors.navActive : AppColors.navInactive,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () {
            if (!isActive) {
              context.go(entry.value);
            }
          },
          child: Text(entry.key),
        );
      }).toList(),
    );
  }
}
