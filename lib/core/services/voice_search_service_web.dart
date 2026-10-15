import 'dart:js_interop';
import 'voice_search_service.dart';

@JS('flutterVoiceSearch.isSupported')
external bool _isVoiceSupported();

@JS('flutterVoiceSearch.start')
external void _startVoice(JSFunction onResult, JSFunction onError, JSFunction onEnd);

@JS('flutterVoiceSearch.stop')
external void _stopVoice();

VoiceSearchService getVoiceSearchService() => _WebVoiceSearchService();

class _WebVoiceSearchService implements VoiceSearchService {
  @override
  bool isSupported() {
    try {
      return _isVoiceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  void startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    try {
      final onResultJS = ((JSString text, JSBoolean isFinal) {
        onResult(text.toDart, isFinal.toDart);
      }).toJS;

      final onErrorJS = ((JSString error) {
        onError(error.toDart);
      }).toJS;

      final onEndJS = (() {
        onEnd();
      }).toJS;

      _startVoice(onResultJS, onErrorJS, onEndJS);
    } catch (e) {
      onError(e.toString());
      onEnd();
    }
  }

  @override
  void stopListening() {
    try {
      _stopVoice();
    } catch (_) {}
  }
}
