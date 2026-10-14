import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../../features/agency/presentation/widgets/agency_update_status_badge.dart';
import '../../features/auth/data/services/auth_service.dart';

class _NavItem {
  final String title;
  final String route;
  final IconData icon;
  final String subtitle;

  const _NavItem({
    required this.title,
    required this.route,
    required this.icon,
    required this.subtitle,
  });
}

class AppLayout extends StatelessWidget {
  final Widget child;
  final String activeRoute;
  final bool disableScroll;

  static const List<_NavItem> _navItems = [
    _NavItem(
      title: 'Sectors',
      route: '/sectors',
      icon: Icons.flight_takeoff_rounded,
      subtitle: 'All sectors and routes',
    ),
    _NavItem(
      title: 'Agency Master',
      route: '/agency',
      icon: Icons.business_rounded,
      subtitle: 'Agencies and deduction settings',
    ),
    _NavItem(
      title: 'Import',
      route: '/import',
      icon: Icons.upload_file_rounded,
      subtitle: 'Import agency flight messages',
    ),
    _NavItem(
      title: 'Agency Data',
      route: '/data',
      icon: Icons.table_chart_rounded,
      subtitle: 'Raw and processed flight schedules',
    ),
    _NavItem(
      title: 'Lowest Fare',
      route: '/lowest-fare',
      icon: Icons.price_check_rounded,
      subtitle: 'Best fares and comparison',
    ),
  ];

  const AppLayout({
    super.key,
    required this.child,
    required this.activeRoute,
    this.disableScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(context, isMobile),
      drawer: _buildDrawer(context),
      body: disableScroll
          ? Padding(padding: const EdgeInsets.all(16.0), child: child)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isMobile) {
    final activeItem = _navItems.cast<_NavItem?>().firstWhere(
          (item) => item?.route == activeRoute,
          orElse: () => null,
        );
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleSpacing: isMobile ? 8 : 16,
      leading: isMobile
          ? (canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
                  onPressed: () => context.pop(),
                  tooltip: 'Back',
                )
              : Builder(
                  builder: (scaffoldCtx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppColors.textBlack),
                    onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
                    tooltip: 'Menu',
                  ),
                ))
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/applogo/3.png',
            height: isMobile ? 32 : 45,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          if (isMobile && activeItem != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.headerDark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.headerDark.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                activeItem.title,
                style: const TextStyle(
                  color: AppColors.headerDark,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (!isMobile) ...[
            const SizedBox(width: 40),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDesktopNavRow(context),
              ),
            ),
          ],
        ],
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: AgencyUpdateStatusBadge(compact: true),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          tooltip: 'Sign Out (mytravels@gmail.com)',
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(width: 4),
        if (isMobile && canPop)
          Builder(
            builder: (scaffoldCtx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textBlack),
              onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
              tooltip: 'Navigation Menu',
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopNavRow(BuildContext context) {
    return Row(
      children: _navItems.map((item) {
        final isActive = item.route == activeRoute;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: isActive
                  ? AppColors.headerDark.withValues(alpha: 0.12)
                  : Colors.transparent,
              foregroundColor: isActive
                  ? AppColors.headerDark
                  : AppColors.buttonGrey,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isActive
                    ? BorderSide(color: AppColors.headerDark.withValues(alpha: 0.35))
                    : BorderSide.none,
              ),
            ),
            icon: Icon(
              item.icon,
              size: 16,
              color: isActive ? AppColors.headerDark : AppColors.buttonLightGrey,
            ),
            label: Text(
              item.title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: isActive ? AppColors.headerDark : AppColors.textBlack,
              ),
            ),
            onPressed: () {
              if (!isActive) {
                context.go(item.route);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = min(320.0, screenWidth * 0.82);

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 16,
              16,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B365D), Color(0xFF0D2040)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/applogo/3.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.flight_takeoff_rounded,
                          color: AppColors.headerDark,
                          size: 24,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close Menu',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aerosphere Travels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Flight Operations & Rates Portal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4, bottom: 8),
                  child: Text(
                    'NAVIGATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.buttonLightGrey.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ..._navItems.map((item) {
                  final isActive = item.route == activeRoute;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).pop();
                          if (!isActive) {
                            context.go(item.route);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.headerDark.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isActive
                                ? Border.all(
                                    color: AppColors.headerDark
                                        .withValues(alpha: 0.35),
                                    width: 1.2,
                                  )
                                : Border.all(color: Colors.transparent, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.headerDark
                                      : AppColors.buttonLightGrey
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.buttonGrey,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isActive
                                            ? AppColors.headerDark
                                            : AppColors.textBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.headerDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Drawer Footer with User Info & Sign Out
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.headerDark.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: AppColors.headerDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aerosphere Staff',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                          Text(
                            'mytravels@gmail.com',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textGrey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      tooltip: 'Sign Out',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _confirmLogout(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Operations Active',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.buttonGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textGrey.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from Aerosphere Travels portal?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await authServiceInstance.logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}


