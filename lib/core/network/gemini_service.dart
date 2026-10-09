import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in the .env file');
    }
    // Using gemini-3.5-flash as it is usually more stable and less crowded
    _model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: apiKey);
  }

  Future<List<Map<String, dynamic>>> parseFlightData(String message) async {
    final prompt = '''
You are an expert AI that extracts flight fare data from unstructured travel agency WhatsApp messages.
Extract the flights into a clean JSON array of objects.

CRITICAL INSTRUCTIONS:
- If a line has multiple dates (e.g., '15,16 OCT' or '21 to 24 OCT'), split them and create a SEPARATE object for EACH date.
- The JSON keys must strictly match the list below.

Every object in the array must strictly have these fields:
- source (3-letter code, e.g. 'CCJ' or 'TRZ')
- destination (3-letter code, e.g. 'DXB' or 'SHJ')
- date (The specific date, e.g. '15 OCT'. Do not put multiple dates here)
- airline (e.g. 'IX' or '6E')
- flightNumber (The flight number, e.g. '774' or '669')
- timing (e.g. '11:00' or '—')
- baggage (e.g. '30 KG')
- seats (number of seats, e.g. '2' or '—')
- marketedPrice (The price as a pure number, e.g. 15000. Do not include commas or currency symbols)

Return ONLY the raw JSON array. Do not include markdown tags like ```json.

Message to parse:
$message
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '[]';
      
      // Clean up markdown block if the model accidentally adds it
      final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final List<dynamic> parsed = jsonDecode(cleanText);
      return parsed.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }
}
