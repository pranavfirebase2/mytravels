import 'voice_search_service.dart';

VoiceSearchService getVoiceSearchService() => _StubVoiceSearchService();

class _StubVoiceSearchService implements VoiceSearchService {
  @override
  bool isSupported() => false;

  @override
  void startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    onError("Speech recognition is only supported in web browsers.");
    onEnd();
  }

  @override
  void stopListening() {}
}
