import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mytravels/core/constants/app_colors.dart';
import 'package:mytravels/core/widgets/app_layout.dart';
import 'package:mytravels/features/fare_broadcast/domain/entities/broadcast_item.dart';
import 'package:mytravels/features/fare_broadcast/presentation/providers/fare_broadcast_providers.dart';

import '../../../flights/presentation/providers/flight_providers.dart';

class FareBroadcastPage extends ConsumerStatefulWidget {
  const FareBroadcastPage({super.key});

  @override
  ConsumerState<FareBroadcastPage> createState() => _FareBroadcastPageState();
}

class _FareBroadcastPageState extends ConsumerState<FareBroadcastPage>
    with SingleTickerProviderStateMixin {
  late TabController _mobileTabController;
  final TextEditingController _markupController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _communityLinkController = TextEditingController();

  bool _initializedControllers = false;
  final Set<int> _expandedSectorIndices = {};

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    _markupController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _communityLinkController.dispose();
    super.dispose();
  }

  void _syncControllers(FareBroadcastConfig config) {
    if (!_initializedControllers) {
      _markupController.text =
          config.markup == 0 ? '' : config.markup.toInt().toString();
      _contactNameController.text = config.contactName;
      _contactPhoneController.text = config.contactPhone;
      _communityLinkController.text = config.communityLink;
      _initializedControllers = true;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Fare flyer text copied! Ready to paste into WhatsApp.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _shareToWhatsApp(String text) async {
    final encoded = Uri.encodeComponent(text);
    final url = Uri.parse('https://api.whatsapp.com/send?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _copyToClipboard(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final broadcastAsync = ref.watch(fareBroadcastProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return AppLayout(
      activeRoute: '/fare-broadcast',
      child: broadcastAsync.when(
        loading: () => SizedBox(
          height: 450,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Loading Fare Broadcast Data...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headerDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Computing lowest fares and checking sector deals',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading fare data: $err'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(fareBroadcastProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (config) {
          _syncControllers(config);
          final messageText = config.generateBroadcastText();

          if (isMobile) {
            return _buildMobileView(config, messageText);
          }
          return _buildDesktopView(config, messageText);
        },
      ),
    );
  }

  Widget _buildDesktopView(FareBroadcastConfig config, String messageText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Controls & Sectors List
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopToolbar(config),
              const SizedBox(height: 16),
              _buildSectorsList(config),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Right Column: WhatsApp Preview & Share Actions
        Expanded(
          flex: 5,
          child: _buildPreviewPanel(config, messageText),
        ),
      ],
    );
  }

  Widget _buildMobileView(FareBroadcastConfig config, String messageText) {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: TabBar(
            controller: _mobileTabController,
            labelColor: AppColors.headerDark,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.headerDark,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.tune_rounded, size: 18),
                text: 'Sectors & Config',
              ),
              Tab(
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                text: 'WhatsApp Preview',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tab Views
        SizedBox(
          height: MediaQuery.sizeOf(context).height - 180,
          child: TabBarView(
            controller: _mobileTabController,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTopToolbar(config),
                    const SizedBox(height: 14),
                    _buildSectorsList(config),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPreviewPanel(config, messageText),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopToolbar(FareBroadcastConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.headerDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.headerDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare Broadcast Generator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    Text(
                      'Auto-picks lowest fares across all agencies for marketing flyers',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh Fares from Database',
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryBlue),
                onPressed: () {
                  ref.invalidate(allFlightsProvider);
                  ref.invalidate(fareBroadcastProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing latest fares from database...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 24),

          // Price Mode Selector
          const Text(
            'Fare Format in Message',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<PriceDisplayMode>(
            segments: const [
              ButtonSegment(
                value: PriceDisplayMode.flightAndAmount,
                label: Text('Flight & Amount (IX 733 - 21000)'),
                icon: Icon(Icons.flight_takeoff_rounded, size: 16),
              ),
              ButtonSegment(
                value: PriceDisplayMode.lowestAmount,
                label: Text('Amount Only'),
                icon: Icon(Icons.currency_rupee_rounded, size: 16),
              ),
              ButtonSegment(
                value: PriceDisplayMode.specialFareText,
                label: Text('SPECIAL FARE'),
                icon: Icon(Icons.star_rounded, size: 16),
              ),
              ButtonSegment(
                value: PriceDisplayMode.amountWithSpecialFare,
                label: Text('Both (₹ + Text)'),
                icon: Icon(Icons.auto_awesome_rounded, size: 16),
              ),
            ],
            selected: {config.priceMode},
            onSelectionChanged: (Set<PriceDisplayMode> newSelection) {
              ref
                  .read(fareBroadcastProvider.notifier)
                  .setPriceMode(newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Markup, Contact Name & Phone Row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Markup Field
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _markupController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Add Margin (₹)',
                    hintText: '0',
                    prefixText: '+₹ ',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final markup = double.tryParse(val) ?? 0.0;
                    ref.read(fareBroadcastProvider.notifier).setMarkup(markup);
                  },
                ),
              ),

              // Contact Name
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _contactNameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    hintText: 'Sorryjith',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    ref
                        .read(fareBroadcastProvider.notifier)
                        .updateContactDetails(name: val.trim());
                  },
                ),
              ),

              // Contact Phone
              SizedBox(
                width: 170,
                child: TextField(
                  controller: _contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Booking Phone',
                    hintText: '+91 85900 72609',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    ref
                        .read(fareBroadcastProvider.notifier)
                        .updateContactDetails(phone: val.trim());
                  },
                ),
              ),

              // WhatsApp Community Link
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _communityLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Community Link (Bottom of flyer)',
                    hintText: 'https://chat.whatsapp.com/...',
                    prefixIcon: Icon(Icons.groups_rounded, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    ref
                        .read(fareBroadcastProvider.notifier)
                        .updateContactDetails(communityLink: val.trim());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Select All / Deselect All Row
          Row(
            children: [
              Text(
                'Available Sectors (${config.sectors.where((s) => s.isSelected).length}/${config.sectors.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.headerDark,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.check_box_outlined, size: 16),
                label: const Text('Select All', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  ref
                      .read(fareBroadcastProvider.notifier)
                      .toggleAllSectors(true);
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  ref
                      .read(fareBroadcastProvider.notifier)
                      .toggleAllSectors(false);
                },
              ),
              TextButton.icon(
                icon: Icon(
                  _expandedSectorIndices.length >= config.sectors.length && config.sectors.isNotEmpty
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                  size: 16,
                ),
                label: Text(
                  _expandedSectorIndices.length >= config.sectors.length && config.sectors.isNotEmpty
                      ? 'Collapse All'
                      : 'Expand All',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  setState(() {
                    if (_expandedSectorIndices.length >= config.sectors.length) {
                      _expandedSectorIndices.clear();
                    } else {
                      _expandedSectorIndices.addAll(List.generate(config.sectors.length, (i) => i));
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectorsList(FareBroadcastConfig config) {
    if (config.sectors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No sector flights found. Please import flight rates first.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: config.sectors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, sectorIdx) {
        final sector = config.sectors[sectorIdx];
        return _buildSectorCard(config, sector, sectorIdx);
      },
    );
  }

  Widget _buildSectorCard(
    FareBroadcastConfig config,
    BroadcastSectorItem sector,
    int sectorIdx,
  ) {
    final activeDatesCount = sector.dates.where((d) => d.isSelected).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sector.isSelected
              ? AppColors.headerDark.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
          width: sector.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        key: ValueKey('sec_${sectorIdx}_${_expandedSectorIndices.contains(sectorIdx)}'),
        initiallyExpanded: _expandedSectorIndices.contains(sectorIdx),
        onExpansionChanged: (isExpanded) {
          setState(() {
            if (isExpanded) {
              _expandedSectorIndices.add(sectorIdx);
            } else {
              _expandedSectorIndices.remove(sectorIdx);
            }
          });
        },
        shape: const Border(),
        leading: Checkbox(
          value: sector.isSelected,
          activeColor: AppColors.headerDark,
          onChanged: (val) {
            ref
                .read(fareBroadcastProvider.notifier)
                .toggleSector(sectorIdx, val ?? false);
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                '${sector.source} ➝ ${sector.destination}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($activeDatesCount dates selected)',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                'Flight: ${sector.flightNumber.isEmpty ? "Not set" : sector.flightNumber}  •  Baggage: ${sector.baggage}',
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Sector Settings: Flight Number & Baggage inputs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: sector.flightNumber,
                        decoration: const InputDecoration(
                          labelText: 'Flight Number',
                          hintText: 'e.g. IX 375',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref
                              .read(fareBroadcastProvider.notifier)
                              .updateSectorFlightNumber(sectorIdx, val.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: sector.baggage,
                        decoration: const InputDecoration(
                          labelText: 'Baggage Allowance',
                          hintText: 'e.g. 30 KG',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref
                              .read(fareBroadcastProvider.notifier)
                              .updateSectorBaggage(sectorIdx, val.trim());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dates Chip Selection Grid
                const Text(
                  'Select Travel Dates to Broadcast:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(sector.dates.length, (dateIdx) {
                    final d = sector.dates[dateIdx];
                    return _buildDateChip(
                      config: config,
                      date: d,
                      sectorIdx: sectorIdx,
                      dateIdx: dateIdx,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required FareBroadcastConfig config,
    required BroadcastDateItem date,
    required int sectorIdx,
    required int dateIdx,
  }) {
    final price = (date.lowestPrice + config.markup).round();
    final isSelected = date.isSelected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref
              .read(fareBroadcastProvider.notifier)
              .toggleDate(sectorIdx, dateIdx, !isSelected);
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF22C55E)
                  : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 15,
                color: isSelected ? const Color(0xFF166534) : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                date.displayDate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected ? const Color(0xFF166534) : Colors.black87,
                ),
              ),
              if (date.flightNumber.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFBBF7D0)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    date.flightNumber,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF14532D)
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF16A34A)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '₹$price',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (date.via.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    'Via ${date.via}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showEditDateDialog(sectorIdx, dateIdx, date),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: isSelected ? const Color(0xFF166534) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(FareBroadcastConfig config, String messageText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'WhatsApp Flyer Live Preview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                tooltip: 'Edit Template Header & Footer',
                onPressed: () => _showTemplateEditDialog(config),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons Bar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B365D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Copy Text',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _copyToClipboard(messageText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _shareToWhatsApp(messageText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simulated WhatsApp Chat Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEAE2), // WhatsApp wallpaper tone
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDAD2C7)),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SelectableText(
                messageText.isEmpty
                    ? 'No sectors or dates selected.\nPlease check at least one sector above.'
                    : messageText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'monospace',
                  color: Color(0xFF111B21),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplateEditDialog(FareBroadcastConfig config) {
    final headerController = TextEditingController(text: config.customHeader);
    final footerController = TextEditingController(text: config.customFooter);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.headerDark),
            SizedBox(width: 8),
            Text('Customize Broadcast Template'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Header Template',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: headerController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter header message...',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Footer Template (Use {PHONE} and {NAME} placeholders)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: footerController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter footer message...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref
                  .read(fareBroadcastProvider.notifier)
                  .updateHeader(headerController.text);
              ref
                  .read(fareBroadcastProvider.notifier)
                  .updateFooter(footerController.text);
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save Template'),
          ),
        ],
      ),
    );
  }

  void _showEditDateDialog(
    int sectorIdx,
    int dateIdx,
    BroadcastDateItem dateItem,
  ) {
    final flightNumController =
        TextEditingController(text: dateItem.flightNumber);
    final priceController =
        TextEditingController(text: dateItem.lowestPrice.toInt().toString());
    final viaController = TextEditingController(text: dateItem.via);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_calendar_rounded,
                color: AppColors.headerDark),
            const SizedBox(width: 8),
            Text('Edit ${dateItem.displayDate} Fare'),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: flightNumController,
                decoration: const InputDecoration(
                  labelText: 'Flight Number',
                  hintText: 'e.g. IX 733',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lowest Price (₹)',
                  hintText: 'e.g. 21000',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: viaController,
                decoration: const InputDecoration(
                  labelText: 'Connecting City / Via (e.g. MCT)',
                  hintText: 'Leave blank for direct flight',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.hub_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newFn = flightNumController.text.trim();
              final newPrice =
                  double.tryParse(priceController.text.trim()) ??
                      dateItem.lowestPrice;
              final newVia = viaController.text.trim().toUpperCase();
              ref
                  .read(fareBroadcastProvider.notifier)
                  .updateDateFlightNumber(sectorIdx, dateIdx, newFn);
              ref
                  .read(fareBroadcastProvider.notifier)
                  .updateDatePrice(sectorIdx, dateIdx, newPrice);
              ref
                  .read(fareBroadcastProvider.notifier)
                  .updateDateVia(sectorIdx, dateIdx, newVia);
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
