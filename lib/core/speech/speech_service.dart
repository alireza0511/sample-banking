import 'package:equatable/equatable.dart';

/// Abstract interface for speech recognition services
/// Allows easy swapping of implementations (speech_to_text, Google Cloud, AWS, etc.)
abstract class SpeechService {
  /// Initialize the speech service and request permissions
  /// Returns true if initialized successfully
  Future<bool> initialize();

  /// Check if speech recognition is available on this device
  Future<bool> isAvailable();

  /// Check if the service has microphone permissions
  Future<bool> hasPermission();

  /// Request microphone permissions from the user
  Future<bool> requestPermission();

  /// Start listening for speech
  /// [onResult] - Callback fired when speech is recognized (partial or final)
  /// [onError] - Callback fired when an error occurs
  /// [localeId] - Language locale (e.g., 'en_US', 'es_ES')
  /// [partialResults] - Whether to return partial results as user speaks
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(String error)? onError,
    String? localeId,
    bool partialResults = true,
  });

  /// Stop listening for speech
  Future<void> stopListening();

  /// Cancel the current speech recognition session
  Future<void> cancel();

  /// Check if currently listening
  bool get isListening;

  /// Get available locales for speech recognition
  Future<List<SpeechLocale>> getAvailableLocales();

  /// Get the name of this speech service implementation
  String get serviceName;

  /// Check if this service is currently available/working
  bool get isServiceAvailable;

  /// Dispose resources
  void dispose();
}

/// Result from speech recognition
class SpeechRecognitionResult extends Equatable {
  /// The recognized text
  final String recognizedWords;

  /// Confidence level (0.0 to 1.0)
  final double confidence;

  /// Whether this is a final result or partial
  final bool isFinal;

  /// Timestamp when recognition completed
  final DateTime timestamp;

  const SpeechRecognitionResult({
    required this.recognizedWords,
    required this.confidence,
    required this.isFinal,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [recognizedWords, confidence, isFinal, timestamp];

  @override
  String toString() =>
      'SpeechRecognitionResult(words: "$recognizedWords", confidence: $confidence, isFinal: $isFinal)';
}

/// Locale information for speech recognition
class SpeechLocale extends Equatable {
  /// Locale identifier (e.g., 'en_US', 'es_ES')
  final String localeId;

  /// Human-readable name (e.g., 'English (United States)')
  final String name;

  const SpeechLocale({
    required this.localeId,
    required this.name,
  });

  @override
  List<Object?> get props => [localeId, name];

  @override
  String toString() => 'SpeechLocale($localeId: $name)';
}

/// Exception thrown by speech services
class SpeechServiceException implements Exception {
  final String message;
  final String? serviceName;
  final dynamic originalError;

  const SpeechServiceException(
    this.message, {
    this.serviceName,
    this.originalError,
  });

  @override
  String toString() {
    final service = serviceName != null ? '[$serviceName] ' : '';
    return 'SpeechServiceException: $service$message';
  }
}
