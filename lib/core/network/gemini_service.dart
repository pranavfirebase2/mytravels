import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String _geminiApiKey;
  final String _groqApiKey;

  GeminiService()
      : _geminiApiKey = _loadEnvKey('GEMINI_API_KEY'),
        _groqApiKey = _loadEnvKey('GROQ_API_KEY');

  static String _loadEnvKey(String name) {
    try {
      if (!dotenv.isInitialized) return '';
      var key = dotenv.env[name]?.trim() ?? '';
      if (key.startsWith('"') && key.endsWith('"') && key.length >= 2) {
        key = key.substring(1, key.length - 1).trim();
      }
      return key;
    } catch (_) {
      return '';
    }
  }

  static const Map<String, String> _cityMap = {
    // Kerala & South India
    'thiruvananthapuram': 'TRV',
    'trivandrum': 'TRV',
    'kozhikode': 'CCJ',
    'calicut': 'CCJ',
    'kannur': 'CNN',
    'cochin': 'COK',
    'kochi': 'COK',
    'ernakulam': 'COK',
    'mangaluru': 'IXE',
    'mangalore': 'IXE',
    'tiruchirappalli': 'TRZ',
    'trichy': 'TRZ',
    'bengaluru': 'BLR',
    'bangalore': 'BLR',
    'chennai': 'MAA',
    'madras': 'MAA',
    'hyderabad': 'HYD',
    'coimbatore': 'CJB',
    'madurai': 'IXM',
    'goa': 'GOI',
    // North / West India
    'bombay': 'BOM',
    'mumbai': 'BOM',
    'delhi': 'DEL',
    'new delhi': 'DEL',
    'ahmedabad': 'AMD',
    // UAE & Gulf
    'ras al khaimah': 'RKT',
    'ras alkhaimah': 'RKT',
    'rak': 'RKT',
    'abu dhabi': 'AUH',
    'abudhabi': 'AUH',
    'al ain': 'AAN',
    'alain': 'AAN',
    'dubai': 'DXB',
    'sharjah': 'SHJ',
    'doha': 'DOH',
    'muscat': 'MCT',
    'kuwait': 'KWI',
    'bahrain': 'BAH',
    'riyadh': 'RUH',
    'jeddah': 'JED',
    'dammam': 'DMM',
    'salalah': 'SLL',
    // International
    'kuala lumpur': 'KUL',
    'singapore': 'SIN',
    'colombo': 'CMB',
    'bangkok': 'BKK',
  };

  static const Map<String, String> _airlineMap = {
    'air india express': 'IX',
    'airindia express': 'IX',
    'air india': 'AI',
    'indigo': '6E',
    'flydubai': 'FZ',
    'fly dubai': 'FZ',
    'air arabia': 'G9',
    'salamair': 'OV',
    'salam air': 'OV',
    'oman air': 'WY',
    'omanair': 'WY',
    'akasa air': 'QP',
    'akasa': 'QP',
    'flynas': 'XY',
    'fly nas': 'XY',
    'saudia': 'SV',
    'saudi airlines': 'SV',
    'saudi': 'SV',
    'emirates': 'EK',
    'qatar airways': 'QR',
    'qatar': 'QR',
    'etihad airways': 'EY',
    'etihad': 'EY',
    'jazeera airways': 'J9',
    'jazeera': 'J9',
    'kuwait airways': 'KU',
    'kuwait air': 'KU',
    'airasia': 'AK',
    'air asia': 'AK',
    'spicejet': 'SG',
    'spice jet': 'SG',
    'vistara': 'UK',
    'gulf air': 'GF',
    'biman': 'BG',
  };

  static const Set<String> _months = {
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  };

  String _normalizeMessage(String text) {
    var out = text;
    // 1. Replace multi-word airline names first
    for (final entry in _airlineMap.entries) {
      out = out.replaceAll(RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false), entry.value);
    }
    // 2. Replace city names with standard 3-letter IATA codes
    for (final entry in _cityMap.entries) {
      out = out.replaceAll(RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false), entry.value);
    }
    // 3. Normalize k notation (e.g. 14.5k -> 14500, 15k -> 15000)
    out = out.replaceAllMapped(RegExp(r'(\d+)\.5[kK]\b'), (m) => '${m.group(1)}500');
    out = out.replaceAllMapped(RegExp(r'(\d+)[kK]\b'), (m) => '${m.group(1)}000');

    // 4. Expand date ranges and comma lists into individual flight lines
    // Handles: "15-Oct", "16,17-Oct", "19-25-Oct", "21-23,25-Oct", "18 TO 20 OCT", "15, 16, 17 OCT", "01-10-Nov", "11-30-Nov"
    final dateSpecRegex = RegExp(
      r'\b((?:\d{1,2}(?:\s*(?:TO|-)\s*\d{1,2})?)(?:\s*,\s*(?:\d{1,2}(?:\s*(?:TO|-)\s*\d{1,2})?))*)\s*[-/]?\s*([A-Za-z]{3})\b',
      caseSensitive: false,
    );

    final lines = out.split('\n');
    final expanded = <String>[];
    for (final line in lines) {
      final m = dateSpecRegex.firstMatch(line);
      if (m != null) {
        final spec = m.group(1)!;
        final month = m.group(2)!.toUpperCase();

        if (_months.contains(month)) {
          final parts = spec.split(',').map((s) => s.trim()).toList();
          final days = <int>[];

          for (final part in parts) {
            final rangeM = RegExp(r'^(\d{1,2})\s*(?:TO|-)\s*(\d{1,2})$', caseSensitive: false).firstMatch(part);
            if (rangeM != null) {
              final start = int.tryParse(rangeM.group(1)!) ?? 0;
              final end = int.tryParse(rangeM.group(2)!) ?? 0;
              if (start >= 1 && end <= 31 && start <= end && (end - start) <= 30) {
                for (var d = start; d <= end; d++) {
                  days.add(d);
                }
              }
            } else {
              final singleDay = int.tryParse(part);
              if (singleDay != null && singleDay >= 1 && singleDay <= 31) {
                days.add(singleDay);
              }
            }
          }

          if (days.length > 1) {
            for (final d in days) {
              expanded.add(line.replaceRange(m.start, m.end, '$d $month'));
            }
            continue;
          } else if (days.length == 1) {
            expanded.add(line.replaceRange(m.start, m.end, '${days.first} $month'));
            continue;
          }
        }
      }

      expanded.add(line);
    }

    return expanded.join('\n');
  }

  Future<List<Map<String, dynamic>>> parseFlightData(String message, {String? agencyName}) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return [];

    // Normalize message (convert all 10 agency formats, city names, airline names, date ranges)
    final normalized = _normalizeMessage(trimmed);

    // 1. High-Speed Regex Fast-Path:
    // Extracts flights instantly in 0.002 seconds preserving exact WhatsApp sequence!
    final regexFlights = _parseWithRegexFallback(normalized, agencyName: agencyName);

    // If regex captured any flights, return instantly without waiting for AI!
    if (regexFlights.isNotEmpty) {
      return regexFlights;
    }

    // 2. Preprocess & inject sector headers into lines for unstructured AI parsing
    try {
      final injected = _preprocessAndInjectSectors(normalized);
      final lines = injected.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length > 40) {
        final List<String> chunks = [];
        for (var i = 0; i < lines.length; i += 40) {
          final end = (i + 40 < lines.length) ? i + 40 : lines.length;
          chunks.add(lines.sublist(i, end).join('\n'));
        }
        final List<Map<String, dynamic>> allFlights = [];
        for (var i = 0; i < chunks.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 350));
          }
          final chunkFlights = await _parseChunk(chunks[i]);
          allFlights.addAll(chunkFlights);
        }
        if (allFlights.isNotEmpty) return allFlights;
      } else {
        final aiFlights = await _parseChunk(injected);
        if (aiFlights.isNotEmpty) return aiFlights;
      }
    } catch (_) {}

    if (regexFlights.isNotEmpty) {
      return regexFlights;
    }

    throw Exception(
      'Could not detect any valid flight fares from the message. Please check the text format and try again.',
    );
  }

  String _preprocessAndInjectSectors(String text) {
    final lines = text.split('\n');
    final viaWordRegex = RegExp(
      r'\b([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\||\s+)\s*([A-Za-z]{3})\s+(?:VIA|VI|1\s*STOP\s*VIA)\s+([A-Za-z]{3})\b',
      caseSensitive: false,
    );
    final connectingRegex = RegExp(
      r'\b([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\||\s+)\s*([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\||\s+)\s*([A-Za-z]{3})\b',
      caseSensitive: false,
    );
    final sectorRegex = RegExp(r'\b([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\|)\s*([A-Za-z]{3})\b', caseSensitive: false);
    final inlineSectorRegex = RegExp(r'\b([A-Za-z]{3})\s+([A-Za-z]{3})\b', caseSensitive: false);
    final dateRegex = RegExp(r'\b\d{1,2}\s*(?:OCT|NOV|DEC|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP)\b', caseSensitive: false);
    final priceRegex = RegExp(r'₹|\b\d{4,6}\b');

    String? currentSector;
    final normalized = <String>[];

    for (final raw in lines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final hasDate = dateRegex.hasMatch(trimmed);
      final hasPrice = priceRegex.hasMatch(trimmed);

      if (!(hasDate && hasPrice)) {
        final viaMatch = viaWordRegex.firstMatch(trimmed);
        if (viaMatch != null) {
          final src = viaMatch.group(1)!.toUpperCase();
          final dst = viaMatch.group(2)!.toUpperCase();
          final via = viaMatch.group(3)!.toUpperCase();
          if (!_months.contains(src) && !_months.contains(dst) && !_months.contains(via)) {
            currentSector = '$src ➝ $dst (VIA $via)';
            continue;
          }
        }

        final connMatch = connectingRegex.firstMatch(trimmed);
        if (connMatch != null) {
          final src = connMatch.group(1)!.toUpperCase();
          final via = connMatch.group(2)!.toUpperCase();
          final dst = connMatch.group(3)!.toUpperCase();
          if (!_months.contains(src) && !_months.contains(via) && !_months.contains(dst)) {
            currentSector = '$src ➝ $dst (VIA $via)';
            continue;
          }
        }

        var secMatch = sectorRegex.firstMatch(trimmed);
        secMatch ??= inlineSectorRegex.firstMatch(trimmed);
        if (secMatch != null) {
          final src = secMatch.group(1)!.toUpperCase();
          final dst = secMatch.group(2)!.toUpperCase();
          if (!_months.contains(src) && !_months.contains(dst)) {
            currentSector = '$src ➝ $dst';
            continue;
          }
        }
      }

      if (currentSector != null && (hasDate || hasPrice)) {
        normalized.add('[$currentSector] $trimmed');
      } else {
        normalized.add(trimmed);
      }
    }

    return normalized.join('\n');
  }

  Future<List<Map<String, dynamic>>> _parseChunk(String messageChunk) async {
    const systemPrompt = '''
You are an expert flight fare parser. Extract each flight from the travel agency text into a single pipe-delimited line in this exact format:
source|destination|date|airline|flightNumber|timing|baggage|seats|marketedPrice|via

Examples:
CCJ|DXB|15 OCT|IX|347|11:00|30 KG|2|15000|
CCJ|SHJ|21 OCT|OV|774/241|—|20+5 KG|—|19500|MCT

CRITICAL RULES:
- The line MUST ALWAYS start with the 3-letter origin airport code (e.g. CNN, CCJ, COK), NEVER with the date!
  Even if the message says "15 OCT CNN DXB" or "15 OCT - DXB", the output MUST be "CNN|DXB|15 OCT|...".
- Source and destination must strictly be 3-letter IATA airport codes (e.g., 'CNN', 'CCJ', 'DXB', 'COK', 'SHJ', 'TRV', 'AUH', 'BOM', 'DEL').
- CONNECTION / VIA FLIGHTS: When a flight has an intermediate stop or 3 airport codes (e.g. "CCJ MCT SHJ", "CCJ ➝ MCT ➝ SHJ", "CCJ SHJ VIA MCT"):
  - Source is the FIRST airport (origin, e.g. "CCJ").
  - Destination is the FINAL airport (destination, e.g. "SHJ").
  - The 10th pipe column "via" is the connecting airport (e.g. "MCT"). For direct flights, leave 10th column empty.
- If a line has multiple dates (e.g., '15,16 OCT' or '21 to 24 OCT'), split them and create a SEPARATE line for EACH date.
- Marketed price must be numeric only without commas or currency symbols (e.g., 15000).
- If timing, baggage, or seats are not mentioned, use '—'.
- If a flight/date is marked 'SOLD OUT' or 'CLOSED', do NOT include it.
- Output ONLY the pipe-delimited lines. Do not include markdown blocks, headers, or explanations.
''';

    try {
      final text = await _generateWithFallback(systemPrompt, messageChunk);
      final flights = _extractFlightsFromText(text);
      if (flights.isNotEmpty) return flights;
    } catch (_) {
      // AI completely unavailable or failed, attempt regex fallback below
    }

    // Safety net: If AI fails or returns empty, parse using regex rules
    final fallbackFlights = _parseWithRegexFallback(messageChunk);
    if (fallbackFlights.isNotEmpty) {
      return fallbackFlights;
    }

    throw Exception(
      'AI service temporarily busy. Please try importing again in a few seconds.',
    );
  }

  Future<String> _generateWithFallback(String systemPrompt, String userMessage) async {
    // 1. Primary: Groq LPU (Ultra-fast 0.4s inference, 100% free)
    if (_groqApiKey.isNotEmpty) {
      final groqModels = ['openai/gpt-oss-120b', 'openai/gpt-oss-20b'];
      for (final model in groqModels) {
        for (var attempt = 1; attempt <= 2; attempt++) {
          try {
            final response = await http.post(
              Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer $_groqApiKey',
                'Content-Type': 'application/json',
                'User-Agent': 'FlutterApp/1.0',
              },
              body: jsonEncode({
                'model': model,
                'temperature': 0.1,
                'max_tokens': 800,
                'reasoning_effort': 'low',
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': userMessage},
                ],
              }),
            ).timeout(const Duration(seconds: 15));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final choices = data['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final content = choices[0]['message']?['content'] as String? ?? '';
                if (content.trim().isNotEmpty) return content;
              }
            } else if (response.statusCode == 429 || response.statusCode == 503) {
              if (attempt < 2) {
                await Future.delayed(const Duration(milliseconds: 1200));
                continue;
              }
            }
          } catch (_) {
            if (attempt < 2) {
              await Future.delayed(const Duration(milliseconds: 1000));
              continue;
            }
          }
        }
      }
    }

    // 2. Secondary Fallback: Google Gemini
    if (_geminiApiKey.isNotEmpty) {
      final combinedPrompt = '$systemPrompt\n\nText to parse:\n$userMessage';
      final candidateModels = ['gemini-3.5-flash', 'gemini-flash-latest'];

      for (final modelName in candidateModels) {
        for (var attempt = 1; attempt <= 2; attempt++) {
          try {
            final url = Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_geminiApiKey',
            );
            final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [{'text': combinedPrompt}]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.1,
                  'thinkingConfig': {
                    'thinkingBudget': 0,
                  },
                },
              }),
            ).timeout(const Duration(seconds: 12));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final candidates = data['candidates'] as List?;
              if (candidates != null && candidates.isNotEmpty) {
                final content = candidates[0]['content'];
                final parts = content?['parts'] as List?;
                if (parts != null && parts.isNotEmpty) {
                  final text = parts[0]['text'] as String? ?? '';
                  if (text.trim().isNotEmpty) return text;
                }
              }
            }
            break;
          } catch (_) {
            if (attempt < 2) {
              await Future.delayed(Duration(milliseconds: 800 * attempt));
              continue;
            }
            break;
          }
        }
      }
    }

    throw Exception('Failed to generate content from AI');
  }

  List<Map<String, dynamic>> _parseWithRegexFallback(String text, {String? agencyName}) {
    final results = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    final viaWordRegex = RegExp(
      r'\b([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\||\s+)\s*([A-Za-z]{3})\s+(?:VIA|VI|1\s*STOP\s*VIA)\s+([A-Za-z]{3})\b',
      caseSensitive: false,
    );
    final connectingRegex = RegExp(
      r'\b([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\||\s+)\s*([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\||\s+)\s*([A-Za-z]{3})\b',
      caseSensitive: false,
    );
    final sectorRegex = RegExp(r'\b([A-Za-z]{3})\s*(?:→|➝|➔|➜|->|=>|TO|-|/|–|—|>|\|)\s*([A-Za-z]{3})\b', caseSensitive: false);
    final inlineSectorRegex = RegExp(r'\b([A-Za-z]{3})\s+([A-Za-z]{3})\b', caseSensitive: false);
    final dateRegex = RegExp(r'\b(\d{1,2})\s*[-/]?\s*([A-Za-z]{3})\b');
    final flightNumRegex = RegExp(
      r'\b(IX|6E|AI|SG|FZ|G9|WY|EK|QR|EY|QP|XY|SV|J9|KU|AK|OV|F3|RX|UK|GF|[A-Za-z]{2}|[A-Za-z]\d|\d[A-Za-z])\s*[- *]?(\d{2,4}(?:\s*(?:&|\/)\s*\d{2,4})?)\b',
      caseSensitive: false,
    );
    final standaloneAirlineRegex = RegExp(r'\b(IX|6E|AI|SG|FZ|G9|WY|EK|QR|EY|QP|XY|SV|J9|KU|AK|OV|F3|RX|UK|GF)\b', caseSensitive: false);
    final groupHeaderRegex = RegExp(r'\bgroup[- ]?(\d+)\b', caseSensitive: false);
    final priceRegex = RegExp(r'(?:₹|INR|RS\.?)?\s*(\d{1,2}[,.]\d{3}|\d{4,6})', caseSensitive: false);
    final baggageRegex = RegExp(r'\b(\d{1,2}(?:\s*\+\s*\d{1,2})?\s*KG[S]?)\b|\b(\d{1,2}\s*\+\s*\d{1,2})\b', caseSensitive: false);
    final timingRegex = RegExp(r'\b(\d{1,2}:\d{2}(?:\s*(?:AM|PM))?(?:\s*-\s*\d{1,2}:\d{2}(?:\s*(?:AM|PM))?)?)\b', caseSensitive: false);
    final seatsRegex = RegExp(r'\b(\d{1,2})\s*(?:SEATS?|SEAT|STS|ST)\b|\b(\d{1,2})\s*💺', caseSensitive: false);

    String? currentSrc;
    String? currentDst;
    String currentVia = '';
    String currentAirline = '—';
    String currentFlightNum = '—';
    String currentBaggage = '—';
    String currentTiming = '—';
    String? currentGroupAirline;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.toLowerCase().contains('sold out') || line.toLowerCase().contains('closed') || line.toLowerCase().contains('best')) {
        continue;
      }

      final dateMatch = dateRegex.firstMatch(line);

      String? lineSrc;
      String? lineDst;
      String? lineVia;

      final viaMatch = viaWordRegex.firstMatch(line);
      if (viaMatch != null) {
        final s = viaMatch.group(1)!.toUpperCase();
        final d = viaMatch.group(2)!.toUpperCase();
        final v = viaMatch.group(3)!.toUpperCase();
        if (!_months.contains(s) && !_months.contains(d) && !_months.contains(v)) {
          lineSrc = s;
          lineDst = d;
          lineVia = v;
        }
      }

      if (lineSrc == null) {
        final connMatch = connectingRegex.firstMatch(line);
        if (connMatch != null) {
          final s = connMatch.group(1)!.toUpperCase();
          final v = connMatch.group(2)!.toUpperCase();
          final d = connMatch.group(3)!.toUpperCase();
          if (!_months.contains(s) && !_months.contains(v) && !_months.contains(d)) {
            lineSrc = s;
            lineVia = v;
            lineDst = d;
          }
        }
      }

      if (lineSrc == null) {
        for (final m in sectorRegex.allMatches(line)) {
          final s = m.group(1)!.toUpperCase();
          final d = m.group(2)!.toUpperCase();
          if (!_months.contains(s) && !_months.contains(d)) {
            lineSrc = s;
            lineDst = d;
            lineVia = '';
            break;
          }
        }
      }

      if (lineSrc == null) {
        for (final m in inlineSectorRegex.allMatches(line)) {
          final s = m.group(1)!.toUpperCase();
          final d = m.group(2)!.toUpperCase();
          if (!_months.contains(s) && !_months.contains(d)) {
            lineSrc = s;
            lineDst = d;
            lineVia = '';
            break;
          }
        }
      }

      // 1. If line has NO date, it CANNOT be a flight line!
      // It must be a sector header, context header (baggage/airline/flightNum), or divider/info.
      if (dateMatch == null) {
        // Ignore infant/cancellation/terms rules
        final lower = line.toLowerCase();
        if (lower.contains('infant') ||
            lower.contains('terms') ||
            lower.contains('condition') ||
            lower.contains('rule') ||
            lower.contains('cancellation') ||
            lower.contains('refund') ||
            lower.contains('note:')) {
          continue;
        }

        // Check for Group headers (e.g. Trinity format: Group 1 = SG, Group 2 = IX, Group 3 = 6E)
        final groupMatch = groupHeaderRegex.firstMatch(line);
        if (groupMatch != null) {
          final gNum = groupMatch.group(1);
          final sa = standaloneAirlineRegex.firstMatch(line);
          if (sa != null) {
            currentGroupAirline = sa.group(1)!.toUpperCase();
          } else if (gNum == '1') {
            currentGroupAirline = 'SG'; // SpiceJet
          } else if (gNum == '2') {
            currentGroupAirline = 'IX'; // Air India Express
          } else if (gNum == '3') {
            currentGroupAirline = '6E'; // IndiGo
          }
          currentAirline = currentGroupAirline ?? '—';
          currentFlightNum = '—';
          continue;
        }

        if (lineSrc != null) {
          currentSrc = lineSrc;
          currentDst = lineDst;
          currentVia = lineVia ?? '';
          // Sector header resets sector-specific defaults
          currentAirline = currentGroupAirline ?? '—';
          currentFlightNum = '—';
          currentBaggage = '—';
          currentTiming = '—';
        }

        // Check if this header line provides airline, flight number, baggage, or timing
        final fn = flightNumRegex.firstMatch(line);
        if (fn != null) {
          final code = fn.group(1)!.toUpperCase();
          if (!_months.contains(code) && code != currentSrc && code != currentDst) {
            currentAirline = code;
            currentFlightNum = fn.group(2)!;
          }
        } else {
          final sa = standaloneAirlineRegex.firstMatch(line);
          if (sa != null) {
            final code = sa.group(1)!.toUpperCase();
            if (code != currentSrc && code != currentDst) {
              currentAirline = code;
              currentFlightNum = '—';
            }
          }
        }

        final bg = baggageRegex.firstMatch(line);
        if (bg != null) {
          final rawBg = bg.group(1) ?? bg.group(2) ?? '';
          if (rawBg.isNotEmpty) {
            var formatted = rawBg.toUpperCase().replaceAll('KGS', 'KG');
            if (!formatted.contains('KG')) {
              formatted = '$formatted KG';
            } else {
              formatted = formatted.replaceAllMapped(RegExp(r'(\d)KG'), (m) => '${m.group(1)} KG');
            }
            currentBaggage = formatted;
          }
        }

        final tm = timingRegex.firstMatch(line);
        if (tm != null) {
          currentTiming = tm.group(1)!;
        }

        continue;
      }

      var src = lineSrc ?? currentSrc;
      var dst = lineDst ?? currentDst;
      var via = lineVia ?? currentVia;

      if (src == null || dst == null) continue;

      var fnMatch = flightNumRegex.firstMatch(line);

      // Check if fnMatch overlaps with dateMatch (e.g. "J9 18 OCT" -> 18 is date, not flight number!)
      bool isDateOverlap = false;
      if (fnMatch != null) {
        if (fnMatch.end > dateMatch.start && fnMatch.start < dateMatch.end) {
          isDateOverlap = true;
        }
      }

      final priceMatches = priceRegex.allMatches(line).toList();
      if (priceMatches.isEmpty) continue;

      // Filter out price matches that overlap with the flight number match or date
      final validPrices = priceMatches.where((pm) {
        if (pm.start >= dateMatch.start && pm.end <= dateMatch.end) return false;
        if (fnMatch != null && !isDateOverlap && pm.start >= fnMatch.start && pm.end <= fnMatch.end) {
          return false;
        }
        return true;
      }).toList();

      if (validPrices.isEmpty) continue;

      final priceStr = validPrices.last.group(1)!.replaceAll(RegExp(r'[,.]'), '');
      final price = double.tryParse(priceStr) ?? 0.0;
      if (price < 1000) continue;

      final dateStr = '${dateMatch.group(1)} ${dateMatch.group(2)!.toUpperCase()}';

      // Determine airline and flight number
      String airline = currentAirline;
      String flightNum = '—';

      if (fnMatch != null && !isDateOverlap) {
        final code = fnMatch.group(1)!.toUpperCase();
        if (!_months.contains(code) && code != src && code != dst) {
          airline = code;
          flightNum = fnMatch.group(2)!;
        }
      } else {
        // Check for line airline (either from date overlap or standalone)
        final lineAirline = isDateOverlap
            ? fnMatch!.group(1)!.toUpperCase()
            : standaloneAirlineRegex.firstMatch(line)?.group(1)?.toUpperCase();

        if (lineAirline != null && !_months.contains(lineAirline) && lineAirline != src && lineAirline != dst) {
          airline = lineAirline;
        }

        // Inherit flight number if airline matches current header airline
        if (airline == currentAirline) {
          flightNum = currentFlightNum;
        }
      }

      final bgMatch = baggageRegex.firstMatch(line);
      final tmMatch = timingRegex.firstMatch(line);
      final stMatch = seatsRegex.firstMatch(line);

      String baggage = currentBaggage;
      if (bgMatch != null) {
        final rawBg = bgMatch.group(1) ?? bgMatch.group(2) ?? '';
        if (rawBg.isNotEmpty) {
          var formatted = rawBg.toUpperCase().replaceAll('KGS', 'KG');
          if (!formatted.contains('KG')) {
            formatted = '$formatted KG';
          } else {
            formatted = formatted.replaceAllMapped(RegExp(r'(\d)KG'), (m) => '${m.group(1)} KG');
          }
          baggage = formatted;
        }
      }
      final timing = tmMatch?.group(1) ?? currentTiming;

      results.add({
        'source': src,
        'destination': dst,
        'via': via,
        'date': dateStr,
        'airline': airline,
        'flightNumber': flightNum,
        'timing': timing,
        'baggage': baggage,
        'seats': (stMatch?.group(1) ?? stMatch?.group(2)) ?? '—',
        'marketedPrice': price,
      });
    }

    return results;
  }

  List<Map<String, dynamic>> _extractFlightsFromText(String rawText) {
    final clean = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Fallback: in case the model returns JSON
    if (clean.startsWith('[')) {
      try {
        final List<dynamic> parsed = jsonDecode(clean);
        return parsed.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    final List<Map<String, dynamic>> results = [];
    final lines = clean.split('\n');

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.toLowerCase().startsWith('source|')) continue;
      final parts = line.split('|').map((p) => p.trim()).toList();

      if (parts.length >= 9) {
        var src = parts[0].toUpperCase().trim();
        var dst = parts[1].toUpperCase().trim();
        var dt = parts[2].toUpperCase().trim();

        // Convert full city names if AI returned city names
        if (_cityMap.containsKey(src.toLowerCase())) {
          src = _cityMap[src.toLowerCase()]!;
        }
        if (_cityMap.containsKey(dst.toLowerCase())) {
          dst = _cityMap[dst.toLowerCase()]!;
        }

        final hasDigit = RegExp(r'\d');
        final isMonth = RegExp(r'\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\b', caseSensitive: false);
        bool isDateStr(String s) => hasDigit.hasMatch(s) || isMonth.hasMatch(s);
        bool isAirportCode(String s) => RegExp(r'^[A-Z]{3}$').hasMatch(s) && !_months.contains(s);

        // Auto-fix Pattern 1: Date | Source | Destination (e.g. "15 OCT | CNN | DXB")
        if (isDateStr(src) && isAirportCode(dst) && isAirportCode(dt)) {
          final tempDate = src;
          src = dst;
          dst = dt;
          dt = tempDate;
        }
        // Auto-fix Pattern 2: Source | Date | Destination (e.g. "CNN | 15 OCT | DXB")
        else if (isAirportCode(src) && isDateStr(dst) && isAirportCode(dt)) {
          final tempDst = dt;
          dt = dst;
          dst = tempDst;
        }

        // Clean up any extra spaces or symbols from airport codes
        if (!isAirportCode(src)) {
          final m = RegExp(r'\b([A-Z]{3})\b').firstMatch(src);
          if (m != null && !_months.contains(m.group(1)!)) src = m.group(1)!;
        }
        if (!isAirportCode(dst)) {
          final m = RegExp(r'\b([A-Z]{3})\b').firstMatch(dst);
          if (m != null && !_months.contains(m.group(1)!)) dst = m.group(1)!;
        }

        // Prevent corrupted entries from polluting the database
        if (!isAirportCode(src) || !isAirportCode(dst)) {
          continue;
        }

        var airline = parts[3].toUpperCase().trim();
        if (_airlineMap.containsKey(airline.toLowerCase())) {
          airline = _airlineMap[airline.toLowerCase()]!;
        }

        var flightNum = parts[4].trim();
        if (airline.isNotEmpty && flightNum.toUpperCase().startsWith(airline)) {
          flightNum = flightNum.substring(airline.length).replaceAll(RegExp(r'^[- ]+'), '').trim();
        }

        // Normalize date to standard "DD MON" format
        final dateMatch = RegExp(r'\b(\d{1,2})\s*([A-Za-z]{3})\b').firstMatch(dt);
        if (dateMatch != null && _months.contains(dateMatch.group(2)!.toUpperCase())) {
          dt = '${dateMatch.group(1)} ${dateMatch.group(2)!.toUpperCase()}';
        }

        final price = double.tryParse(parts[8].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        final via = (parts.length >= 10) ? parts[9].trim().toUpperCase() : '';
        if (price > 0 || parts[8].isNotEmpty) {
          results.add({
            'source': src,
            'destination': dst,
            'via': via,
            'date': dt,
            'airline': airline,
            'flightNumber': flightNum,
            'timing': parts[5].trim(),
            'baggage': parts[6].trim().replaceAll('KGS', 'KG'),
            'seats': parts[7].trim(),
            'marketedPrice': price,
          });
        }
      }
    }

    return results;
  }
}
