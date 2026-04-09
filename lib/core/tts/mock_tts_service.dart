import 'package:flutter/foundation.dart';
import 'tts_service.dart';

/// Mock implementation of TtsService for testing and development
/// Simulates text-to-speech without producing audio output
class MockTtsService implements TtsService {
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = 'en-US';
  String? _currentVoice;

  /// Simulated speech duration per character (in milliseconds)
  final int durationPerCharMs;

  /// List of text being spoken (for testing/verification)
  final List<String> spokenTexts = [];

  MockTtsService({
    this.durationPerCharMs = 50, // 50ms per character
  });

  @override
  String get serviceName => 'MockTts';

  @override
  bool get isServiceAvailable => _isInitialized;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isPaused => _isPaused;

  @override
  double get speechRate => _speechRate;

  @override
  double get volume => _volume;

  @override
  double get pitch => _pitch;

  @override
  String get language => _language;

  @override
  String? get currentVoice => _currentVoice;

  @override
  Future<bool> initialize() async {
    debugPrint('$serviceName: Initializing (mock)...');
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
    debugPrint('$serviceName: Initialized (mock)');
    return true;
  }

  @override
  Future<bool> isAvailable() async {
    return true; // Mock is always available
  }

  @override
  Future<void> speak(
    String text, {
    void Function()? onComplete,
    void Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) {
      debugPrint('$serviceName: Cannot speak empty text');
      return;
    }

    debugPrint('$serviceName: Speaking (mock): "$text"');
    spokenTexts.add(text);
    _isSpeaking = true;

    // Simulate speaking time based on text length and speech rate
    final baseDelay = text.length * durationPerCharMs;
    final adjustedDelay = (baseDelay / _speechRate).round();

    await Future.delayed(Duration(milliseconds: adjustedDelay));

    if (_isSpeaking && !_isPaused) {
      // Only complete if not stopped or paused
      debugPrint('$serviceName: Completed speaking (mock): "$text"');
      _isSpeaking = false;
      _isPaused = false;
      onComplete?.call();
    }
  }

  @override
  Future<void> stop() async {
    debugPrint('$serviceName: Stopping (mock)...');
    _isSpeaking = false;
    _isPaused = false;
    debugPrint('$serviceName: Stopped (mock)');
  }

  @override
  Future<void> pause() async {
    debugPrint('$serviceName: Pausing (mock)...');
    _isPaused = true;
    debugPrint('$serviceName: Paused (mock)');
  }

  @override
  Future<void> resume() async {
    debugPrint('$serviceName: Resuming (mock)...');
    _isPaused = false;
    debugPrint('$serviceName: Resumed (mock)');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    debugPrint('$serviceName: Speech rate set to $_speechRate (mock)');
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    debugPrint('$serviceName: Volume set to $_volume (mock)');
  }

  @override
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.0, 2.0);
    debugPrint('$serviceName: Pitch set to $_pitch (mock)');
  }

  @override
  Future<void> setLanguage(String language) async {
    _language = language;
    debugPrint('$serviceName: Language set to $_language (mock)');
  }

  @override
  Future<List<TtsLanguage>> getAvailableLanguages() async {
    return const [
      TtsLanguage(code: 'en-US', name: 'English (United States)'),
      TtsLanguage(code: 'en-GB', name: 'English (United Kingdom)'),
      TtsLanguage(code: 'es-ES', name: 'Spanish (Spain)'),
      TtsLanguage(code: 'fr-FR', name: 'French (France)'),
      TtsLanguage(code: 'de-DE', name: 'German (Germany)'),
      TtsLanguage(code: 'ja-JP', name: 'Japanese (Japan)'),
      TtsLanguage(code: 'zh-CN', name: 'Chinese (Simplified)'),
    ];
  }

  @override
  Future<List<TtsVoice>> getAvailableVoices() async {
    return const [
      TtsVoice(
        id: 'en-US-voice-1',
        name: 'Alex',
        languageCode: 'en-US',
        gender: 'male',
        isDefault: true,
      ),
      TtsVoice(
        id: 'en-US-voice-2',
        name: 'Samantha',
        languageCode: 'en-US',
        gender: 'female',
      ),
      TtsVoice(
        id: 'es-ES-voice-1',
        name: 'Jorge',
        languageCode: 'es-ES',
        gender: 'male',
        isDefault: true,
      ),
      TtsVoice(
        id: 'fr-FR-voice-1',
        name: 'Thomas',
        languageCode: 'fr-FR',
        gender: 'male',
        isDefault: true,
      ),
    ];
  }

  @override
  Future<void> setVoice(String voiceId) async {
    _currentVoice = voiceId;
    debugPrint('$serviceName: Voice set to $voiceId (mock)');
  }

  @override
  void dispose() {
    debugPrint('$serviceName: Disposing (mock)...');
    _isSpeaking = false;
    _isPaused = false;
    _isInitialized = false;
    spokenTexts.clear();
  }

  /// Get all spoken texts (for testing)
  List<String> getSpokenTexts() => List.unmodifiable(spokenTexts);

  /// Clear spoken texts history
  void clearSpokenTexts() {
    spokenTexts.clear();
  }
}
