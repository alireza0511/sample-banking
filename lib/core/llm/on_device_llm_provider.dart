import 'dart:async';
import 'dart:io';

import 'llm_provider.dart';
import 'llm_service.dart';
import 'local_llm_platform.dart';

/// On-device LLM provider using native platform APIs
/// Wraps platform-specific implementations:
/// - iOS 26+: Apple Foundation Models
/// - Android: Gemini Nano via Google AICore
///
/// Falls back to unavailable on unsupported platforms.
class OnDeviceLlmProvider extends LlmProvider {
  final LocalLlmPlatform _platform;

  LocalLlmAvailability? _availability;
  bool _isOnDeviceAvailable = false;

  OnDeviceLlmProvider({
    LocalLlmPlatform? platform,
    super.maxContextMessages = 10,
    super.timeout = const Duration(seconds: 60),
  }) : _platform = platform ?? LocalLlmPlatform.instance;

  @override
  LlmProviderInfo get providerInfo => LlmProviderInfo(
        name: 'On-Device AI',
        type: LlmProviderType.onDevice,
        isPrivate: true,
        modelName: _availability?.modelName ?? _getDefaultModelName(),
      );

  String _getDefaultModelName() {
    if (Platform.isIOS) {
      return 'Apple Foundation Models';
    } else if (Platform.isAndroid) {
      return 'Gemini Nano';
    }
    return 'Unknown';
  }

  @override
  Future<bool> isAvailable() async {
    if (!isInitialized) {
      try {
        await initialize();
      } catch (_) {
        return false;
      }
    }
    return _isOnDeviceAvailable;
  }

  @override
  Future<void> doInitialize() async {
    // Check platform support
    if (!Platform.isIOS && !Platform.isAndroid) {
      _isOnDeviceAvailable = false;
      _availability = LocalLlmAvailability(
        isAvailable: false,
        reason: 'On-device LLM only supported on iOS and Android',
        platform: _getPlatformName(),
      );
      return;
    }

    // Check native availability
    _availability = await _platform.checkAvailability();
    _isOnDeviceAvailable = _availability?.isAvailable ?? false;
  }

  String _getPlatformName() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  @override
  Future<LlmResponse> doGenerateResponse(LlmRequest request) async {
    if (!_isOnDeviceAvailable) {
      throw LlmError(
        message: _availability?.reason ?? 'On-device LLM not available on this device',
        type: LlmErrorType.unavailable,
      );
    }

    final prompt = buildPromptWithContext(request);

    final result = await _platform.generate(
      prompt: prompt,
      systemPrompt: request.systemPrompt,
      temperature: request.temperature,
      maxTokens: request.maxTokens,
    );

    if (result.isError) {
      throw LlmError(
        message: result.error ?? 'Generation failed',
        type: _mapErrorType(result.error),
      );
    }

    return LlmResponse(
      content: result.content,
      providerInfo: providerInfo,
      tokensUsed: result.tokensUsed,
    );
  }

  @override
  Stream<String> doStreamResponse(LlmRequest request) async* {
    if (!_isOnDeviceAvailable) {
      throw LlmError(
        message: _availability?.reason ?? 'On-device LLM not available on this device',
        type: LlmErrorType.unavailable,
      );
    }

    final prompt = buildPromptWithContext(request);

    try {
      await for (final token in _platform.generateStream(
        prompt: prompt,
        systemPrompt: request.systemPrompt,
        temperature: request.temperature,
        maxTokens: request.maxTokens,
      )) {
        yield token;
      }
    } catch (e) {
      if (e is LlmError) rethrow;
      throw LlmError(
        message: 'Streaming failed: $e',
        type: LlmErrorType.unknown,
        originalError: e,
      );
    }
  }

  @override
  void doDispose() {
    _platform.dispose();
  }

  /// Map error messages to error types
  LlmErrorType _mapErrorType(String? error) {
    if (error == null) return LlmErrorType.unknown;

    final lowerError = error.toLowerCase();

    if (lowerError.contains('timeout')) {
      return LlmErrorType.timeout;
    }
    if (lowerError.contains('unavailable') || lowerError.contains('not available')) {
      return LlmErrorType.unavailable;
    }
    if (lowerError.contains('memory') || lowerError.contains('oom')) {
      return LlmErrorType.outOfMemory;
    }
    if (lowerError.contains('model') && lowerError.contains('load')) {
      return LlmErrorType.modelNotLoaded;
    }
    if (lowerError.contains('invalid')) {
      return LlmErrorType.invalidRequest;
    }

    return LlmErrorType.unknown;
  }

  /// Get detailed availability information
  LocalLlmAvailability? get availabilityInfo => _availability;

  /// Check if streaming is supported
  bool get supportsStreaming =>
      _availability?.capabilities.contains('streaming') ?? true;
}
