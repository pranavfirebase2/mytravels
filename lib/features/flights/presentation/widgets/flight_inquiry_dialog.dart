import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/url_helper.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../agency/domain/entities/agency.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../../domain/entities/flight.dart';

/// Shows the flight inquiry popup with From number (9526429827) and To number (agency number).
/// If agency number is not added, clearly displays 'Agency number not added' and allows entering/saving.
void showFlightInquiryDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Flight flight,
  required Agency? agency,
  required double adjustedPrice,
  required double deduction,
  required String src,
  required String dst,
}) {
  final manualPhoneController = TextEditingController(text: agency?.whatsappNumber.trim() ?? '');
  bool saveNumberToAgency = true;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final hasSavedAgencyNumber = agency != null && agency.whatsappNumber.trim().isNotEmpty;
          final enteredPhone = manualPhoneController.text.trim();
          final effectivePhone = enteredPhone.isNotEmpty
              ? enteredPhone
              : (agency?.whatsappNumber.trim() ?? '');
          final hasAnyNumber = effectivePhone.isNotEmpty;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.airlineNames[flight.airline] ?? flight.airline} (${flight.airline} ${flight.flightNumber})${flight.via.isNotEmpty ? " · Via ${flight.via}" : ""}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$src → ${flight.via.isNotEmpty ? "${flight.via} → " : ""}$dst · ${flight.date}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textGrey),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Route & Airport Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                src,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                              ),
                              Text(
                                AppStrings.airportNames[src] ?? src,
                                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                          if (flight.via.isNotEmpty) ...[
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue, size: 16),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 0.8),
                                  ),
                                  child: Text(
                                    'Via ${flight.via}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStrings.airportNames[flight.via] ?? flight.via,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue, size: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                dst,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                              ),
                              Text(
                                AppStrings.airportNames[dst] ?? dst,
                                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Flight specs details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _buildSpecRow(Icons.calendar_today_rounded, 'Date', flight.date),
                          if (flight.via.isNotEmpty) ...[
                            const Divider(height: 14),
                            _buildSpecRow(Icons.connecting_airports_rounded, 'Connection / Via', 'Via ${flight.via} (${AppStrings.airportNames[flight.via] ?? flight.via})'),
                          ],
                          const Divider(height: 14),
                          _buildSpecRow(Icons.schedule_rounded, 'Timing', flight.timing.isNotEmpty ? flight.timing : '—'),
                          const Divider(height: 14),
                          _buildSpecRow(Icons.luggage_outlined, 'Baggage', flight.baggage.isNotEmpty ? flight.baggage : '—'),
                          const Divider(height: 14),
                          _buildSpecRow(Icons.event_seat_outlined, 'Seats Available', flight.seats.isNotEmpty ? flight.seats : '—'),
                          const Divider(height: 14),
                          _buildSpecRow(Icons.sell_outlined, 'Marketed Fare', '₹${flight.marketedPrice.toInt()}'),
                          if (deduction > 0) ...[
                            const Divider(height: 14),
                            _buildSpecRow(Icons.discount_outlined, 'Comparison Deduction', '- ₹${deduction.toInt()}'),
                          ],
                          const Divider(height: 14),
                          _buildSpecRow(
                            Icons.payments_outlined,
                            'Final Adjusted Fare',
                            '₹${adjustedPrice.toInt()}',
                            valueStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // WhatsApp Routing Card (From number & To number)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hasAnyNumber
                            ? const Color(0xFF25D366).withValues(alpha: 0.08)
                            : Colors.red.withValues(alpha: 0.06),
                        border: Border.all(
                          color: hasAnyNumber
                              ? const Color(0xFF25D366).withValues(alpha: 0.4)
                              : AppColors.errorRed.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: hasAnyNumber ? const Color(0xFF25D366) : AppColors.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      flight.agencyName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (agency?.isStarred == true) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Agency WhatsApp Number
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasAnyNumber
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : AppColors.errorRed.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: hasAnyNumber ? const Color(0xFF1B8A44) : AppColors.errorRed,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Agency WhatsApp : ',
                                  style: TextStyle(fontSize: 13, color: AppColors.buttonGrey, fontWeight: FontWeight.w500),
                                ),
                                Expanded(
                                  child: Text(
                                    hasAnyNumber ? effectivePhone : 'Agency number not added',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: hasAnyNumber ? const Color(0xFF1B8A44) : AppColors.errorRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // If agency number is not added, show prominent alert and inline input
                          if (!hasSavedAgencyNumber) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Agency number not added',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.brown),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Enter agency WhatsApp number below to connect, or update in Agency Master.',
                                          style: TextStyle(fontSize: 11.5, color: Colors.brown),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: manualPhoneController,
                              keyboardType: TextInputType.phone,
                              onChanged: (val) => setDialogState(() {}),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Enter ${flight.agencyName} Number',
                                hintText: 'e.g. 9876543210 or +919876543210',
                                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: saveNumberToAgency,
                                  activeColor: const Color(0xFF25D366),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      saveNumberToAgency = val ?? true;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'Save this number to Agency Master for future inquiries',
                                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close', style: TextStyle(color: AppColors.buttonGrey)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
                onPressed: () async {
                  final targetPhone = manualPhoneController.text.trim().isNotEmpty
                      ? manualPhoneController.text.trim()
                      : (agency?.whatsappNumber.trim() ?? '');

                  if (targetPhone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Agency number not added for ${flight.agencyName}. Please enter a phone number or add in Agency Master.'),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                    return;
                  }

                  // If user entered a new number and saveNumberToAgency is checked, save to Agency Master in Firestore
                  if (saveNumberToAgency && manualPhoneController.text.trim().isNotEmpty) {
                    try {
                      if (agency != null) {
                        await ref.read(agencyControllerProvider).updateAgency(
                          agency.copyWith(whatsappNumber: targetPhone),
                        );
                      } else {
                        await ref.read(agencyControllerProvider).addAgency(
                          Agency(
                            id: '',
                            name: flight.agencyName,
                            whatsappNumber: targetPhone,
                            comparisonDeduction: deduction,
                            isStarred: false,
                          ),
                        );
                      }
                    } catch (_) {
                      // Silently ignore or let WhatsApp proceed
                    }
                  }

                  final srcAirport = AppStrings.airportNames[src] ?? src;
                  final dstAirport = AppStrings.airportNames[dst] ?? dst;
                  final formattedDate = _formatDateForMessage(flight);

                  final viaAirport = flight.via.isNotEmpty ? (AppStrings.airportNames[flight.via] ?? flight.via) : '';
                  final connectionLine = flight.via.isNotEmpty
                      ? '\n🔄 Connection: Via $viaAirport (${flight.via})'
                      : '';

                  final message = '''Hi, 
please check the availability for this flight.
✈️ Flight: ${flight.airline} ${flight.flightNumber}${flight.via.isNotEmpty ? " (Via ${flight.via})" : ""}
📅 Date: $formattedDate
📍 From: $srcAirport ($src)
📍 To: $dstAirport ($dst)$connectionLine''';

                  var cleanPhone = targetPhone.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanPhone.length == 10) {
                    cleanPhone = '91$cleanPhone';
                  }

                  final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';

                  try {
                    await openExternalUrl(url);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open WhatsApp: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('Connect Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildSpecRow(IconData icon, String label, String value, {TextStyle? valueStyle}) {
  return Row(
    children: [
      Icon(icon, size: 15, color: AppColors.buttonLightGrey),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.buttonGrey)),
      const Spacer(),
      Text(
        value,
        style: valueStyle ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBlack),
      ),
    ],
  );
}

String _formatDateForMessage(Flight flight) {
  const fullMonths = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  if (flight.parsedDate != null) {
    final d = flight.parsedDate!;
    return '${d.day} ${fullMonths[d.month]} ${d.year}';
  }

  // Try parsing flight.date string
  try {
    final raw = flight.date.trim();
    final isoParsed = DateTime.tryParse(raw);
    if (isoParsed != null) {
      return '${isoParsed.day} ${fullMonths[isoParsed.month]} ${isoParsed.year}';
    }

    final parts = raw.split(RegExp(r'[\s\-/]+'));
    if (parts.length >= 2) {
      final day = int.tryParse(parts[0]);
      if (day != null) {
        final monthStr = parts[1].toUpperCase();
        const shortMonths = {
          'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
          'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
        };
        final m = shortMonths[monthStr.length >= 3 ? monthStr.substring(0, 3) : monthStr] ?? int.tryParse(parts[1]);
        if (m != null && m >= 1 && m <= 12) {
          int year = DateTime.now().year;
          if (parts.length >= 3) {
            year = int.tryParse(parts[2]) ?? year;
            if (year < 100) year += 2000;
          }
          return '$day ${fullMonths[m]} $year';
        }
      }
    }
  } catch (_) {}

  return flight.date;
}
