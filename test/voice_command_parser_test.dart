import 'package:flutter_test/flutter_test.dart';
import 'package:mytravels/core/services/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser Tests', () {
    final now = DateTime(2026, 10, 15);

    test('extracts exact sector and date: "calicut dubai october 21"', () {
      final res = VoiceCommandParser.parse('calicut dubai october 21', now: now);
      expect(res.src, 'CCJ');
      expect(res.dst, 'DXB');
      expect(res.hasSector, isTrue);
      expect(res.date, DateTime(2026, 10, 21));
    });

    test('extracts sector with typos: "calict dubai october 21"', () {
      final res = VoiceCommandParser.parse('calict dubai october 21', now: now);
      expect(res.src, 'CCJ');
      expect(res.dst, 'DXB');
      expect(res.date, DateTime(2026, 10, 21));
    });

    test('extracts sector with kalicut phonetic variant: "kalicut dubai october 21"', () {
      final res = VoiceCommandParser.parse('kalicut dubai october 21', now: now);
      expect(res.src, 'CCJ');
      expect(res.dst, 'DXB');
      expect(res.date, DateTime(2026, 10, 21));
    });

    test('extracts sector with kalict typo: "kalict dxb 21 october"', () {
      final res = VoiceCommandParser.parse('kalict dxb 21 october', now: now);
      expect(res.src, 'CCJ');
      expect(res.dst, 'DXB');
      expect(res.date, DateTime(2026, 10, 21));
    });

    test('extracts relative date tomorrow: "kozhikode to sharjah tomorrow"', () {
      final res = VoiceCommandParser.parse('kozhikode to sharjah tomorrow', now: now);
      expect(res.src, 'CCJ');
      expect(res.dst, 'SHJ');
      expect(res.date, DateTime(2026, 10, 16));
    });

    test('extracts abbreviations and dates: "cochin jeddah 25 oct"', () {
      final res = VoiceCommandParser.parse('cochin jeddah 25 oct', now: now);
      expect(res.src, 'COK');
      expect(res.dst, 'JED');
      expect(res.date, DateTime(2026, 10, 25));
    });

    test('extracts sector only without date: "kannur abu dhabi"', () {
      final res = VoiceCommandParser.parse('kannur abu dhabi', now: now);
      expect(res.src, 'CNN');
      expect(res.dst, 'AUH');
      expect(res.date, isNull);
    });

    test('extracts ordinal dates: "mangalore dubai 18th"', () {
      final res = VoiceCommandParser.parse('mangalore dubai 18th', now: now);
      expect(res.src, 'IXE');
      expect(res.dst, 'DXB');
      expect(res.date, DateTime(2026, 10, 18));
    });

    test('extracts date only when on sector details page: "october 21"', () {
      final res = VoiceCommandParser.parse('october 21', now: now);
      expect(res.src, isNull);
      expect(res.dst, isNull);
      expect(res.date, DateTime(2026, 10, 21));
    });
  });
}
