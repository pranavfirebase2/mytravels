import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/agency/presentation/pages/agency_page.dart';
import '../../features/sectors/presentation/pages/sectors_page.dart';
import '../../features/import/presentation/pages/import_page.dart';
import '../../features/import/presentation/pages/import_history_page.dart';
import '../../features/lowest_fare/presentation/pages/lowest_fare_page.dart';
import '../../features/flights/presentation/pages/agency_data_page.dart';
import '../../features/sectors/presentation/pages/sector_details_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/fare_broadcast/presentation/pages/fare_broadcast_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authServiceInstance,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authServiceInstance.isAuthenticated;
      final location = state.matchedLocation;

      // Let the splash screen display its animation and handle routing
      if (location == '/splash') {
        return null;
      }

      final isGoingToLogin = location == '/login';

      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }

      if (isAuth && isGoingToLogin) {
        return '/sectors';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/sectors',
        builder: (context, state) => const SectorsPage(),
      ),
      GoRoute(
        path: '/sector/:src/:dst',
        builder: (context, state) {
          final src = state.pathParameters['src']!;
          final dst = state.pathParameters['dst']!;
          final dateStr = state.uri.queryParameters['date'];
          DateTime? initialDate;
          if (dateStr != null && dateStr.isNotEmpty) {
            initialDate = DateTime.tryParse(dateStr);
          }
          return SectorDetailsPage(
            src: src,
            dst: dst,
            initialDate: initialDate,
          );
        },
      ),
      GoRoute(
        path: '/agency',
        builder: (context, state) => const AgencyPage(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportPage(),
      ),
      GoRoute(
        path: '/import/history',
        builder: (context, state) => const ImportHistoryPage(),
      ),
      GoRoute(
        path: '/data',
        builder: (context, state) => const AgencyDataPage(),
      ),
      GoRoute(
        path: '/lowest-fare',
        builder: (context, state) => const LowestFarePage(),
      ),
      GoRoute(
        path: '/fare-broadcast',
        builder: (context, state) => const FareBroadcastPage(),
      ),
    ],
  );
}
