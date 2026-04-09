import 'package:flutter/foundation.dart';
import 'mock_speech_service.dart';
import 'speech_service.dart';
import 'speech_to_text_service.dart';

/// Manages speech recognition services with fallback support
/// Similar to LlmManager pattern - tries services in order until one works
class SpeechManager {
  final List<SpeechService> _services;
  SpeechService? _activeService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// The currently active speech service
  SpeechService? get activeService => _activeService;

  /// Name of the currently active service
  String get activeServiceName => _activeService?.serviceName ?? 'None';

  /// Whether currently listening for speech
  bool get isListening => _activeService?.isListening ?? false;

  SpeechManager({List<SpeechService>? services})
      : _services = services ??
            [
              SpeechToTextService(),
              MockSpeechService(),
            ];

  /// Initialize the speech manager
  /// Tries services in order until one initializes successfully
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SpeechManager: Already initialized');
      return;
    }

    debugPrint('SpeechManager: Initializing with ${_services.length} services...');

    for (final service in _services) {
      try {
        debugPrint('SpeechManager: Trying ${service.serviceName}...');

        final initialized = await service.initialize();

        if (initialized && service.isServiceAvailable) {
          _activeService = service;
          _isInitialized = true;
          debugPrint('SpeechManager: Successfully initialized ${service.serviceName}');
          return;
        } else {
          debugPrint('SpeechManager: ${service.serviceName} not available');
        }
      } catch (e) {
        debugPrint('SpeechManager: ${service.serviceName} failed: $e');
        // Continue to next service
      }
    }

    if (_activeService == null) {
      debugPrint('SpeechManager: WARNING - No speech services available!');
      // Fall back to mock service as last resort
      _activeService = MockSpeechService();
      await _activeService!.initialize();
      _isInitialized = true;
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _activeService?.isServiceAvailable ?? false;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _activeService?.hasPermission() ?? false;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _activeService?.requestPermission() ?? false;
  }

  /// Start listening for speech
  /// [onResult] - Callback fired when speech is recognized
  /// [onError] - Callback fired when an error occurs
  /// [localeId] - Language locale (defaults to device locale)
  /// [partialResults] - Return intermediate results as user speaks
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(String error)? onError,
    String? localeId,
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      final error = 'No speech service available';
      debugPrint('SpeechManager: $error');
      onError?.call(error);
      return;
    }

    try {
      await _activeService!.startListening(
        onResult: onResult,
        onError: (error) {
          debugPrint('SpeechManager: Error from ${_activeService!.serviceName}: $error');
          onError?.call(error);
        },
        localeId: localeId,
        partialResults: partialResults,
      );
    } catch (e) {
      debugPrint('SpeechManager: Failed to start listening: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (_activeService == null) {
      debugPrint('SpeechManager: No active service to stop');
      return;
    }

    try {
      await _activeService!.stopListening();
    } catch (e) {
      debugPrint('SpeechManager: Failed to stop listening: $e');
      rethrow;
    }
  }

  /// Cancel the current speech recognition session
  Future<void> cancel() async {
    if (_activeService == null) {
      debugPrint('SpeechManager: No active service to cancel');
      return;
    }

    try {
      await _activeService!.cancel();
    } catch (e) {
      debugPrint('SpeechManager: Failed to cancel: $e');
      rethrow;
    }
  }

  /// Get available language locales
  Future<List<SpeechLocale>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeService == null) {
      return [];
    }

    return await _activeService!.getAvailableLocales();
  }

  /// Switch to a different speech service by name
  /// Useful for testing or manual service selection
  Future<bool> switchToService(String serviceName) async {
    final service = _services.firstWhere(
      (s) => s.serviceName == serviceName,
      orElse: () => throw ArgumentError('Service $serviceName not found'),
    );

    debugPrint('SpeechManager: Switching to $serviceName...');

    try {
      final initialized = await service.initialize();

      if (initialized && service.isServiceAvailable) {
        // Dispose old service if it's different
        if (_activeService != null && _activeService != service) {
          _activeService!.dispose();
        }

        _activeService = service;
        debugPrint('SpeechManager: Switched to $serviceName');
        return true;
      } else {
        debugPrint('SpeechManager: $serviceName not available');
        return false;
      }
    } catch (e) {
      debugPrint('SpeechManager: Failed to switch to $serviceName: $e');
      return false;
    }
  }

  /// Get list of available service names
  List<String> getAvailableServiceNames() {
    return _services.map((s) => s.serviceName).toList();
  }

  /// Dispose all services
  void dispose() {
    debugPrint('SpeechManager: Disposing...');
    for (final service in _services) {
      service.dispose();
    }
    _activeService = null;
    _isInitialized = false;
  }
}
