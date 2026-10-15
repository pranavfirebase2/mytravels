import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/url_helper.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../agency/domain/entities/agency.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../../../fare_broadcast/presentation/providers/fare_broadcast_providers.dart';
import '../../domain/entities/flight.dart';
import '../providers/flight_providers.dart';

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
                  tooltip: 'Copy Inquiry Message',
                  icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primaryBlue),
                  onPressed: () {
                    final message = generateFlightInquiryMessage(
                      flight: flight,
                      src: src,
                      dst: dst,
                    );
                    copyInquiryMessageToClipboard(context, message);
                  },
                ),
                IconButton(
                  tooltip: 'Delete this flight rate',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.errorRed),
                  onPressed: () => _confirmAndDeleteFlight(
                    context: context,
                    dialogContext: dialogContext,
                    ref: ref,
                    flight: flight,
                    src: src,
                    dst: dst,
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
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: () => _confirmAndDeleteFlight(
                  context: context,
                  dialogContext: dialogContext,
                  ref: ref,
                  flight: flight,
                  src: src,
                  dst: dst,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(
                  'Delete Flight',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close', style: TextStyle(color: AppColors.buttonGrey)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final message = generateFlightInquiryMessage(
                        flight: flight,
                        src: src,
                        dst: dst,
                      );
                      copyInquiryMessageToClipboard(context, message);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

                      final message = generateFlightInquiryMessage(
                        flight: flight,
                        src: src,
                        dst: dst,
                      );

                      var cleanPhone = targetPhone.replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleanPhone.length == 10) {
                        cleanPhone = '91$cleanPhone';
                      }

                      final encodedMsg = Uri.encodeComponent(message);
                      final url = 'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg';

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

String formatFlightDateForMessage(Flight flight) {
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

String generateFlightInquiryMessage({
  required Flight flight,
  required String src,
  required String dst,
}) {
  final srcAirport = AppStrings.airportNames[src] ?? src;
  final dstAirport = AppStrings.airportNames[dst] ?? dst;
  final formattedDate = formatFlightDateForMessage(flight);
  final airlineName = AppStrings.airlineNames[flight.airline] ?? flight.airline;

  String cleanFlightNo = flight.flightNumber.trim().toUpperCase();
  final cleanAirline = flight.airline.trim().toUpperCase();
  if (cleanFlightNo.isNotEmpty && cleanFlightNo != '—') {
    if (cleanAirline.isNotEmpty && !cleanFlightNo.startsWith(cleanAirline)) {
      cleanFlightNo = '$cleanAirline $cleanFlightNo';
    }
  } else {
    cleanFlightNo = cleanAirline;
  }

  final flightDisplay = (cleanFlightNo.isNotEmpty && cleanFlightNo != airlineName)
      ? '$airlineName ($cleanFlightNo)'
      : airlineName;

  final viaAirport = flight.via.isNotEmpty ? (AppStrings.airportNames[flight.via] ?? flight.via) : '';
  final connectionLine = flight.via.isNotEmpty
      ? '\n🔄 Connection: Via $viaAirport (${flight.via})'
      : '';
  final baggageLine = flight.baggage.isNotEmpty &&
          flight.baggage != '—' &&
          flight.baggage.toLowerCase() != 'no baggage info'
      ? '\n🧳 Baggage: ${flight.baggage}'
      : '';
  final timingLine = flight.timing.isNotEmpty &&
          flight.timing != '—' &&
          flight.timing.toLowerCase() != 'no timing'
      ? '\n⏰ Timing: ${flight.timing}'
      : '';

  final fareStr = '₹${flight.marketedPrice.toInt()}/-';

  return '''Hi,
Please check availability for this flight:

✈️ Flight: $flightDisplay$connectionLine
📅 Date: $formattedDate
💰 Fare: $fareStr
📍 Sector: $srcAirport ($src) ➝ $dstAirport ($dst)$baggageLine$timingLine

Is this flight available for $fareStr on $formattedDate? Please confirm.''';
}

void copyInquiryMessageToClipboard(BuildContext context, String message) {
  Clipboard.setData(ClipboardData(text: message));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Inquiry message copied! Ready to paste into WhatsApp.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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

Future<void> _confirmAndDeleteFlight({
  required BuildContext context,
  required BuildContext dialogContext,
  required WidgetRef ref,
  required Flight flight,
  required String src,
  required String dst,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (confirmCtx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Flight Rate?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to permanently delete this flight entry from the sector table?',
              style: TextStyle(fontSize: 13, color: AppColors.buttonGrey),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 14, color: Color(0xFF991B1B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          flight.agencyName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${flight.airline} ${flight.flightNumber}${flight.via.isNotEmpty ? " (Via ${flight.via})" : ""}  •  ${flight.date}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$src ➝ $dst',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        '₹${flight.marketedPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Delete Now', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(confirmCtx).pop(true),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    try {
      await ref.read(flightRepositoryProvider).deleteFlight(flight.id);
      ref.invalidate(allFlightsProvider);
      ref.invalidate(fareBroadcastProvider);

      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deleted ${flight.airline} ${flight.flightNumber} (${flight.agencyName}) successfully.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete flight: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
