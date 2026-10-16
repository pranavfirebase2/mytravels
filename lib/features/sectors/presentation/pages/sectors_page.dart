import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flight_providers.dart';
import '../../../agency/presentation/widgets/agency_update_status_badge.dart';
import '../widgets/voice_search_dialog.dart';

import 'package:go_router/go_router.dart';

class SectorsPage extends ConsumerStatefulWidget {
  const SectorsPage({super.key});

  @override
  ConsumerState<SectorsPage> createState() => _SectorsPageState();
}


class _SectorsPageState extends ConsumerState<SectorsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFrom;
  String? _selectedTo;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  void _openVoiceSearch(BuildContext context) {
    VoiceSearchDialog.show(
      context: context,
      onResultApplied: (res) {
        if (res.hasSector) {
          final dateParam = res.date != null
              ? '?date=${res.date!.year}-${res.date!.month.toString().padLeft(2, '0')}-${res.date!.day.toString().padLeft(2, '0')}'
              : '';
          context.go('/sector/${res.src}/${res.dst}$dateParam');
        } else if (res.src != null && res.dst == null) {
          setState(() {
            _selectedFrom = res.src;
          });
        } else if (res.dst != null && res.src == null) {
          setState(() {
            _selectedTo = res.dst;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsProvider);
    final sectorsList = sectorsAsync.value ?? [];
    
    final uniqueFroms = sectorsList.map((s) => s.src).toSet().toList()..sort();
    final uniqueTos = sectorsList.map((s) => s.dst).toSet().toList()..sort();

    return AppLayout(
      activeRoute: '/sectors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 750;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'All Sectors',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const AgencyUpdateStatusBadge(compact: true),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.primaryBlue),
                              tooltip: 'Sync latest sectors',
                              onPressed: () {
                                ref.invalidate(allFlightsProvider);
                              },
                            ),
                          ],
                        ),
                        if (_selectedFrom != null || _selectedTo != null || _searchQuery.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedFrom = null;
                                _selectedTo = null;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'From',
                            uniqueFroms,
                            _selectedFrom,
                            (val) => setState(() => _selectedFrom = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdown(
                            'To',
                            uniqueTos,
                            _selectedTo,
                            (val) => setState(() => _selectedTo = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search sector (e.g. CCJ DXB)',
                              hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.search, color: AppColors.iconBlueAccent, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textGrey),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Voice Search (e.g. "Calicut Dubai Oct 21")',
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryBlue, Color(0xFF1D4ED8)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                              onPressed: () => _openVoiceSearch(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'All Sectors',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      const AgencyUpdateStatusBadge(),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.primaryBlue),
                        tooltip: 'Sync latest sectors',
                        onPressed: () {
                          ref.invalidate(allFlightsProvider);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDropdown('From', uniqueFroms, _selectedFrom, (val) => setState(() => _selectedFrom = val)),
                      const SizedBox(width: 8),
                      _buildDropdown('To', uniqueTos, _selectedTo, (val) => setState(() => _selectedTo = val)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search sector (e.g. CCJ DXB)',
                            hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.search, color: AppColors.iconBlueAccent, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: AppColors.textGrey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: 'Voice Search (e.g. "Calicut Dubai Oct 21")',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _openVoiceSearch(context),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryBlue, Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Voice Search',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedFrom != null || _selectedTo != null || _searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedFrom = null;
                                _selectedTo = null;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          sectorsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, st) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e'))),
            data: (sectors) {
              final filteredSectors = sectors.where((s) {
                if (_selectedFrom != null && s.src != _selectedFrom) return false;
                if (_selectedTo != null && s.dst != _selectedTo) return false;
                if (_searchQuery.isEmpty) return true;
                final srcName = AppStrings.airportNames[s.src]?.toLowerCase() ?? '';
                final dstName = AppStrings.airportNames[s.dst]?.toLowerCase() ?? '';
                
                final forward = '${s.src.toLowerCase()} ${s.dst.toLowerCase()}';
                final backward = '${s.dst.toLowerCase()} ${s.src.toLowerCase()}';
                final combined = '${s.src.toLowerCase()}${s.dst.toLowerCase()}';
                final forwardNames = '$srcName $dstName';
                final backwardNames = '$dstName $srcName';
                
                return forward.contains(_searchQuery) || 
                       backward.contains(_searchQuery) || 
                       combined.contains(_searchQuery.replaceAll(' ', '')) ||
                       forwardNames.contains(_searchQuery) ||
                       backwardNames.contains(_searchQuery) ||
                       srcName.contains(_searchQuery) ||
                       dstName.contains(_searchQuery);
              }).toList();

              if (filteredSectors.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No matching sectors found.')));
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  mainAxisExtent: 118,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sector.src,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primaryBlue),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                                  child: Icon(Icons.flight_takeoff, color: AppColors.iconBlue, size: 17),
                                ),
                                Text(
                                  sector.dst,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primaryBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppStrings.airportNames[sector.src] ?? sector.src} - ${AppStrings.airportNames[sector.dst] ?? sector.dst}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sector.airlines.isEmpty ? 'Unknown' : sector.airlines.join(' · '),
                              style: const TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint == 'From' ? 'All Origins' : 'All Dests', style: const TextStyle(fontSize: 14)),
            ),
            ...items.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ))
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
