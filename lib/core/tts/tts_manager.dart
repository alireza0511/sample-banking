import 'package:flutter/foundation.dart';
import 'flutter_tts_service.dart';
import 'mock_tts_service.dart';
import 'tts_service.dart';

/// Manages text-to-speech services with fallback support
/// Similar to SpeechManager/LlmManager pattern - tries services in order until one works
class TtsManager {
  final List<TtsService> _services;
  TtsService? _activeService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// The currently active TTS service
  TtsService? get activeService => _activeService;

  /// Name of the currently active service
  String get activeServiceName => _activeService?.serviceName ?? 'None';

  /// Whether currently speaking
  bool get isSpeaking => _activeService?.isSpeaking ?? false;

  /// Whether currently paused
  bool get isPaused => _activeService?.isPaused ?? false;

  /// Current speech rate
  double get speechRate => _activeService?.speechRate ?? 0.5;

  /// Current volume
  double get volume => _activeService?.volume ?? 1.0;

  /// Current pitch
  double get pitch => _activeService?.pitch ?? 1.0;

  /// Current language
  String get language => _activeService?.language ?? 'en-US';

  TtsManager({List<TtsService>? services})
      : _services = services ??
            [
              FlutterTtsService(),
              MockTtsService(),
            ];

  /// Initialize the TTS manager
  /// Tries services in order until one initializes successfully
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('TtsManager: Already initialized');
      return;
    }

    debugPrint('TtsManager: Initializing with ${_services.length} services...');

    for (final service in _services) {
      try {
        debugPrint('TtsManager: Trying ${service.serviceName}...');

        final initialized = await service.initialize();

        if (initialized && service.isServiceAvailable) {
          _activeService = service;
          _isInitialized = true;
          debugPrint('TtsManager: Successfully initialized ${service.serviceName}');
          return;
        } else {
          debugPrint('TtsManager: ${service.serviceName} not available');
        }
      } catch (e) {
        debugPrint('TtsManager: ${service.serviceName} failed: $e');
        // Continue to next service
      }
    }

    if (_activeService == null) {
      debugPrint('TtsManager: WARNING - No TTS services available!');
      // Fall back to mock service as last resort
      _activeService = MockTtsService();
      await _activeService!.initialize();
      _isInitialized = true;
    }
  }

  /// Check if TTS is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _activeService?.isServiceAvailable ?? false;
  }

  /// Speak the given text
  /// [text] - The text to speak
  /// [onComplete] - Optional callback when speech completes
  /// [onError] - Optional callback when an error occurs
  Future<void> speak(
    String text, {
    void Function()? onComplete,
    void Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      final error = 'No TTS service available';
      debugPrint('TtsManager: $error');
      onError?.call(error);
      return;
    }

    try {
      await _activeService!.speak(
        text,
        onComplete: onComplete,
        onError: (error) {
          debugPrint('TtsManager: Error from ${_activeService!.serviceName}: $error');
          onError?.call(error);
        },
      );
    } catch (e) {
      debugPrint('TtsManager: Failed to speak: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (_activeService == null) {
      debugPrint('TtsManager: No active service to stop');
      return;
    }

    try {
      await _activeService!.stop();
    } catch (e) {
      debugPrint('TtsManager: Failed to stop: $e');
      rethrow;
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    if (_activeService == null) {
      debugPrint('TtsManager: No active service to pause');
      return;
    }

    try {
      await _activeService!.pause();
    } catch (e) {
      debugPrint('TtsManager: Failed to pause: $e');
      rethrow;
    }
  }

  /// Resume speaking
  Future<void> resume() async {
    if (_activeService == null) {
      debugPrint('TtsManager: No active service to resume');
      return;
    }

    try {
      await _activeService!.resume();
    } catch (e) {
      debugPrint('TtsManager: Failed to resume: $e');
      rethrow;
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      debugPrint('TtsManager: No active service');
      return;
    }

    await _activeService!.setSpeechRate(rate);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      debugPrint('TtsManager: No active service');
      return;
    }

    await _activeService!.setVolume(volume);
  }

  /// Set pitch (0.0 to 2.0)
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      debugPrint('TtsManager: No active service');
      return;
    }

    await _activeService!.setPitch(pitch);
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      debugPrint('TtsManager: No active service');
      return;
    }

    await _activeService!.setLanguage(language);
  }

  /// Get available languages
  Future<List<TtsLanguage>> getAvailableLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      return [];
    }

    return await _activeService!.getAvailableLanguages();
  }

  /// Get available voices
  Future<List<TtsVoice>> getAvailableVoices() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      return [];
    }

    return await _activeService!.getAvailableVoices();
  }

  /// Set voice
  Future<void> setVoice(String voiceId) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      debugPrint('TtsManager: No active service');
      return;
    }

    await _activeService!.setVoice(voiceId);
  }

  /// Switch to a different TTS service by name
  /// Useful for testing or manual service selection
  Future<bool> switchToService(String serviceName) async {
    final service = _services.firstWhere(
      (s) => s.serviceName == serviceName,
      orElse: () => throw ArgumentError('Service $serviceName not found'),
    );

    debugPrint('TtsManager: Switching to $serviceName...');

    try {
      final initialized = await service.initialize();

      if (initialized && service.isServiceAvailable) {
        // Dispose old service if it's different
        if (_activeService != null && _activeService != service) {
          _activeService!.dispose();
        }

        _activeService = service;
        debugPrint('TtsManager: Switched to $serviceName');
        return true;
      } else {
        debugPrint('TtsManager: $serviceName not available');
        return false;
      }
    } catch (e) {
      debugPrint('TtsManager: Failed to switch to $serviceName: $e');
      return false;
    }
  }

  /// Get list of available service names
  List<String> getAvailableServiceNames() {
    return _services.map((s) => s.serviceName).toList();
  }

  /// Dispose all services
  void dispose() {
    debugPrint('TtsManager: Disposing...');
    for (final service in _services) {
      service.dispose();
    }
    _activeService = null;
    _isInitialized = false;
  }
}
