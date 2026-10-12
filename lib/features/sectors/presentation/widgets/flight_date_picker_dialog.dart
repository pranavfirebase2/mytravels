import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../flights/domain/entities/flight.dart';

class FlightDatePickerDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final List<Flight> sectorFlights;
  final bool Function(Flight flight, DateTime date) matchesDate;
  final DateTime? Function(String dateStr) parseFlightDate;

  const FlightDatePickerDialog({
    super.key,
    required this.selectedDate,
    required this.sectorFlights,
    required this.matchesDate,
    required this.parseFlightDate,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime? selectedDate,
    required List<Flight> sectorFlights,
    required bool Function(Flight flight, DateTime date) matchesDate,
    required DateTime? Function(String dateStr) parseFlightDate,
  }) {
    return showDialog<DateTime?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FlightDatePickerDialog(
        selectedDate: selectedDate,
        sectorFlights: sectorFlights,
        matchesDate: matchesDate,
        parseFlightDate: parseFlightDate,
      ),
    );
  }

  @override
  State<FlightDatePickerDialog> createState() => _FlightDatePickerDialogState();
}

class _FlightDatePickerDialogState extends State<FlightDatePickerDialog> {
  late DateTime _currentMonth;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);

    if (widget.selectedDate != null) {
      _currentMonth = DateTime(widget.selectedDate!.year, widget.selectedDate!.month);
    } else {
      DateTime candidate = DateTime(_today.year, _today.month);
      for (var f in widget.sectorFlights) {
        final p = f.parsedDate ?? widget.parseFlightDate(f.date);
        if (p != null && !p.isBefore(_today)) {
          candidate = DateTime(p.year, p.month);
          break;
        }
      }
      _currentMonth = candidate;
    }
  }

  bool _hasFlightOn(DateTime date) {
    for (var f in widget.sectorFlights) {
      if (widget.matchesDate(f, date)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthTitle = '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';
    final canGoPrev = _currentMonth.isAfter(DateTime(_today.year, _today.month));

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // Sunday is 0, Monday is 1, ..., Saturday is 6
    final startOffset = firstDayOfMonth.weekday % 7;
    final totalCells = startOffset + daysInMonth;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_month, color: AppColors.primaryBlue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Select Flight Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textGrey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Month Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: canGoPrev ? AppColors.textBlack : AppColors.textGrey.withValues(alpha: 0.3),
                    onPressed: canGoPrev
                        ? () {
                            setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                            });
                          }
                        : null,
                  ),
                  Text(
                    monthTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.textBlack,
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Days of week header row
              Row(
                children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Calendar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  if (index < startOffset) {
                    return const SizedBox.shrink();
                  }

                  final day = index - startOffset + 1;
                  final cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                  final isPast = cellDate.isBefore(_today);
                  final isSelected = widget.selectedDate != null &&
                      widget.selectedDate!.year == cellDate.year &&
                      widget.selectedDate!.month == cellDate.month &&
                      widget.selectedDate!.day == cellDate.day;
                  final hasFlight = _hasFlightOn(cellDate);

                  // Colors
                  Color? bgColor;
                  Color textColor;
                  Border? border;

                  if (isSelected) {
                    bgColor = AppColors.primaryBlue;
                    textColor = AppColors.white;
                  } else if (isPast) {
                    bgColor = Colors.transparent;
                    textColor = Colors.grey.shade300;
                  } else if (hasFlight) {
                    // Warm yellow color circle for available flight dates!
                    bgColor = const Color(0xFFFFD54F); // Warm yellow/amber
                    border = Border.all(color: const Color(0xFFFFA000), width: 1.2);
                    textColor = const Color(0xFF3E2723); // Dark readable text
                  } else {
                    bgColor = Colors.transparent;
                    textColor = AppColors.textBlack;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: isPast
                        ? null
                        : () {
                            Navigator.pop(context, cellDate);
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: border,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (hasFlight || isSelected) ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFA000), width: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Flight available',
                    style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Selected',
                    style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottom buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.selectedDate != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text('Clear Filter', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(context, DateTime.fromMillisecondsSinceEpoch(0));
                      },
                    )
                  else
                    const SizedBox.shrink(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
