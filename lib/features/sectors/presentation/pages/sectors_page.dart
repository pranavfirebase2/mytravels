import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flight_providers.dart';

import 'package:go_router/go_router.dart';

class SectorsPage extends ConsumerStatefulWidget {
  const SectorsPage({super.key});

  @override
  ConsumerState<SectorsPage> createState() => _SectorsPageState();
}

class _SectorsPageState extends ConsumerState<SectorsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      activeRoute: '/sectors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Sectors', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search sector (e.g. CCJ DXB)',
                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search, color: AppColors.iconBlueAccent, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ref.watch(sectorsProvider).when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, st) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e'))),
            data: (sectors) {
              final filteredSectors = sectors.where((s) {
                if (_searchQuery.isEmpty) return true;
                final forward = '${s.src.toLowerCase()} ${s.dst.toLowerCase()}';
                final backward = '${s.dst.toLowerCase()} ${s.src.toLowerCase()}';
                final combined = '${s.src.toLowerCase()}${s.dst.toLowerCase()}';
                return forward.contains(_searchQuery) || backward.contains(_searchQuery) || combined.contains(_searchQuery.replaceAll(' ', ''));
              }).toList();

              if (filteredSectors.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No matching sectors found.')));
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
                itemCount: filteredSectors.length,
                itemBuilder: (context, index) {
                  final sector = filteredSectors[index];
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
