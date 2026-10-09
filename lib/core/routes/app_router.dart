import 'package:go_router/go_router.dart';
import '../../features/agency/presentation/pages/agency_page.dart';
import '../../features/sectors/presentation/pages/sectors_page.dart';
import '../../features/import/presentation/pages/import_page.dart';
import '../../features/lowest_fare/presentation/pages/lowest_fare_page.dart';
import '../../features/flights/presentation/pages/agency_data_page.dart';
import '../../features/sectors/presentation/pages/sector_details_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/lowest-fare', // Previewing lowest fare
    routes: [
      GoRoute(
        path: '/sectors',
        builder: (context, state) => const SectorsPage(),
      ),
      GoRoute(
        path: '/sector/:src/:dst',
        builder: (context, state) {
          final src = state.pathParameters['src']!;
          final dst = state.pathParameters['dst']!;
          return SectorDetailsPage(src: src, dst: dst);
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
        path: '/data',
        builder: (context, state) => const AgencyDataPage(),
      ),
      GoRoute(
        path: '/lowest-fare',
        builder: (context, state) => const LowestFarePage(),
      ),
    ],
  );
}
