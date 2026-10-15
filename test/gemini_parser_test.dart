import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytravels/core/network/gemini_service.dart';

void main() {
  test('GeminiService parses updated fare format correctly', () async {
    final sample = '''*UPDATED FARE*

*20 KG BAGGAGE 🎒J9 406*
COK KWI J9 18 OCT 25000 1 SEAT
COK KWI J9 19 OCT 24000
COK KWI J9 22 OCT 22500
COK KWI J9 23 OCT 22000
COK KWI J9 26 OCT 23500
===================
*30 KG BAGGAGE 🎒6E 1438*
IXE AUH 6E 16 OCT 21000 2 SEAT
===================
*30 KG BAGGAGE 🎒IX 857*
IXE KWI IX 25 OCT 19500
===================
*30 KG BAGGAGE 🎒IX 741&745*
CNN SHJ IX 15 OCT 23000 1 SEAT
CNN SHJ IX 16 OCT 24000 1 SEAT
CNN SHJ IX 17 OCT 23500 MRNG 
CNN SHJ IX 18 OCT 24500 MRNG 
CNN SHJ IX 19 OCT 23500 MRNG 
CNN SHJ IX 20 OCT 22500
CNN SHJ IX 21 OCT 22000 MRNG 
CNN SHJ IX 21 OCT 23000
CNN SHJ IX 22 OCT 22000 MRNG 
CNN SHJ IX 22 OCT 22500
CNN SHJ IX 23 OCT 22000 MRNG 
CNN SHJ IX 23 OCT 22500
CNN SHJ IX 24 OCT 22500 MRNG
===================
*30 KG BAGGAGE 🎒IX 747*
CNN DXB IX 18 OCT 26000 1 SEAT
CNN DXB IX 19 OCT 24500 1 SEAT
CNN DXB IX 20 OCT 23000
CNN DXB IX 21 OCT 22500
CNN DXB IX 22 OCT 22500
CNN DXB IX 23 OCT 22500
CNN DXB IX 24 OCT 22500
===================
*30 KG BAGGAGE 🎒IX 751*
CNN RKT IX 18 OCT 23000 2 SEAT
CNN RKT IX 23 OCT 21000
===================
*30 KG BAGGAGE 🎒6E 1325*
CNN DOH 6E 18 OCT 21500
CNN DOH 6E 19 OCT 21500
CNN DOH 6E 22 OCT 22500
CNN DOH 6E 23 OCT 21000
CNN DOH 6E 24 OCT 21000
===================
*30 KG BAGGAGE 🎒IX 773*
CNN DOH IX 19 OCT 21500
CNN DOH IX 20 OCT 22000
CNN DOH IX 21 OCT 22000
CNN DOH IX 23 OCT 20500
CNN DOH IX 24 OCT 21500
===================
*30 KG BAGGAGE 🎒IX 789*
CNN RUH IX 18 OCT 20500
CNN RUH IX 19 OCT 20500
CNN RUH IX 22 OCT 20500
===================
*30 KG BAGGAGE 🎒IX 321*
CCJ RUH IX 16 OCT 17000
CCJ RUH IX 17 OCT 17000
CCJ RUH IX 18 OCT 17000
CCJ RUH IX 19 OCT 17000
CCJ RUH IX 20 OCT 17000
CCJ RUH IX 21 OCT 17000
CCJ RUH IX 22 OCT 17000
=================
*30 KG BAGGAGE 🎒XY 328&374*
CCJ RUH XY 19 OCT 25000 2 SEAT
CCJ RUH XY 20 OCT 25000
CCJ RUH XY 21 OCT 26000 1 SEAT
=================
*30 KG BAGGAGE 🎒IX 347*
CCJ AUH IX 19 OCT 20500
CCJ AUH IX 21 OCT 20000
CCJ AUH IX 22 OCT 19500
CCJ AUH IX 23 OCT 19500
CCJ AUH IX 25 OCT 19000
=================
*30 KG BAGGAGE 🎒IX 353&351*
CCJ SHJ IX 17 OCT 25500 1 SEAT
CCJ SHJ IX 18 OCT 24500 2 SEAT
CCJ SHJ IX 19 OCT 23000
CCJ SHJ IX 20 OCT 23000 MRNG
CCJ SHJ IX 20 OCT 23500
CCJ SHJ IX 21 OCT 23000
CCJ SHJ IX 22 OCT 22500
CCJ SHJ IX 23 OCT 21500
CCJ SHJ IX 24 OCT 21500 MRNG
CCJ SHJ IX 24 OCT 22000
=================
*20 KG BAGGAGE 🎒G9 729*
CCJ RKT G9 22 OCT 22000
CCJ RKT G9 23 OCT 21500
=================
*30 KG BAGGAGE 🎒IX 335*
CCJ AAN IX 19 OCT 22000
CCJ AAN IX 21 OCT 22000 2 SEAT
CCJ AAN IX 25 OCT 21500
=================
*30 KG BAGGAGE 🎒IX 343*
CCJ DXB IX 19 OCT 24000
CCJ DXB IX 20 OCT 23000
CCJ DXB IX 23 OCT 23000
CCJ DXB IX 25 OCT 23000
=================
*30 KG BAGGAGE 🎒6E 1473*
CCJ DXB 6E 19 OCT 24000
CCJ DXB 6E 20 OCT 24000
CCJ DXB 6E 21 OCT 23000
CCJ DXB 6E 22 OCT 23000
CCJ DXB 6E 24 OCT 23000
=================
*30 KG BAGGAGE 🎒FZ 430*
CCJ DXB FZ 20 OCT 26000 2 SEAT
CCJ DXB FZ 24 OCT 23500 
=================
*30 KG BAGGAGE 🎒IX 337*
CCJ MCT IX 20 OCT 11000
CCJ MCT IX 22 OCT 11000
CCJ MCT IX 24 OCT 11500
=================
*30 KG BAGGAGE 🎒IX 375*
CCJ DOH IX 17 OCT 23000 1 SEAT
CCJ DOH IX 19 OCT 22500
CCJ DOH IX 21 OCT 22500
CCJ DOH IX 22 OCT 23000
CCJ DOH IX 23 OCT 23000
CCJ DOH IX 24 OCT 23000
===================
*30 KG BAGGAGE 🎒IX 391*
CCJ KWI IX 21 OCT 26000
CCJ KWI IX 22 OCT 25000
===================
*30 KG BAGGAGE 🎒IX 477*
COK DOH IX 16 OCT 18500 1 SEAT 
COK DOH IX 17 OCT 18500
COK DOH IX 18 OCT 18000
COK DOH IX 19 OCT 18000
COK DOH IX 21 OCT 18000 
COK DOH IX 22 OCT 18000
=================
*30 KG BAGGAGE 🎒IX 425*
COK DXB IX 20 OCT 20500 
COK DXB IX 22 OCT 20500
==================
*30 KG BAGGAGE 🎒IX 373*
CCJ BAH IX 17 OCT 18000
CCJ BAH IX 19 OCT 18500
CCJ BAH IX 22 OCT 18500
==================''';

    final service = GeminiService();
    final flights = await service.parseFlightData(sample);
    expect(flights.length, equals(105));

    // Verify first flight: J9 406 with 20 KG
    expect(flights[0]['source'], equals('COK'));
    expect(flights[0]['destination'], equals('KWI'));
    expect(flights[0]['date'], equals('18 OCT'));
    expect(flights[0]['airline'], equals('J9'));
    expect(flights[0]['flightNumber'], equals('406'));
    expect(flights[0]['baggage'], equals('20 KG'));
    expect(flights[0]['seats'], equals('1'));
    expect(flights[0]['marketedPrice'], equals(25000.0));

    // Verify 6E 1438 with 30 KG
    final f6e = flights.firstWhere((f) => f['source'] == 'IXE' && f['destination'] == 'AUH');
    expect(f6e['airline'], equals('6E'));
    expect(f6e['flightNumber'], equals('1438'));
    expect(f6e['baggage'], equals('30 KG'));
    expect(f6e['seats'], equals('2'));
    expect(f6e['marketedPrice'], equals(21000.0));

    // Verify dual flight number IX 741&745
    final fDual = flights.firstWhere((f) => f['source'] == 'CNN' && f['destination'] == 'SHJ');
    expect(fDual['airline'], equals('IX'));
    expect(fDual['flightNumber'], equals('741&745'));
    expect(fDual['baggage'], equals('30 KG'));

    // Verify XY 328&374
    final fXy = flights.firstWhere((f) => f['airline'] == 'XY');
    expect(fXy['flightNumber'], equals('328&374'));
    expect(fXy['baggage'], equals('30 KG'));
    expect(fXy['source'], equals('CCJ'));
    expect(fXy['destination'], equals('RUH'));

    // Verify G9 729 with 20 KG
    final fG9 = flights.firstWhere((f) => f['airline'] == 'G9');
    expect(fG9['flightNumber'], equals('729'));
    expect(fG9['baggage'], equals('20 KG'));

    // Verify all 105 flights have valid non-empty values
    for (final f in flights) {
      expect(f['source'], isNotEmpty);
      expect(f['destination'], isNotEmpty);
      expect(f['date'], isNotEmpty);
      expect(f['airline'], isNot('—'));
      expect(f['flightNumber'], isNot('—'));
      expect(f['baggage'], isNot('—'));
      expect(f['marketedPrice'], greaterThan(0));
    }
  });

  test('GeminiService parses previous infant fare sample correctly', () async {
    final text = File('/Users/pranav/.gemini/antigravity-ide/brain/bb257f40-a64c-479c-ad4a-7d29bd5ed327/scratch/user_pasted_text.txt').readAsStringSync();
    final service = GeminiService();
    final flights = await service.parseFlightData(text);
    expect(flights.length, greaterThan(30));

    // Check CCJ RKT IX 331 inherited properly and not overwritten by infant fare 10KG
    final rktFlights = flights.where((f) => f['source'] == 'CCJ' && f['destination'] == 'RKT').toList();
    expect(rktFlights.length, equals(3));
    for (final rf in rktFlights) {
      expect(rf['airline'], equals('IX'));
      expect(rf['flightNumber'], equals('331'));
      expect(rf['baggage'], equals('30+7 KG'));
    }
  });

  test('GeminiService parses FlyUnited special fares format correctly', () async {
    const text = '''*FLYUNITED SPECIAL FARES ALERT* ⚡
*━━━━━━━━━━━━━━━*

*📍 COCHIN → BAHRAIN(IX 471)*
🧳 30KG Checked Baggage

✦ 21 OCT— 18500
✦ 23 OCT— 18000
━━━━━━━━━━━━━━━
*📍 COCHIN → SHARJAH (IX 411)*
🧳 30KG Checked Baggage

✦ 18 OCT —  23500 1💺
✦ 20 OCT —  21000 1💺
✦ 21 OCT —  21000
✦ 22 OCT —  21000
✦ 23 OCT —  20000
━━━━━━━━━━━━━━━
*📍 COCHIN → DUBAI (IX 431)*
🧳 30KG Checked Baggage

✦ 17 OCT — 24000 1💺
✦ 19 OCT — 19500
✦ 20 OCT — 20500
✦ 21 OCT — 19000
✦ 22 OCT — 19500
✦ 23 OCT — 19500
━━━━━━━━━━━━━━━
*📍 KOCHI → ABU DHABI (IX 415)*
🧳 30KG Checked Baggage
  
✦ 19 OCT — 17500
✦ 21 OCT — 16500
✦ 23 OCT — 16500
━━━━━━━━━━━━━━━
*🛟 KANNUR → MUSCAT (IX 711)*
🧳 30KG Checked Baggage

✦ 21 OCT — 14000
✦ 23 OCT — 14000
━━━━━━━━━━━━━━━
*🛟 KANNUR → SHARJAH(IX 745)*
🧳 30KG Checked Baggage

✦ 18 OCT — 24000 1💺
✦ 20 OCT — 23000 1💺
✦ 21 OCT — 21500
✦ 22 OCT — 21500
*━━━━━━━━━━━━━━━*''';

    final service = GeminiService();
    final flights = await service.parseFlightData(text);
    expect(flights.length, equals(22));

    // Verify first flight: COK -> BAH
    expect(flights[0]['source'], equals('COK'));
    expect(flights[0]['destination'], equals('BAH'));
    expect(flights[0]['airline'], equals('IX'));
    expect(flights[0]['flightNumber'], equals('471'));
    expect(flights[0]['baggage'], equals('30 KG'));
    expect(flights[0]['marketedPrice'], equals(18500.0));

    // Verify seat emoji 1💺 captured
    final seatFlight = flights.firstWhere((f) => f['date'] == '18 OCT' && f['destination'] == 'SHJ');
    expect(seatFlight['seats'], equals('1'));
    expect(seatFlight['marketedPrice'], equals(23500.0));
  });

  test('GeminiService parses Group fare with date ranges and comma lists correctly', () async {
    const text = '''Todays Fare		
_*Group-1*_		
*COK-DXB*		
15-Oct		13000
16,17-Oct	12700
18-Oct		13000
19-25-Oct	12500
26-31-Oct	13000
01-10-Nov	13500
11-30-Nov	13700
*CCJ-DXB*		
15-Oct		16500
16-Oct		16300
17-Oct		15500
18-Oct		13900
19-Oct		13700		
21-24-Oct	13500
		
_*Group-2*_		
*TRV-DXB*		
19-Oct		17500
20-Oct		17900
21-Oct		17500
22-Oct		16200
23-Oct		17000
24-Oct		17500		
*TRV-SHJ*		
18-Oct		17900
19-Oct		18500		
21-Oct		17300
22-24-Oct	16900		
*TRV-AUH*		
19-Oct		15500		
21-Oct		15000		
23-Oct		14900		
*IXE-DXB*		
19,21-Oct	21900		
22-24-Oct	21500		
*TRZ-DXB*		
20-21-Oct	15500
22-24-Oct	14900
25-Oct		14500
26-Oct		14900
27-31-Oct	14500		
*CNN-SHJ*		
23,25-Oct	19500				
27-Oct		18900		
*CNN-DXB*		
26,27-Oct	19500		
*CNN-RKT*		
26-Oct		17900	
*CCJ-RKT*		
18-Oct		20900
19-Oct		20500		
21,23-Oct	19500				
*CCJ-SHJ*		
24,26-Oct	19500				
*CCJ-DXB*		
20-Oct		22500	
22-Oct		21500		
24-Oct		20900
25,26-Oct	20500
27-Oct		19900
		
_*Group-3*_		
*CCJ-RKT*		
21-23,25-Oct	19900
26,29,30-Oct	19500		
*In case of flight cancellation, only a full refund will be provided*''';

    final service = GeminiService();
    final flights = await service.parseFlightData(text);
    expect(flights.length, equals(113));

    // Verify first flight: COK -> DXB (Group 1: SpiceJet SG)
    expect(flights[0]['source'], equals('COK'));
    expect(flights[0]['destination'], equals('DXB'));
    expect(flights[0]['date'], equals('15 OCT'));
    expect(flights[0]['airline'], equals('SG'));
    expect(flights[0]['marketedPrice'], equals(13000.0));

    // Verify Group 2 (TRV-DXB: Air India Express IX)
    final trvFlight = flights.firstWhere((f) => f['source'] == 'TRV' && f['destination'] == 'DXB');
    expect(trvFlight['airline'], equals('IX'));

    // Verify Group 3 (CCJ-RKT: IndiGo 6E)
    final g3Flight = flights.firstWhere((f) => f['source'] == 'CCJ' && f['destination'] == 'RKT' && f['marketedPrice'] == 19900.0);
    expect(g3Flight['airline'], equals('6E'));

    // Verify expanded November dates
    final novFlight = flights.firstWhere((f) => f['date'] == '1 NOV' && f['source'] == 'COK');
    expect(novFlight['airline'], equals('SG'));
    expect(novFlight['marketedPrice'], equals(13500.0));

    // Verify mixed range + comma: 21-23,25-Oct
    final mixedSectorFlights = flights.where((f) => f['source'] == 'CCJ' && f['destination'] == 'RKT' && f['marketedPrice'] == 19900.0).toList();
    expect(mixedSectorFlights.length, equals(4)); // 21, 22, 23, 25 OCT
    for (final mf in mixedSectorFlights) {
      expect(mf['airline'], equals('6E'));
    }
  });

  test('GeminiService parses connecting / via flights (e.g. CCJ MCT SHJ) correctly', () async {
    final sample = '''
*CCJ MCT SHJ OV 774/241 20+5*
CCJ MCT SHJ 21 OCT 19500
CCJ MCT SHJ 26 OCT 19500
CCJ MCT SHJ 27 OCT 19500
CCJ MCT SHJ 29 OCT 19000
''';

    final service = GeminiService();
    final flights = await service.parseFlightData(sample);

    expect(flights.length, equals(4));
    for (var f in flights) {
      expect(f['source'], equals('CCJ'));
      expect(f['destination'], equals('SHJ'));
      expect(f['via'], equals('MCT'));
      expect(f['airline'], equals('OV'));
      expect(f['baggage'], equals('20+5 KG'));
    }
    expect(flights[0]['date'], equals('21 OCT'));
    expect(flights[0]['marketedPrice'], equals(19500.0));
  });
}
