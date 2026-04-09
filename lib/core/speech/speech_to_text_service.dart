import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'speech_service.dart';

/// Implementation of SpeechService using the speech_to_text package
/// This is a wrapper that can be easily swapped with other implementations
class SpeechToTextService implements SpeechService {
  final stt.SpeechToText _speechToText;

  bool _isInitialized = false;
  bool _isListening = false;

  SpeechToTextService({stt.SpeechToText? speechToText})
      : _speechToText = speechToText ?? stt.SpeechToText();

  @override
  String get serviceName => 'SpeechToText';

  @override
  bool get isServiceAvailable => _isInitialized;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('$serviceName: Already initialized');
      return true;
    }

    try {
      debugPrint('$serviceName: Initializing...');
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('$serviceName: Initialization error: $error');
        },
        onStatus: (status) {
          debugPrint('$serviceName: Status changed to: $status');
          _isListening = status == 'listening';
        },
      );

      if (_isInitialized) {
        debugPrint('$serviceName: Initialized successfully');
      } else {
        debugPrint('$serviceName: Initialization failed');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('$serviceName: Initialization exception: $e');
      throw SpeechServiceException(
        'Failed to initialize speech service',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _speechToText.initialize();
    } catch (e) {
      debugPrint('$serviceName: Availability check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      return await _speechToText.hasPermission;
    } catch (e) {
      debugPrint('$serviceName: Permission check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      // speech_to_text requests permissions during initialize()
      return await initialize();
    } catch (e) {
      debugPrint('$serviceName: Permission request failed: $e');
      return false;
    }
  }

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(String error)? onError,
    String? localeId,
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw SpeechServiceException(
          'Cannot start listening: service not initialized',
          serviceName: serviceName,
        );
      }
    }

    try {
      debugPrint('$serviceName: Starting to listen...');

      await _speechToText.listen(
        onResult: (stt.SpeechRecognitionResult result) {
          final convertedResult = SpeechRecognitionResult(
            recognizedWords: result.recognizedWords,
            confidence: result.confidence,
            isFinal: result.finalResult,
            timestamp: DateTime.now(),
          );

          debugPrint('$serviceName: Result - ${convertedResult.recognizedWords} '
              '(confidence: ${convertedResult.confidence}, '
              'final: ${convertedResult.isFinal})');

          onResult(convertedResult);
        },
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: partialResults,
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
        ),
        onSoundLevelChange: (level) {
          // Optional: could expose this via callback if needed
          debugPrint('$serviceName: Sound level: $level');
        },
      );

      _isListening = true;
      debugPrint('$serviceName: Now listening');
    } catch (e) {
      debugPrint('$serviceName: Failed to start listening: $e');
      onError?.call(e.toString());
      throw SpeechServiceException(
        'Failed to start listening',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      debugPrint('$serviceName: Stopping listening...');
      await _speechToText.stop();
      _isListening = false;
      debugPrint('$serviceName: Stopped listening');
    } catch (e) {
      debugPrint('$serviceName: Failed to stop listening: $e');
      throw SpeechServiceException(
        'Failed to stop listening',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<void> cancel() async {
    try {
      debugPrint('$serviceName: Cancelling...');
      await _speechToText.cancel();
      _isListening = false;
      debugPrint('$serviceName: Cancelled');
    } catch (e) {
      debugPrint('$serviceName: Failed to cancel: $e');
      throw SpeechServiceException(
        'Failed to cancel',
        serviceName: serviceName,
        originalError: e,
      );
    }
  }

  @override
  Future<List<SpeechLocale>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final locales = await _speechToText.locales();
      return locales
          .map((locale) => SpeechLocale(
                localeId: locale.localeId,
                name: locale.name,
              ))
          .toList();
    } catch (e) {
      debugPrint('$serviceName: Failed to get locales: $e');
      return [];
    }
  }

  @override
  void dispose() {
    debugPrint('$serviceName: Disposing...');
    if (_isListening) {
      _speechToText.stop();
    }
    _isInitialized = false;
    _isListening = false;
  }
}
