import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Platform interface for on-device LLM functionality
/// Handles communication with native iOS/Android LLM APIs:
/// - iOS 26+: Apple Foundation Models
/// - Android: Gemini Nano via Google AICore
class LocalLlmPlatform {
  static const MethodChannel _channel = MethodChannel('com.kindbanking/local_llm');
  static const EventChannel _streamChannel = EventChannel('com.kindbanking/local_llm_stream');

  static LocalLlmPlatform? _instance;

  /// Singleton instance
  static LocalLlmPlatform get instance {
    _instance ??= LocalLlmPlatform._();
    return _instance!;
  }

  LocalLlmPlatform._();

  /// Check if on-device LLM is available on this device
  /// Returns availability status with details
  Future<LocalLlmAvailability> checkAvailability() async {
    // Desktop/web not supported
    if (!Platform.isIOS && !Platform.isAndroid) {
      return LocalLlmAvailability(
        isAvailable: false,
        reason: 'On-device LLM only available on iOS and Android',
        platform: _getPlatformName(),
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkAvailability');

      if (result == null) {
        return LocalLlmAvailability(
          isAvailable: false,
          reason: 'No response from platform',
          platform: _getPlatformName(),
        );
      }

      return LocalLlmAvailability(
        isAvailable: result['isAvailable'] as bool? ?? false,
        reason: result['reason'] as String?,
        modelName: result['modelName'] as String?,
        modelVersion: result['modelVersion'] as String?,
        platform: _getPlatformName(),
        capabilities: _parseCapabilities(result['capabilities']),
      );
    } on PlatformException catch (e) {
      return LocalLlmAvailability(
        isAvailable: false,
        reason: 'Platform error: ${e.message}',
        platform: _getPlatformName(),
      );
    } on MissingPluginException {
      // Native implementation not available - expected during development
      return LocalLlmAvailability(
        isAvailable: false,
        reason: 'Native LLM plugin not implemented',
        platform: _getPlatformName(),
      );
    }
  }

  /// Generate a complete response (non-streaming)
  Future<LocalLlmResult> generate({
    required String prompt,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('generate', {
        'prompt': prompt,
        'systemPrompt': systemPrompt,
        'temperature': temperature,
        'maxTokens': maxTokens,
      });

      if (result == null) {
        return LocalLlmResult.error('No response from platform');
      }

      if (result['error'] != null) {
        return LocalLlmResult.error(result['error'] as String);
      }

      return LocalLlmResult(
        content: result['content'] as String? ?? '',
        tokensUsed: result['tokensUsed'] as int?,
        finishReason: result['finishReason'] as String?,
      );
    } on PlatformException catch (e) {
      return LocalLlmResult.error('Platform error: ${e.message}');
    } on MissingPluginException {
      return LocalLlmResult.error('Native LLM plugin not implemented');
    }
  }

  /// Stream response tokens as they're generated
  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) {
    final controller = StreamController<String>();

    // Send request to start streaming
    _channel.invokeMethod<void>('startStream', {
      'prompt': prompt,
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'maxTokens': maxTokens,
    }).then((_) {
      // Listen to stream channel for tokens
      _streamChannel.receiveBroadcastStream().listen(
        (dynamic token) {
          if (token is String) {
            controller.add(token);
          } else if (token is Map && token['done'] == true) {
            controller.close();
          } else if (token is Map && token['error'] != null) {
            controller.addError(Exception(token['error']));
            controller.close();
          }
        },
        onError: (dynamic error) {
          controller.addError(error);
          controller.close();
        },
        onDone: () {
          if (!controller.isClosed) {
            controller.close();
          }
        },
      );
    }).catchError((dynamic error) {
      if (error is MissingPluginException) {
        controller.addError(Exception('Native LLM plugin not implemented'));
      } else {
        controller.addError(error);
      }
      controller.close();
    });

    return controller.stream;
  }

  /// Cancel any ongoing generation
  Future<void> cancelGeneration() async {
    try {
      await _channel.invokeMethod<void>('cancelGeneration');
    } catch (_) {
      // Ignore errors during cancellation
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } catch (_) {
      // Ignore errors during disposal
    }
  }

  String _getPlatformName() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  List<String> _parseCapabilities(dynamic capabilities) {
    if (capabilities == null) return [];
    if (capabilities is List) {
      return capabilities.map((e) => e.toString()).toList();
    }
    return [];
  }
}

/// Availability status for on-device LLM
class LocalLlmAvailability {
  /// Whether on-device LLM is available
  final bool isAvailable;

  /// Human-readable reason if not available
  final String? reason;

  /// Model name (e.g., "Apple Foundation Models", "Gemini Nano")
  final String? modelName;

  /// Model version if available
  final String? modelVersion;

  /// Platform name
  final String platform;

  /// Supported capabilities (e.g., ["text-generation", "summarization"])
  final List<String> capabilities;

  const LocalLlmAvailability({
    required this.isAvailable,
    this.reason,
    this.modelName,
    this.modelVersion,
    required this.platform,
    this.capabilities = const [],
  });

  @override
  String toString() {
    return 'LocalLlmAvailability('
        'isAvailable: $isAvailable, '
        'platform: $platform, '
        'modelName: $modelName, '
        'reason: $reason)';
  }
}

/// Result from on-device LLM generation
class LocalLlmResult {
  /// Generated content
  final String content;

  /// Number of tokens used
  final int? tokensUsed;

  /// Reason generation finished (e.g., "stop", "length")
  final String? finishReason;

  /// Error message if generation failed
  final String? error;

  /// Whether this result is an error
  bool get isError => error != null;

  const LocalLlmResult({
    required this.content,
    this.tokensUsed,
    this.finishReason,
    this.error,
  });

  factory LocalLlmResult.error(String message) {
    return LocalLlmResult(
      content: '',
      error: message,
    );
  }

  @override
  String toString() {
    if (isError) {
      return 'LocalLlmResult.error($error)';
    }
    return 'LocalLlmResult(content: ${content.length} chars, tokens: $tokensUsed)';
  }
}
