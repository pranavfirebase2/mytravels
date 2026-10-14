import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../flights/domain/entities/flight.dart';

class SyncScrollControllerGroup {
  final List<ScrollController> _controllers = [];
  double _offset = 0.0;
  bool _isScrolledByCode = false;

  ScrollController addAndGet() {
    final controller = ScrollController(initialScrollOffset: _offset);
    _controllers.add(controller);
    controller.addListener(() {
      if (_isScrolledByCode) return;
      if (controller.hasClients && controller.offset != _offset) {
        _isScrolledByCode = true;
        _offset = controller.offset;
        for (var c in _controllers) {
          if (c != controller && c.hasClients && c.offset != _offset) {
            c.jumpTo(_offset);
          }
        }
        _isScrolledByCode = false;
      }
    });
    return controller;
  }

  Future<void> animateTo(
    double offset, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOutCubic,
  }) async {
    ScrollController? active;
    for (var c in _controllers) {
      if (c.hasClients) {
        active = c;
        break;
      }
    }
    if (active != null) {
      final maxExtent = active.position.maxScrollExtent;
      final target = offset.clamp(0.0, maxExtent);
      await active.animateTo(target, duration: duration, curve: curve);
    }
  }

  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
  }
}

class SectorComparisonTable extends StatefulWidget {
  final List<String> dates;
  final List<String> agencies;
  final List<Flight> flights;
  final Map<String, double> agencyDeductions;
  final String src;
  final String dst;
  final String? Function(String) getAirlineLogoPath;
  final Widget Function(String) buildFallbackLogo;
  final void Function(Flight flight, double adjustedPrice, double deduction)? onFlightTap;

  const SectorComparisonTable({
    super.key,
    required this.dates,
    required this.agencies,
    required this.flights,
    required this.agencyDeductions,
    required this.src,
    required this.dst,
    required this.getAirlineLogoPath,
    required this.buildFallbackLogo,
    this.onFlightTap,
  });

  @override
  State<SectorComparisonTable> createState() => _SectorComparisonTableState();
}

class _SectorComparisonTableState extends State<SectorComparisonTable> {
  late SyncScrollControllerGroup _group;
  late ScrollController _headerController;
  late List<ScrollController> _rowControllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _group = SyncScrollControllerGroup();
    _headerController = _group.addAndGet();
    _rowControllers = List.generate(widget.dates.length, (index) => _group.addAndGet());
  }

  @override
  void didUpdateWidget(SectorComparisonTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dates.length != widget.dates.length ||
        oldWidget.dates.join(',') != widget.dates.join(',')) {
      _group.dispose();
      _initControllers();
    }
  }

  @override
  void dispose() {
    _group.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final hour24 = local.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$day $month, $hour12:$minute $period';
  }

  bool _isFlightOutdated(DateTime? createdAt) {
    if (createdAt == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    // If 2 or more days old, always outdated
    if (today.difference(createdDate).inDays >= 2) {
      return true;
    }

    // Daily 11:00 AM cutoff: after 11:00 AM today, any fare not updated today is outdated
    if (now.hour >= 11 && createdDate.isBefore(today)) {
      return true;
    }

    return false;
  }

  void _scrollToAgency(String agencyName) {
    final idx = widget.agencies.indexOf(agencyName);
    if (idx != -1) {
      const double agencyColWidth = 180.0;
      _group.animateTo(idx * agencyColWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double dateColWidth = 135.0;
    const double agencyColWidth = 180.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: StickyHeader(
        header: Container(
          color: AppColors.cardBackground,
          child: Row(
            children: [
              Container(
                width: dateColWidth,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                    bottom: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                  ),
                ),
                child: const Text('Travel date', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: widget.agencies.map((agency) => Container(
                      width: agencyColWidth,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Flexible(child: Text(agency, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          children: List.generate(widget.dates.length, (index) {
            final date = widget.dates[index];
            final flightsForDate = widget.flights.where((f) => f.date == date).toList();

            // Calculate distinct prices for this date to determine Rank 1 (Lowest) & Rank 2 (Second lowest)
            final sortedPrices = <double>{};
            for (var f in flightsForDate) {
              final price = f.marketedPrice - (widget.agencyDeductions[f.agencyName] ?? 0);
              sortedPrices.add(price);
            }
            final priceList = sortedPrices.toList()..sort();
            final double? minPriceForDate = priceList.isNotEmpty ? priceList.first : null;
            final double? secondMinPriceForDate = priceList.length > 1 ? priceList[1] : null;

            // Find agencies offering the lowest price on this date
            final lowestAgencies = flightsForDate
                .where((f) => (f.marketedPrice - (widget.agencyDeductions[f.agencyName] ?? 0)) == minPriceForDate)
                .map((f) => f.agencyName)
                .toSet()
                .toList();

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: dateColWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        right: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                        bottom: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (lowestAgencies.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          if (lowestAgencies.length == 1)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _scrollToAgency(lowestAgencies.first),
                                borderRadius: BorderRadius.circular(4),
                                child: Tooltip(
                                  message: 'Tap to view ${lowestAgencies.first}',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, size: 10, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            lowestAgencies.first,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B5E20),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.chevron_right_rounded, size: 12, color: Color(0xFF1B5E20)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                ...lowestAgencies.take(2).map((agency) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _scrollToAgency(agency),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Tooltip(
                                        message: 'Tap to view $agency',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Colors.green.withValues(alpha: 0.35),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star, size: 9, color: Colors.green),
                                              const SizedBox(width: 3),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 85),
                                                child: Text(
                                                  agency,
                                                  style: const TextStyle(
                                                    fontSize: 9.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1B5E20),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                if (lowestAgencies.length > 2)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _scrollToAgency(lowestAgencies[2]),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.green.withValues(alpha: 0.35),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          '+${lowestAgencies.length - 2}',
                                          style: const TextStyle(
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                          bottom: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: _rowControllers[index],
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: widget.agencies.map((agency) {
                            final flightOptions = widget.flights.where((f) => f.date == date && f.agencyName == agency).toList();
                            return Container(
                              width: agencyColWidth,
                              padding: const EdgeInsets.all(12.0),
                              child: flightOptions.isEmpty
                                  ? const Center(child: Text('—', style: TextStyle(color: AppColors.textGrey)))
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: flightOptions.map((f) {
                                        final ded = widget.agencyDeductions[f.agencyName] ?? 0;
                                        final adjustedPrice = f.marketedPrice - ded;
                                        final isLowest = minPriceForDate != null && adjustedPrice == minPriceForDate;
                                        final isSecondLowest = secondMinPriceForDate != null && adjustedPrice == secondMinPriceForDate;
                                        final isOutdated = _isFlightOutdated(f.createdAt);

                                        final Color borderColor;
                                        final double borderWidth;
                                        final Color cardBg;
                                        final Color priceColor;

                                        if (isOutdated) {
                                          borderColor = Colors.redAccent;
                                          borderWidth = (isLowest || isSecondLowest) ? 2.0 : 1.5;
                                          cardBg = Colors.redAccent.withValues(alpha: 0.04);
                                          priceColor = Colors.red.shade900;
                                        } else if (isLowest) {
                                          borderColor = Colors.green;
                                          borderWidth = 2.0;
                                          cardBg = Colors.green.withValues(alpha: 0.10);
                                          priceColor = const Color(0xFF1B5E20);
                                        } else if (isSecondLowest) {
                                          borderColor = Colors.amber.shade700;
                                          borderWidth = 2.0;
                                          cardBg = Colors.amber.withValues(alpha: 0.08);
                                          priceColor = const Color(0xFFB45309);
                                        } else {
                                          borderColor = AppColors.primaryBlue.withValues(alpha: 0.2);
                                          borderWidth = 1.0;
                                          cardBg = AppColors.cardBackground;
                                          priceColor = Colors.black;
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: widget.onFlightTap != null
                                                  ? () => widget.onFlightTap!(f, adjustedPrice, ded)
                                                  : null,
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: cardBg,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: borderColor,
                                                    width: borderWidth,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Builder(
                                                      builder: (context) {
                                                        final isOutdated = _isFlightOutdated(f.createdAt);
                                                        if (f.createdAt == null) return const SizedBox.shrink();
                                                        return Padding(
                                                          padding: const EdgeInsets.only(bottom: 4.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.access_time_rounded,
                                                                size: 11,
                                                                color: isOutdated ? Colors.redAccent : AppColors.textGrey,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  _formatDateTime(f.createdAt!),
                                                                  style: TextStyle(
                                                                    fontSize: 9.5,
                                                                    color: isOutdated ? Colors.redAccent : AppColors.textGrey,
                                                                    fontWeight: isOutdated ? FontWeight.bold : FontWeight.w500,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                              if (isOutdated) ...[
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.redAccent.withValues(alpha: 0.12),
                                                                    borderRadius: BorderRadius.circular(3),
                                                                  ),
                                                                  child: const Text(
                                                                    'Old',
                                                                    style: TextStyle(
                                                                      fontSize: 8,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: Colors.redAccent,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Builder(
                                                          builder: (context) {
                                                            final logoPath = widget.getAirlineLogoPath(f.airline);
                                                            if (logoPath != null) {
                                                              return Image.asset(
                                                                logoPath,
                                                                width: 60,
                                                                height: 36,
                                                                fit: BoxFit.contain,
                                                                errorBuilder: (context, error, stackTrace) => widget.buildFallbackLogo(f.airline),
                                                              );
                                                            }
                                                            return widget.buildFallbackLogo(f.airline);
                                                          },
                                                        ),
                                                        Text(
                                                          '₹${adjustedPrice.toInt()}',
                                                          style: TextStyle(color: priceColor, fontSize: 16, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '${widget.src} - ${widget.dst}',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${AppStrings.airportNames[widget.src] ?? widget.src} - ${AppStrings.airportNames[widget.dst] ?? widget.dst}',
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textGrey),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text('${AppStrings.airlineNames[f.airline] ?? f.airline} (${f.airline}) - ${f.flightNumber}', style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
                                                    const SizedBox(height: 2),
                                                    Text(f.baggage.isNotEmpty ? f.baggage : 'No baggage info', style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
