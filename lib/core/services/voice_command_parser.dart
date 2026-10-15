import 'dart:math';

class VoiceSearchResult {
  final String? src;
  final String? dst;
  final DateTime? date;
  final String rawTranscript;
  final String? srcName;
  final String? dstName;

  const VoiceSearchResult({
    this.src,
    this.dst,
    this.date,
    required this.rawTranscript,
    this.srcName,
    this.dstName,
  });

  bool get hasSector => src != null && dst != null;
  bool get hasDate => date != null;

  @override
  String toString() =>
      'VoiceSearchResult(src: $src ($srcName), dst: $dst ($dstName), date: $date, raw: "$rawTranscript")';
}

class VoiceCommandParser {
  static const Map<String, String> _airportAliases = {
    // Kerala
    'calicut': 'CCJ', 'kalicut': 'CCJ', 'calict': 'CCJ', 'kalict': 'CCJ',
    'calic': 'CCJ', 'kalic': 'CCJ', 'kalicot': 'CCJ', 'calicot': 'CCJ',
    'kalikat': 'CCJ', 'kalikot': 'CCJ', 'kozhikode': 'CCJ', 'kozhikod': 'CCJ',
    'kozhicode': 'CCJ', 'kozhicot': 'CCJ', 'karippur': 'CCJ', 'karipur': 'CCJ', 'ccj': 'CCJ',
    'cochin': 'COK', 'kochi': 'COK', 'cochi': 'COK', 'kochyn': 'COK',
    'nedumbassery': 'COK', 'nedumbasseri': 'COK', 'nedumbasseri airport': 'COK', 'cok': 'COK',
    'kannur': 'CNN', 'kanur': 'CNN', 'cannur': 'CNN', 'cannore': 'CNN',
    'mattannur': 'CNN', 'mattannoor': 'CNN', 'cnn': 'CNN',
    'trivandrum': 'TRV', 'thiruvananthapuram': 'TRV', 'trivandram': 'TRV', 'tvm': 'TRV', 'trv': 'TRV',

    // Other India
    'mangalore': 'IXE', 'mangaluru': 'IXE', 'manglore': 'IXE', 'mangalor': 'IXE', 'bajpe': 'IXE', 'ixe': 'IXE',
    'bangalore': 'BLR', 'bengaluru': 'BLR', 'banglore': 'BLR', 'blr': 'BLR',
    'chennai': 'MAA', 'madras': 'MAA', 'maa': 'MAA',
    'mumbai': 'BOM', 'bombay': 'BOM', 'bom': 'BOM',
    'delhi': 'DEL', 'new delhi': 'DEL', 'del': 'DEL',
    'goa': 'GOI', 'mopa': 'GOI', 'dabolim': 'GOI', 'goi': 'GOI',
    'hyderabad': 'HYD', 'hyd': 'HYD',
    'coimbatore': 'CJB', 'cjb': 'CJB',
    'trichy': 'TRZ', 'tiruchirappalli': 'TRZ', 'trz': 'TRZ',
    'madurai': 'IXM', 'ixm': 'IXM',
    'ahmedabad': 'AMD', 'amd': 'AMD',

    // UAE & Gulf
    'dubai': 'DXB', 'dubay': 'DXB', 'duba': 'DXB', 'dxb': 'DXB',
    'sharjah': 'SHJ', 'sharja': 'SHJ', 'sarjah': 'SHJ', 'sarja': 'SHJ', 'shj': 'SHJ',
    'abu dhabi': 'AUH', 'abudhabi': 'AUH', 'abudabi': 'AUH', 'abu dabi': 'AUH', 'auh': 'AUH',
    'ras al khaimah': 'RKT', 'rak': 'RKT', 'rkt': 'RKT',
    'al ain': 'AAN', 'alain': 'AAN', 'aan': 'AAN',
    'muscat': 'MCT', 'maskat': 'MCT', 'muskat': 'MCT', 'maskath': 'MCT', 'mct': 'MCT',
    'salalah': 'SLL', 'salala': 'SLL', 'sll': 'SLL', 'sal': 'SLL',
    'doha': 'DOH', 'qatar': 'DOH', 'doh': 'DOH',
    'bahrain': 'BAH', 'bahrein': 'BAH', 'bahrayn': 'BAH', 'manama': 'BAH', 'bah': 'BAH',
    'kuwait': 'KWI', 'kuwayt': 'KWI', 'kwi': 'KWI',
    'riyadh': 'RUH', 'riad': 'RUH', 'riyad': 'RUH', 'riyath': 'RUH', 'ruh': 'RUH',
    'jeddah': 'JED', 'jedda': 'JED', 'jiddah': 'JED', 'jidda': 'JED', 'jed': 'JED',
    'dammam': 'DMM', 'damam': 'DMM', 'dmm': 'DMM',

    // Far East
    'singapore': 'SIN', 'sin': 'SIN',
    'kuala lumpur': 'KUL', 'malaysia': 'KUL', 'kul': 'KUL',
    'colombo': 'CMB', 'sri lanka': 'CMB', 'cmb': 'CMB',
    'bangkok': 'BKK', 'thailand': 'BKK', 'bkk': 'BKK',
    'guangzhou': 'CAN', 'can': 'CAN',
  };

  static const Map<String, String> airportDisplayNames = {
    'CCJ': 'Calicut',
    'COK': 'Kochi',
    'CNN': 'Kannur',
    'TRV': 'Trivandrum',
    'IXE': 'Mangalore',
    'BLR': 'Bangalore',
    'MAA': 'Chennai',
    'BOM': 'Mumbai',
    'DEL': 'Delhi',
    'GOI': 'Goa',
    'HYD': 'Hyderabad',
    'CJB': 'Coimbatore',
    'TRZ': 'Trichy',
    'IXM': 'Madurai',
    'AMD': 'Ahmedabad',
    'DXB': 'Dubai',
    'SHJ': 'Sharjah',
    'AUH': 'Abu Dhabi',
    'RKT': 'Ras Al Khaimah',
    'AAN': 'Al Ain',
    'MCT': 'Muscat',
    'SLL': 'Salalah',
    'DOH': 'Doha',
    'BAH': 'Bahrain',
    'KWI': 'Kuwait',
    'RUH': 'Riyadh',
    'JED': 'Jeddah',
    'DMM': 'Dammam',
    'SIN': 'Singapore',
    'KUL': 'Kuala Lumpur',
    'CMB': 'Colombo',
    'BKK': 'Bangkok',
    'CAN': 'Guangzhou',
  };

  static const Map<String, int> _monthNames = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  static VoiceSearchResult parse(String rawText, {DateTime? now}) {
    final currentNow = now ?? DateTime.now();
    final text = rawText.toLowerCase().trim();

    final List<MapEntry<int, String>> matchedAirports = [];

    final sortedAliases = _airportAliases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final normalizedText = ' $text ';

    // 1. Exact alias match
    for (final alias in sortedAliases) {
      final code = _airportAliases[alias]!;
      final regex = RegExp(
        r'(?:^|[\s,.\-—–/]+)' + RegExp.escape(alias) + r'(?:$|[\s,.\-—–/]+)',
      );
      final matches = regex.allMatches(normalizedText);
      for (final m in matches) {
        matchedAirports.add(MapEntry(m.start, code));
      }
    }

    // 2. Fuzzy match for single words (allows 1 speech recognition typo)
    if (matchedAirports.length < 2) {
      final words = text
          .split(RegExp(r'[\s,.\-—–/]+'))
          .where((w) => w.length >= 4)
          .toList();
      for (final w in words) {
        if (_monthNames.containsKey(w) || int.tryParse(w) != null) continue;

        String? bestCode;
        int minDistance = 999;
        for (final alias in _airportAliases.keys) {
          if (alias.contains(' ')) continue;
          final dist = _levenshtein(w, alias);
          if (dist <= 1 && dist < minDistance) {
            minDistance = dist;
            bestCode = _airportAliases[alias];
          }
        }
        if (bestCode != null) {
          final idx = text.indexOf(w);
          if (!matchedAirports.any((e) => e.value == bestCode)) {
            matchedAirports.add(MapEntry(idx >= 0 ? idx : 0, bestCode));
          }
        }
      }
    }

    // Sort by position in text (first mentioned = source, second = destination)
    matchedAirports.sort((a, b) => a.key.compareTo(b.key));

    final List<String> distinctCodes = [];
    for (final entry in matchedAirports) {
      if (!distinctCodes.contains(entry.value)) {
        distinctCodes.add(entry.value);
      }
    }

    String? src;
    String? dst;
    if (distinctCodes.isNotEmpty) {
      src = distinctCodes[0];
      if (distinctCodes.length > 1) {
        dst = distinctCodes[1];
      }
    }

    final parsedDate = _parseDate(text, currentNow);

    return VoiceSearchResult(
      src: src,
      dst: dst,
      date: parsedDate,
      rawTranscript: rawText,
      srcName: src != null ? (airportDisplayNames[src] ?? src) : null,
      dstName: dst != null ? (airportDisplayNames[dst] ?? dst) : null,
    );
  }

  static DateTime? _parseDate(String text, DateTime now) {
    if (text.contains('day after tomorrow') || text.contains('day after 2mrw')) {
      return DateTime(now.year, now.month, now.day + 2);
    }
    if (text.contains('tomorrow') || text.contains('2mrw') || text.contains('naale')) {
      return DateTime(now.year, now.month, now.day + 1);
    }
    if (text.contains('today') || text.contains('innu')) {
      return DateTime(now.year, now.month, now.day);
    }

    for (final mName in _monthNames.keys) {
      final mNum = _monthNames[mName]!;
      // Month Day [Year] (e.g. "October 21", "Oct 21 2026")
      final p1 = RegExp(r'\b' + mName + r'\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s+(\d{4}))?\b');
      final match1 = p1.firstMatch(text);
      if (match1 != null) {
        final day = int.tryParse(match1.group(1)!);
        final year = int.tryParse(match1.group(2) ?? '') ??
            (mNum < now.month ? now.year + 1 : now.year);
        if (day != null && day >= 1 && day <= 31) {
          return DateTime(year, mNum, day);
        }
      }

      // Day Month [Year] (e.g. "21 October", "21st Oct")
      final p2 = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?\s+' + mName + r'(?:\s+(\d{4}))?\b');
      final match2 = p2.firstMatch(text);
      if (match2 != null) {
        final day = int.tryParse(match2.group(1)!);
        final year = int.tryParse(match2.group(2) ?? '') ??
            (mNum < now.month ? now.year + 1 : now.year);
        if (day != null && day >= 1 && day <= 31) {
          return DateTime(year, mNum, day);
        }
      }
    }

    // ISO: 2026-10-21
    final isoMatch = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b').firstMatch(text);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      return DateTime(y, m, d);
    }

    // DMY: 21/10 or 21-10 or 21/10/2026
    final dmyMatch = RegExp(r'\b(\d{1,2})[/\-](\d{1,2})(?:[/\-](\d{2,4}))?\b').firstMatch(text);
    if (dmyMatch != null) {
      final d = int.parse(dmyMatch.group(1)!);
      final m = int.parse(dmyMatch.group(2)!);
      var y = int.tryParse(dmyMatch.group(3) ?? '') ?? now.year;
      if (y < 100) y += 2000;
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // Day with suffix: "21st", "date 21"
    final bareDayMatch = RegExp(r'\b(?:on|date)?\s*(\d{1,2})(?:st|nd|rd|th)\b').firstMatch(text);
    if (bareDayMatch != null) {
      final day = int.tryParse(bareDayMatch.group(1)!);
      if (day != null && day >= 1 && day <= 31) {
        var m = now.month;
        var y = now.year;
        if (day < now.day) {
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
        }
        return DateTime(y, m, day);
      }
    }

    return null;
  }
}
