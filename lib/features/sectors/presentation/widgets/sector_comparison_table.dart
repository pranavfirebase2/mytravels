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
    if (oldWidget.dates.length != widget.dates.length) {
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

  @override
  Widget build(BuildContext context) {
    const double dateColWidth = 120.0;
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
            double minPriceForDate = double.infinity;
            for (var f in flightsForDate) {
              final price = f.marketedPrice - (widget.agencyDeductions[f.agencyName] ?? 0);
              if (price < minPriceForDate) minPriceForDate = price;
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: dateColWidth,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        right: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                        bottom: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                        final isLowest = adjustedPrice == minPriceForDate;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isLowest ? Colors.green.withValues(alpha: 0.1) : AppColors.cardBackground,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isLowest ? Colors.green : AppColors.primaryBlue.withValues(alpha: 0.2),
                                                width: isLowest ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (f.createdAt != null) ...[
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 4.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.access_time, size: 10, color: AppColors.textGrey),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            _formatDateTime(f.createdAt!),
                                                            style: const TextStyle(
                                                              fontSize: 9,
                                                              color: AppColors.textGrey,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
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
                                                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  '${widget.src} - ${widget.dst} (${AppStrings.airportNames[widget.src] ?? widget.src} - ${AppStrings.airportNames[widget.dst] ?? widget.dst})',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBlack),
                                                ),
                                                const SizedBox(height: 2),
                                                Text('${AppStrings.airlineNames[f.airline] ?? f.airline} (${f.airline}) - ${f.flightNumber}', style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
                                                const SizedBox(height: 2),
                                                Text(f.baggage.isNotEmpty ? f.baggage : 'No baggage info', style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                                              ],
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
