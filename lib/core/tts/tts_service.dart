import 'package:equatable/equatable.dart';

/// Abstract interface for text-to-speech services
/// Allows easy swapping of implementations (flutter_tts, Google Cloud TTS, AWS Polly, etc.)
abstract class TtsService {
  /// Initialize the TTS service
  /// Returns true if initialized successfully
  Future<bool> initialize();

  /// Check if TTS is available on this device
  Future<bool> isAvailable();

  /// Speak the given text
  /// [text] - The text to speak
  /// [onComplete] - Optional callback when speech completes
  /// [onError] - Optional callback when an error occurs
  Future<void> speak(
    String text, {
    void Function()? onComplete,
    void Function(String error)? onError,
  });

  /// Stop speaking and clear the queue
  Future<void> stop();

  /// Pause speaking (can be resumed)
  Future<void> pause();

  /// Resume speaking after pause
  Future<void> resume();

  /// Check if currently speaking
  bool get isSpeaking;

  /// Check if currently paused
  bool get isPaused;

  /// Set speech rate (0.0 to 1.0, where 0.5 is normal)
  /// Some implementations may support values outside this range
  Future<void> setSpeechRate(double rate);

  /// Get current speech rate
  double get speechRate;

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Get current volume
  double get volume;

  /// Set pitch (0.0 to 2.0, where 1.0 is normal)
  Future<void> setPitch(double pitch);

  /// Get current pitch
  double get pitch;

  /// Set language (e.g., 'en-US', 'es-ES', 'fr-FR')
  Future<void> setLanguage(String language);

  /// Get current language
  String get language;

  /// Get available languages
  Future<List<TtsLanguage>> getAvailableLanguages();

  /// Get available voices for current language
  Future<List<TtsVoice>> getAvailableVoices();

  /// Set voice by identifier
  Future<void> setVoice(String voiceId);

  /// Get current voice
  String? get currentVoice;

  /// Get the name of this TTS service implementation
  String get serviceName;

  /// Check if this service is currently available/working
  bool get isServiceAvailable;

  /// Dispose resources
  void dispose();
}

/// Language information for TTS
class TtsLanguage extends Equatable {
  /// Language code (e.g., 'en-US', 'es-ES')
  final String code;

  /// Human-readable name (e.g., 'English (United States)')
  final String name;

  const TtsLanguage({
    required this.code,
    required this.name,
  });

  @override
  List<Object?> get props => [code, name];

  @override
  String toString() => 'TtsLanguage($code: $name)';
}

/// Voice information for TTS
class TtsVoice extends Equatable {
  /// Unique voice identifier
  final String id;

  /// Human-readable name
  final String name;

  /// Language code this voice supports
  final String languageCode;

  /// Gender (if available): 'male', 'female', 'neutral'
  final String? gender;

  /// Whether this is the default voice for the language
  final bool isDefault;

  const TtsVoice({
    required this.id,
    required this.name,
    required this.languageCode,
    this.gender,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, name, languageCode, gender, isDefault];

  @override
  String toString() => 'TtsVoice($id: $name, $languageCode, gender: $gender)';
}

/// Exception thrown by TTS services
class TtsServiceException implements Exception {
  final String message;
  final String? serviceName;
  final dynamic originalError;

  const TtsServiceException(
    this.message, {
    this.serviceName,
    this.originalError,
  });

  @override
  String toString() {
    final service = serviceName != null ? '[$serviceName] ' : '';
    return 'TtsServiceException: $service$message';
  }
}
