import 'voice_search_service_stub.dart'
    if (dart.library.js_interop) 'voice_search_service_web.dart';

abstract class VoiceSearchService {
  static VoiceSearchService get instance => getVoiceSearchService();

  bool isSupported();

  void startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  });

  void stopListening();
}
