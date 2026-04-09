import 'package:flutter/foundation.dart';
import 'speech_service.dart';

/// Mock implementation of SpeechService for testing and development
/// Returns simulated speech recognition results without requiring microphone access
class MockSpeechService implements SpeechService {
  bool _isInitialized = false;
  bool _isListening = false;
  bool _hasPermission = true;

  /// Simulated responses that will be returned when listening starts
  final List<String> simulatedResponses;

  /// Delay between simulated responses
  final Duration responseDelay;

  /// Index of the current simulated response
  int _currentResponseIndex = 0;

  MockSpeechService({
    this.simulatedResponses = const [
      'Show my balance',
      'Transfer money',
      'Pay bills',
      'What is my account balance',
      'Send fifty dollars to John',
    ],
    this.responseDelay = const Duration(seconds: 2),
  });

  @override
  String get serviceName => 'MockSpeech';

  @override
  bool get isServiceAvailable => _isInitialized;

  @override
  bool get isListening => _isListening;

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
  Future<bool> hasPermission() async {
    return _hasPermission;
  }

  @override
  Future<bool> requestPermission() async {
    debugPrint('$serviceName: Requesting permission (mock)...');
    await Future.delayed(const Duration(milliseconds: 500));
    _hasPermission = true;
    debugPrint('$serviceName: Permission granted (mock)');
    return true;
  }

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(String error)? onError,
    String? localeId,
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('$serviceName: Starting to listen (mock)...');
    _isListening = true;

    // Simulate speech recognition with delayed responses
    _simulateSpeechRecognition(
      onResult: onResult,
      partialResults: partialResults,
    );
  }

  void _simulateSpeechRecognition({
    required void Function(SpeechRecognitionResult result) onResult,
    bool partialResults = true,
  }) {
    if (simulatedResponses.isEmpty) {
      debugPrint('$serviceName: No simulated responses configured');
      return;
    }

    // Get next simulated response (cycle through list)
    final responseText =
        simulatedResponses[_currentResponseIndex % simulatedResponses.length];
    _currentResponseIndex++;

    debugPrint('$serviceName: Will simulate: "$responseText"');

    // Simulate partial results (typing effect)
    if (partialResults) {
      final words = responseText.split(' ');
      var currentText = '';

      for (var i = 0; i < words.length; i++) {
        Future.delayed(responseDelay * (i + 1) ~/ words.length, () {
          if (!_isListening) return; // Stopped listening

          currentText += (i > 0 ? ' ' : '') + words[i];
          final isLastWord = i == words.length - 1;

          onResult(SpeechRecognitionResult(
            recognizedWords: currentText,
            confidence: isLastWord ? 0.95 : 0.75,
            isFinal: isLastWord,
            timestamp: DateTime.now(),
          ));

          debugPrint('$serviceName: Simulated partial result: "$currentText"');
        });
      }
    } else {
      // Just return final result
      Future.delayed(responseDelay, () {
        if (!_isListening) return;

        onResult(SpeechRecognitionResult(
          recognizedWords: responseText,
          confidence: 0.95,
          isFinal: true,
          timestamp: DateTime.now(),
        ));

        debugPrint('$serviceName: Simulated final result: "$responseText"');
      });
    }
  }

  @override
  Future<void> stopListening() async {
    debugPrint('$serviceName: Stopping listening (mock)...');
    _isListening = false;
    debugPrint('$serviceName: Stopped listening (mock)');
  }

  @override
  Future<void> cancel() async {
    debugPrint('$serviceName: Cancelling (mock)...');
    _isListening = false;
    debugPrint('$serviceName: Cancelled (mock)');
  }

  @override
  Future<List<SpeechLocale>> getAvailableLocales() async {
    return const [
      SpeechLocale(localeId: 'en_US', name: 'English (United States)'),
      SpeechLocale(localeId: 'es_ES', name: 'Spanish (Spain)'),
      SpeechLocale(localeId: 'fr_FR', name: 'French (France)'),
      SpeechLocale(localeId: 'de_DE', name: 'German (Germany)'),
      SpeechLocale(localeId: 'ja_JP', name: 'Japanese (Japan)'),
    ];
  }

  @override
  void dispose() {
    debugPrint('$serviceName: Disposing (mock)...');
    _isListening = false;
    _isInitialized = false;
  }

  /// Set whether permission is granted (for testing permission flows)
  void setPermissionGranted(bool granted) {
    _hasPermission = granted;
  }

  /// Add a custom response to the simulated responses
  void addSimulatedResponse(String response) {
    simulatedResponses as List;
  }
}
