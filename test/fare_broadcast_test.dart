import 'package:flutter_test/flutter_test.dart';
import 'package:mytravels/features/fare_broadcast/domain/entities/broadcast_item.dart';
import 'package:mytravels/features/fare_broadcast/presentation/providers/fare_broadcast_providers.dart';

void main() {
  group('FareBroadcast Generator Tests', () {
    test('generateBroadcastText produces exact user template', () {
      final config = FareBroadcastConfig(
        sectors: [
          BroadcastSectorItem(
            source: 'CCJ',
            destination: 'DOH',
            flightNumber: 'IX 375',
            baggage: '30 KG',
            dates: [
              BroadcastDateItem(
                rawDate: '17-Oct',
                displayDate: '17 OCT',
                lowestPrice: 12500,
                agencyName: 'Agency A',
                flightNumber: 'IX 375',
                baggage: '30 KG',
              ),
              BroadcastDateItem(
                rawDate: '18-Oct',
                displayDate: '18 OCT',
                lowestPrice: 12800,
                agencyName: 'Agency B',
                flightNumber: 'IX 375',
                baggage: '30 KG',
              ),
              BroadcastDateItem(
                rawDate: '19-Oct',
                displayDate: '19 OCT',
                lowestPrice: 13100,
                agencyName: 'Agency A',
                flightNumber: 'IX 375',
                baggage: '30 KG',
              ),
              BroadcastDateItem(
                rawDate: '20-Oct',
                displayDate: '20 OCT',
                lowestPrice: 13500,
                agencyName: 'Agency C',
                flightNumber: 'IX 375',
                baggage: '30 KG',
              ),
            ],
          ),
          BroadcastSectorItem(
            source: 'CCJ',
            destination: 'DXB',
            flightNumber: 'IX 343',
            baggage: '30 KG',
            dates: [
              BroadcastDateItem(
                rawDate: '18-Oct',
                displayDate: '18 OCT',
                lowestPrice: 11000,
                agencyName: 'Agency A',
                flightNumber: 'IX 343',
                baggage: '30 KG',
              ),
              BroadcastDateItem(
                rawDate: '19-Oct',
                displayDate: '19 OCT',
                lowestPrice: 11200,
                agencyName: 'Agency B',
                flightNumber: 'IX 343',
                baggage: '30 KG',
              ),
              BroadcastDateItem(
                rawDate: '20-Oct',
                displayDate: '20 OCT',
                lowestPrice: 11500,
                agencyName: 'Agency A',
                flightNumber: 'IX 343',
                baggage: '30 KG',
              ),
              BroadcastDateItem(
                rawDate: '23-Oct',
                displayDate: '23 OCT',
                lowestPrice: 11900,
                agencyName: 'Agency C',
                flightNumber: 'IX 343',
                baggage: '30 KG',
              ),
            ],
          ),
        ],
        priceMode: PriceDisplayMode.specialFareText,
        contactName: 'Sooryajith',
        contactPhone: '+91 85900 72609',
      );

      final result = config.generateBroadcastText();

      final expected = '''
✈️ 𝑨𝑬𝑹𝑶𝑺𝑷𝑯𝑬𝑹𝑬 𝑻𝑹𝑨𝑽𝑬𝑳𝑺 ✈️

💎 *AEROSPERE | SPECIAL FARE* 💎

🔥 *BEST DEALS* 🔥

✈️ *CCJ ➝ DOH | IX 375*
🧳 Baggage Allowance: 30 KG

🔹 17 OCT  —  SPECIAL FARE
🔹 18 OCT  —  SPECIAL FARE
🔹 19 OCT  —  SPECIAL FARE
🔹 20 OCT  —  SPECIAL FARE

✈️ *CCJ ➝ DXB | IX 343*
🧳 Baggage Allowance: 30 KG

🔹 18 OCT  —  SPECIAL FARE
🔹 19 OCT  —  SPECIAL FARE
🔹 20 OCT  —  SPECIAL FARE
🔹 23 OCT  —  SPECIAL FARE

📞 *BOOKING & ENQUIRIES*

☎️ +91 85900 72609
👤 *Contact Person: Sooryajith*


✈️ *AeroSphere Travels*
✨ Your Trusted Travel Partner ✨

📍 *Join our WhatsApp Community for Daily Updates:*
https://chat.whatsapp.com/BnPq1svY2fWCraLCpUD5eo'''.trim();

      expect(result, equals(expected));
    });

    test('generateBroadcastText outputs actual lowest fare prices when priceMode is lowestAmount', () {
      final config = FareBroadcastConfig(
        sectors: [
          BroadcastSectorItem(
            source: 'CCJ',
            destination: 'DOH',
            flightNumber: 'IX 375',
            baggage: '30 KG',
            dates: [
              BroadcastDateItem(
                rawDate: '17-Oct',
                displayDate: '17 OCT',
                lowestPrice: 12500,
                agencyName: 'Agency A',
                flightNumber: 'IX 375',
                baggage: '30 KG',
              ),
            ],
          ),
        ],
        priceMode: PriceDisplayMode.lowestAmount,
        markup: 500,
      );

      final text = config.generateBroadcastText();
      expect(text.contains('🔹 17 OCT  —  13000/-'), isTrue);
    });

    test('generateBroadcastText outputs Flight and Amount format by default with 300 margin', () {
      final config = FareBroadcastConfig(
        sectors: [
          BroadcastSectorItem(
            source: 'CCJ',
            destination: 'DXB',
            flightNumber: 'IX 343',
            baggage: '30 KG',
            dates: [
              BroadcastDateItem(
                rawDate: '23-Oct',
                displayDate: '23 OCT',
                lowestPrice: 21000,
                agencyName: 'Agency A',
                flightNumber: 'IX 733',
                baggage: '30 KG',
              ),
            ],
          ),
        ],
        priceMode: PriceDisplayMode.flightAndAmount,
      );

      final text = config.generateBroadcastText();
      // Default margin is 300, so 21000 + 300 = 21300
      expect(text.contains('🔹 23 OCT  —  IX 733 - 21300'), isTrue);

      final noMarginText = config.copyWith(markup: 0).generateBroadcastText();
      expect(noMarginText.contains('🔹 23 OCT  —  IX 733 - 21000'), isTrue);
    });

    test('generateBroadcastText outputs (Via MCT) for connecting flights', () {
      final config = FareBroadcastConfig(
        sectors: [
          BroadcastSectorItem(
            source: 'CCJ',
            destination: 'SHJ',
            flightNumber: 'OV 774/241',
            baggage: '20+5 KG',
            dates: [
              BroadcastDateItem(
                rawDate: '21-Oct',
                displayDate: '21 OCT',
                lowestPrice: 19500,
                agencyName: 'Agency A',
                flightNumber: 'OV 774/241',
                baggage: '20+5 KG',
                via: 'MCT',
              ),
            ],
          ),
        ],
        priceMode: PriceDisplayMode.flightAndAmount,
      );

      final text = config.generateBroadcastText();
      // Default margin is 300, so 19500 + 300 = 19800
      expect(text.contains('🔹 21 OCT  —  OV 774/241 - 19800 (Via MCT)'), isTrue);
    });
  });
}
