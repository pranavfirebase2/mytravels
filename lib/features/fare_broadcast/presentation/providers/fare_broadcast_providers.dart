import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytravels/features/agency/presentation/providers/agency_providers.dart';
import 'package:mytravels/features/flights/domain/entities/flight.dart';
import 'package:mytravels/features/flights/presentation/providers/flight_providers.dart';
import 'package:mytravels/features/fare_broadcast/domain/entities/broadcast_item.dart';

enum PriceDisplayMode {
  flightAndAmount, // e.g. "🔹 23 OCT  —  IX 733 - 21000"
  lowestAmount, // e.g. "🔹 23 OCT  —  21000/-"
  specialFareText, // e.g. "🔹 23 OCT  —  SPECIAL FARE"
  amountWithSpecialFare, // e.g. "🔹 23 OCT  —  IX 733 - ₹ 21,000 (SPECIAL FARE)"
}

class FareBroadcastConfig {
  final List<BroadcastSectorItem> sectors;
  final PriceDisplayMode priceMode;
  final double markup;
  final String contactName;
  final String contactPhone;
  final String communityLink;
  final String customHeader;
  final String customFooter;

  FareBroadcastConfig({
    required this.sectors,
    this.priceMode = PriceDisplayMode.flightAndAmount,
    this.markup = 0.0,
    this.contactName = 'Sorryjith',
    this.contactPhone = '+91 85900 72609',
    this.communityLink = 'https://chat.whatsapp.com/BnPq1svY2fWCraLCpUD5eo',
    this.customHeader =
        '✈️ 𝑨𝑬𝑹𝑶𝑺𝑷𝑯𝑬𝑹𝑬 𝑻𝑹𝑨𝑽𝑬𝑳𝑺 ✈️\n\n💎 *AEROSPERE | SPECIAL FARE* 💎\n\n🔥 *BEST DEALS* 🔥',
    this.customFooter =
        '📞 *BOOKING & ENQUIRIES*\n\n☎️ {PHONE}\n👤 *Contact Person: {NAME}*\n\n\n✈️ *AeroSphere Travels*\n✨ Your Trusted Travel Partner ✨\n\n📍 *Join our WhatsApp Community for Daily Updates:*\n{COMMUNITY_LINK}',
  });

  FareBroadcastConfig copyWith({
    List<BroadcastSectorItem>? sectors,
    PriceDisplayMode? priceMode,
    double? markup,
    String? contactName,
    String? contactPhone,
    String? communityLink,
    String? customHeader,
    String? customFooter,
  }) {
    return FareBroadcastConfig(
      sectors: sectors ?? this.sectors,
      priceMode: priceMode ?? this.priceMode,
      markup: markup ?? this.markup,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      communityLink: communityLink ?? this.communityLink,
      customHeader: customHeader ?? this.customHeader,
      customFooter: customFooter ?? this.customFooter,
    );
  }

  String generateBroadcastText() {
    final buffer = StringBuffer();

    // 1. Header
    buffer.writeln(customHeader.trim());
    buffer.writeln();

    // 2. Sectors & Deals
    final selectedSectors = sectors.where((s) => s.isSelected).toList();
    for (int i = 0; i < selectedSectors.length; i++) {
      final sector = selectedSectors[i];
      final activeDates = sector.dates.where((d) => d.isSelected).toList();
      if (activeDates.isEmpty) continue;

      // Sector Header
      final flightNumStr = sector.flightNumber.trim().isNotEmpty
          ? ' | ${sector.flightNumber.trim()}'
          : '';
      buffer.writeln('✈️ *${sector.source} ➝ ${sector.destination}$flightNumStr*');

      // Baggage
      final baggageStr = sector.baggage.trim().isNotEmpty
          ? sector.baggage.trim()
          : '30 KG';
      buffer.writeln('🧳 Baggage Allowance: $baggageStr');
      buffer.writeln();

      // Dates and Prices
      for (final date in activeDates) {
        final finalPrice = (date.lowestPrice + markup).round();
        final flightStr = date.flightNumber.trim().isNotEmpty
            ? date.flightNumber.trim()
            : sector.flightNumber.trim();
        final viaStr = date.via.trim().isNotEmpty
            ? ' (Via ${date.via.trim().toUpperCase()})'
            : '';
        String fareText = '';

        switch (priceMode) {
          case PriceDisplayMode.flightAndAmount:
            if (flightStr.isNotEmpty) {
              fareText = '$flightStr - $finalPrice$viaStr';
            } else {
              fareText = '$finalPrice$viaStr';
            }
            break;
          case PriceDisplayMode.specialFareText:
            fareText = 'SPECIAL FARE$viaStr';
            break;
          case PriceDisplayMode.lowestAmount:
            fareText = '$finalPrice/-$viaStr';
            break;
          case PriceDisplayMode.amountWithSpecialFare:
            if (flightStr.isNotEmpty) {
              fareText = '$flightStr - ₹ $finalPrice (SPECIAL FARE)$viaStr';
            } else {
              fareText = '₹ $finalPrice (SPECIAL FARE)$viaStr';
            }
            break;
        }

        buffer.writeln('🔹 ${date.displayDate}  —  $fareText');
      }

      // Spacing between sectors
      buffer.writeln();
    }

    // 3. Footer
    String footer = customFooter
        .replaceAll('{PHONE}', contactPhone)
        .replaceAll('{NAME}', contactName)
        .replaceAll('{COMMUNITY_LINK}', communityLink);
    buffer.writeln(footer.trim());

    return buffer.toString().trim();
  }
}

class FareBroadcastNotifier extends AsyncNotifier<FareBroadcastConfig> {
  @override
  Future<FareBroadcastConfig> build() async {
    final flights = await ref.watch(allFlightsProvider.future);
    final agencies = await ref.watch(agenciesStreamProvider.future);

    final agencyDeductions = <String, double>{};
    for (var a in agencies) {
      agencyDeductions[a.name] = a.comparisonDeduction;
    }

    final sectors = _computeBroadcastSectors(flights, agencyDeductions);
    return FareBroadcastConfig(sectors: sectors);
  }

  List<BroadcastSectorItem> _computeBroadcastSectors(
    List<Flight> flights,
    Map<String, double> agencyDeductions,
  ) {
    // 1. Group flights by sector key: SRC-DST
    final Map<String, List<Flight>> sectorMap = {};
    for (final f in flights) {
      final src = f.source.trim().toUpperCase();
      final dst = f.destination.trim().toUpperCase();
      if (src.length != 3 || dst.length != 3) continue;

      final key = '$src-$dst';
      sectorMap.putIfAbsent(key, () => []).add(f);
    }

    final List<BroadcastSectorItem> result = [];

    // 2. Process each sector
    final sortedKeys = sectorMap.keys.toList()..sort();
    for (final key in sortedKeys) {
      final sectorFlights = sectorMap[key]!;
      final parts = key.split('-');
      final src = parts[0];
      final dst = parts[1];

      // Group by date
      final Map<String, List<Flight>> dateMap = {};
      for (final f in sectorFlights) {
        final d = f.date.trim();
        if (d.isNotEmpty) {
          dateMap.putIfAbsent(d, () => []).add(f);
        }
      }

      final List<BroadcastDateItem> dateItems = [];
      String mostCommonFlightNumber = '';
      String mostCommonBaggage = '30 KG';
      final Map<String, int> flightNumFreq = {};
      final Map<String, int> baggageFreq = {};

      // For each date, find lowest fare flight
      for (final entry in dateMap.entries) {
        final rawDate = entry.key;
        final list = entry.value;

        Flight? lowestFlight;
        double minPrice = double.infinity;

        for (final f in list) {
          final ded = agencyDeductions[f.agencyName] ?? 0.0;
          final adjusted = f.marketedPrice - ded;
          if (adjusted < minPrice) {
            minPrice = adjusted;
            lowestFlight = f;
          }

          // Count frequencies for default sector flight number & baggage
          final fn = _formatFlightNumber(f.airline, f.flightNumber);
          if (fn.isNotEmpty) {
            flightNumFreq[fn] = (flightNumFreq[fn] ?? 0) + 1;
          }
          final bg = f.baggage.trim();
          if (bg.isNotEmpty) {
            baggageFreq[bg] = (baggageFreq[bg] ?? 0) + 1;
          }
        }

        if (lowestFlight != null && minPrice != double.infinity) {
          // Format date: e.g. "17-Oct" -> "17 OCT"
          final displayDate = rawDate
              .replaceAll('-', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .toUpperCase();

          final parsedDate = lowestFlight.parsedDate ?? _parseFlightDate(rawDate);
          final dateFlightNum = _formatFlightNumber(
            lowestFlight.airline,
            lowestFlight.flightNumber,
          );

          dateItems.add(
            BroadcastDateItem(
              rawDate: rawDate,
              displayDate: displayDate,
              lowestPrice: minPrice,
              agencyName: lowestFlight.agencyName,
              flightNumber: dateFlightNum,
              baggage: lowestFlight.baggage.trim().isNotEmpty
                  ? lowestFlight.baggage.trim()
                  : '30 KG',
              parsedDate: parsedDate,
              via: lowestFlight.via,
              isSelected: true,
            ),
          );
        }
      }

      // Sort dates chronologically
      dateItems.sort((a, b) {
        if (a.parsedDate != null && b.parsedDate != null) {
          return a.parsedDate!.compareTo(b.parsedDate!);
        }
        final aNum = int.tryParse(RegExp(r'^\d+').stringMatch(a.displayDate) ?? '') ?? 0;
        final bNum = int.tryParse(RegExp(r'^\d+').stringMatch(b.displayDate) ?? '') ?? 0;
        return aNum.compareTo(bNum);
      });

      if (flightNumFreq.isNotEmpty) {
        mostCommonFlightNumber = flightNumFreq.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
      if (baggageFreq.isNotEmpty) {
        mostCommonBaggage = baggageFreq.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      if (dateItems.isNotEmpty) {
        result.add(
          BroadcastSectorItem(
            source: src,
            destination: dst,
            flightNumber: mostCommonFlightNumber,
            baggage: mostCommonBaggage,
            isSelected: true,
            dates: dateItems,
          ),
        );
      }
    }

    return result;
  }

  void toggleSector(int index, bool selected) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      sectors[index].isSelected = selected;
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void toggleAllSectors(bool selectAll) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      for (var s in sectors) {
        s.isSelected = selectAll;
      }
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void toggleDate(int sectorIndex, int dateIndex, bool selected) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      sectors[sectorIndex].dates[dateIndex].isSelected = selected;
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void updateSectorFlightNumber(int sectorIndex, String flightNumber) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      sectors[sectorIndex].flightNumber = flightNumber;
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void updateSectorBaggage(int sectorIndex, String baggage) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      sectors[sectorIndex].baggage = baggage;
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void setPriceMode(PriceDisplayMode mode) {
    state.whenData((config) {
      state = AsyncValue.data(config.copyWith(priceMode: mode));
    });
  }

  void setMarkup(double markup) {
    state.whenData((config) {
      state = AsyncValue.data(config.copyWith(markup: markup));
    });
  }

  void updateContactDetails({String? name, String? phone, String? communityLink}) {
    state.whenData((config) {
      state = AsyncValue.data(config.copyWith(
        contactName: name ?? config.contactName,
        contactPhone: phone ?? config.contactPhone,
        communityLink: communityLink ?? config.communityLink,
      ));
    });
  }

  void updateHeader(String header) {
    state.whenData((config) {
      state = AsyncValue.data(config.copyWith(customHeader: header));
    });
  }

  void updateDateFlightNumber(int sectorIndex, int dateIndex, String flightNumber) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      sectors[sectorIndex].dates[dateIndex].flightNumber = flightNumber;
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void updateDatePrice(int sectorIndex, int dateIndex, double price) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      sectors[sectorIndex].dates[dateIndex].lowestPrice = price;
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void updateDateVia(int sectorIndex, int dateIndex, String via) {
    state.whenData((config) {
      final sectors = List<BroadcastSectorItem>.from(config.sectors);
      sectors[sectorIndex].dates[dateIndex].via = via;
      state = AsyncValue.data(config.copyWith(sectors: sectors));
    });
  }

  void updateFooter(String footer) {
    state.whenData((config) {
      state = AsyncValue.data(config.copyWith(customFooter: footer));
    });
  }
}

String _formatFlightNumber(String airline, String flightNumber) {
  airline = airline.trim().toUpperCase();
  flightNumber = flightNumber.trim().toUpperCase();
  if (flightNumber.isEmpty) return airline == '—' ? '' : airline;
  if (airline.isEmpty || airline == '—') return flightNumber;
  if (flightNumber.startsWith(airline)) return flightNumber;
  return '$airline $flightNumber';
}

final fareBroadcastProvider =
    AsyncNotifierProvider<FareBroadcastNotifier, FareBroadcastConfig>(() {
  return FareBroadcastNotifier();
});

DateTime? _parseFlightDate(String dateStr) {
  try {
    final cleaned = dateStr.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    const months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
    };
    int? day;
    int? month;
    int? year;

    for (var p in parts) {
      final upper = p.toUpperCase();
      if (months.containsKey(upper)) {
        month = months[upper];
      } else {
        final val = int.tryParse(p);
        if (val != null) {
          if (val > 31) {
            year = val;
          } else if (day == null) {
            day = val;
          } else if (month == null && val <= 12) {
            month = val;
          } else {
            year ??= val;
          }
        }
      }
    }

    if (day != null && month != null) {
      final now = DateTime.now();
      year ??= now.year;
      return DateTime(year, month, day);
    }
  } catch (_) {}
  return null;
}
