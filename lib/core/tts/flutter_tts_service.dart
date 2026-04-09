import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_service.dart';

/// Implementation of TtsService using the flutter_tts package
/// This is a wrapper that can be easily swapped with other implementations
class FlutterTtsService implements TtsService {
  final FlutterTts _flutterTts;

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = 'en-US';
  String? _currentVoice;

  FlutterTtsService({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  @override
  String get serviceName => 'FlutterTts';

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
    if (_isInitialized) {
      debugPrint('$serviceName: Already initialized');
      return true;
    }

    try {
      debugPrint('$serviceName: Initializing...');

      // Set up completion handlers
      _flutterTts.setCompletionHandler(() {
        debugPrint('$serviceName: Speech completed');
        _isSpeaking = false;
        _isPaused = false;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('$serviceName: Error - $msg');
        _isSpeaking = false;
        _isPaused = false;
      });

      _flutterTts.setStartHandler(() {
        debugPrint('$serviceName: Speech started');
        _isSpeaking = true;
        _isPaused = false;
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('$serviceName: Speech cancelled');
        _isSpeaking = false;
        _isPaused = false;
      });

      _flutterTts.setPauseHandler(() {
        debugPrint('$serviceName: Speech paused');
        _isPaused = true;
      });

      _flutterTts.setContinueHandler(() {
        debugPrint('$serviceName: Speech resumed');
        _isPaused = false;
      });

      // Set default values
      await setSpeechRate(_speechRate);
      await setVolume(_volume);
      await setPitch(_pitch);
      await setLanguage(_language);

      _isInitialized = true;
      debugPrint('$serviceName: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('$serviceName: Initialization failed: $e');
      throw TtsServiceException(
        'Failed to initialize TTS service',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if TTS is available by trying to get languages
      final languages = await _flutterTts.getLanguages;
      return languages != null && languages.isNotEmpty;
    } catch (e) {
      debugPrint('$serviceName: Availability check failed: $e');
      return false;
    }
  }

  @override
  Future<void> speak(
    String text, {
    void Function()? onComplete,
    void Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw TtsServiceException(
          'Cannot speak: service not initialized',
          serviceName: serviceName,
        );
      }
    }

    if (text.isEmpty) {
      debugPrint('$serviceName: Cannot speak empty text');
      return;
    }

    try {
      debugPrint('$serviceName: Speaking: "$text"');

      // Set up one-time completion handler if provided
      if (onComplete != null) {
        _flutterTts.setCompletionHandler(() {
          _isSpeaking = false;
          _isPaused = false;
          onComplete();
        });
      }

      // Set up one-time error handler if provided
      if (onError != null) {
        _flutterTts.setErrorHandler((msg) {
          _isSpeaking = false;
          _isPaused = false;
          onError(msg);
        });
      }

      _isSpeaking = true;
      final result = await _flutterTts.speak(text);

      if (result == 0) {
        debugPrint('$serviceName: Speech request failed');
        _isSpeaking = false;
        onError?.call('Speech request failed');
      }
    } catch (e) {
      debugPrint('$serviceName: Failed to speak: $e');
      _isSpeaking = false;
      onError?.call(e.toString());
      throw TtsServiceException(
        'Failed to speak text',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      debugPrint('$serviceName: Stopping...');
      await _flutterTts.stop();
      _isSpeaking = false;
      _isPaused = false;
      debugPrint('$serviceName: Stopped');
    } catch (e) {
      debugPrint('$serviceName: Failed to stop: $e');
      throw TtsServiceException(
        'Failed to stop speaking',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> pause() async {
    try {
      debugPrint('$serviceName: Pausing...');
      await _flutterTts.pause();
      _isPaused = true;
      debugPrint('$serviceName: Paused');
    } catch (e) {
      debugPrint('$serviceName: Failed to pause: $e');
      throw TtsServiceException(
        'Failed to pause speaking',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> resume() async {
    try {
      debugPrint('$serviceName: Resuming...');
      // flutter_tts doesn't have a resume method, need to re-speak
      // This is a limitation of the package
      debugPrint('$serviceName: Warning - Resume not fully supported by flutter_tts');
      _isPaused = false;
    } catch (e) {
      debugPrint('$serviceName: Failed to resume: $e');
      throw TtsServiceException(
        'Failed to resume speaking',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      // flutter_tts accepts 0.0 to 1.0, but some platforms support wider range
      final clampedRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(clampedRate);
      _speechRate = clampedRate;
      debugPrint('$serviceName: Speech rate set to $_speechRate');
    } catch (e) {
      debugPrint('$serviceName: Failed to set speech rate: $e');
      throw TtsServiceException(
        'Failed to set speech rate',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(clampedVolume);
      _volume = clampedVolume;
      debugPrint('$serviceName: Volume set to $_volume');
    } catch (e) {
      debugPrint('$serviceName: Failed to set volume: $e');
      throw TtsServiceException(
        'Failed to set volume',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> setPitch(double pitch) async {
    try {
      final clampedPitch = pitch.clamp(0.0, 2.0);
      await _flutterTts.setPitch(clampedPitch);
      _pitch = clampedPitch;
      debugPrint('$serviceName: Pitch set to $_pitch');
    } catch (e) {
      debugPrint('$serviceName: Failed to set pitch: $e');
      throw TtsServiceException(
        'Failed to set pitch',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      _language = language;
      debugPrint('$serviceName: Language set to $_language');
    } catch (e) {
      debugPrint('$serviceName: Failed to set language: $e');
      throw TtsServiceException(
        'Failed to set language',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<List<TtsLanguage>> getAvailableLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final languages = await _flutterTts.getLanguages;

      if (languages == null || languages.isEmpty) {
        return [];
      }

      return languages
          .map((lang) => TtsLanguage(
                code: lang.toString(),
                name: _getLanguageName(lang.toString()),
              ))
          .toList();
    } catch (e) {
      debugPrint('$serviceName: Failed to get languages: $e');
      return [];
    }
  }

  @override
  Future<List<TtsVoice>> getAvailableVoices() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final voices = await _flutterTts.getVoices;

      if (voices == null || voices.isEmpty) {
        return [];
      }

      return voices.map((voice) {
        final voiceMap = voice as Map<dynamic, dynamic>;
        return TtsVoice(
          id: voiceMap['name']?.toString() ?? '',
          name: voiceMap['name']?.toString() ?? '',
          languageCode: voiceMap['locale']?.toString() ?? _language,
        );
      }).toList();
    } catch (e) {
      debugPrint('$serviceName: Failed to get voices: $e');
      return [];
    }
  }

  @override
  Future<void> setVoice(String voiceId) async {
    try {
      await _flutterTts.setVoice({'name': voiceId, 'locale': _language});
      _currentVoice = voiceId;
      debugPrint('$serviceName: Voice set to $voiceId');
    } catch (e) {
      debugPrint('$serviceName: Failed to set voice: $e');
      throw TtsServiceException(
        'Failed to set voice',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  /// Helper to get human-readable language name
  String _getLanguageName(String code) {
    final names = {
      'en-US': 'English (United States)',
      'en-GB': 'English (United Kingdom)',
      'en-AU': 'English (Australia)',
      'es-ES': 'Spanish (Spain)',
      'es-MX': 'Spanish (Mexico)',
      'fr-FR': 'French (France)',
      'de-DE': 'German (Germany)',
      'it-IT': 'Italian (Italy)',
      'ja-JP': 'Japanese (Japan)',
      'ko-KR': 'Korean (Korea)',
      'zh-CN': 'Chinese (Simplified)',
      'pt-BR': 'Portuguese (Brazil)',
      'ru-RU': 'Russian (Russia)',
      'ar-SA': 'Arabic (Saudi Arabia)',
      'hi-IN': 'Hindi (India)',
    };

    return names[code] ?? code;
  }

  @override
  void dispose() {
    debugPrint('$serviceName: Disposing...');
    if (_isSpeaking) {
      _flutterTts.stop();
    }
    _isInitialized = false;
    _isSpeaking = false;
    _isPaused = false;
  }
}
