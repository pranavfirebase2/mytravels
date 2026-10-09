import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flight_providers.dart';

import 'package:go_router/go_router.dart';

class SectorsPage extends ConsumerWidget {
  const SectorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLayout(
      activeRoute: '/sectors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {},
            child: const Text('Lowest Fare Search'),
          ),
          const SizedBox(height: 16),
          ref.watch(sectorsProvider).when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, st) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e'))),
            data: (sectors) {
              if (sectors.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No sectors available.')));
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  childAspectRatio: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sectors.length,
                itemBuilder: (context, index) {
                  final sector = sectors[index];
                  return Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      onTap: () => context.go('/sector/${sector.src}/${sector.dst}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sector.src,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(Icons.flight_takeoff, color: AppColors.iconBlue, size: 18),
                                ),
                                Text(
                                  sector.dst,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sector.airlines.isEmpty ? 'Unknown' : sector.airlines.join(' · '),
                              style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
