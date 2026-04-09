import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'flutter_local_ai_client.dart';
import 'llm_provider.dart';
import 'llm_service.dart';
import 'local_ai_client.dart';

/// On-device LLM provider using LocalAiClient abstraction
///
/// Wraps platform-specific implementations:
/// - iOS 26+: Apple Foundation Models
/// - Android: Gemini Nano via Google AICore
/// - macOS: Apple Foundation Models
/// - Windows: Windows AI APIs
///
/// The underlying package can be swapped by providing a different
/// LocalAiClient implementation (default: FlutterLocalAiClient).
///
/// Falls back to unavailable on unsupported platforms.
class OnDeviceLlmProvider extends LlmProvider {
  final LocalAiClient _client;
  final Random _random = Random();

  bool _isOnDeviceAvailable = false;
  bool _isModelInitialized = false;

  /// Simulated streaming delay per word (ms)
  final int streamingDelayMs;

  /// Create an OnDeviceLlmProvider with optional custom client
  ///
  /// [client] - Custom LocalAiClient implementation (default: FlutterLocalAiClient)
  /// [streamingDelayMs] - Delay between words when simulating streaming (default: 30ms)
  OnDeviceLlmProvider({
    LocalAiClient? client,
    super.maxContextMessages = 10,
    super.timeout = const Duration(seconds: 60),
    this.streamingDelayMs = 30,
  }) : _client = client ?? FlutterLocalAiClient();

  @override
  LlmProviderInfo get providerInfo => LlmProviderInfo(
        name: 'On-Device AI',
        type: LlmProviderType.onDevice,
        isPrivate: true,
        modelName: _getModelName(),
      );

  String _getModelName() {
    if (Platform.isIOS || Platform.isMacOS) {
      return 'Apple Foundation Models';
    } else if (Platform.isAndroid) {
      return 'Gemini Nano';
    } else if (Platform.isWindows) {
      return 'Windows AI';
    }
    return 'Local AI';
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
    if (!_isSupportedPlatform()) {
      _isOnDeviceAvailable = false;
      return;
    }

    // Check if local AI is available on this device
    try {
      _isOnDeviceAvailable = await _client.isAvailable();
    } catch (e) {
      _isOnDeviceAvailable = false;
    }
  }

  bool _isSupportedPlatform() {
    return Platform.isIOS ||
        Platform.isAndroid ||
        Platform.isMacOS ||
        Platform.isWindows;
  }

  /// Initialize the model with system instructions
  /// Called lazily on first generation request
  Future<void> _ensureModelInitialized() async {
    if (_isModelInitialized) return;

    try {
      final success = await _client.initialize(
        instructions: _systemInstructions,
      );
      _isModelInitialized = success;

      if (!success) {
        throw const LlmError(
          message: 'Failed to initialize on-device model',
          type: LlmErrorType.modelNotLoaded,
        );
      }
    } catch (e) {
      if (e is LlmError) rethrow;
      throw LlmError(
        message: 'Failed to initialize on-device model: $e',
        type: LlmErrorType.modelNotLoaded,
        originalError: e,
      );
    }
  }

  /// System instructions for the banking assistant
  static const String _systemInstructions = '''
You are a helpful banking assistant for Kind Banking app. You help users with:
- Checking account balances
- Making transfers
- Viewing transaction history
- Managing cards (freeze/unfreeze)
- Paying bills

Be concise, friendly, and always prioritize the user's financial security.
Never share sensitive information in your responses.
If asked to perform an action, guide the user to the appropriate screen.
''';

  @override
  Future<LlmResponse> doGenerateResponse(LlmRequest request) async {
    if (!_isOnDeviceAvailable) {
      throw const LlmError(
        message: 'On-device LLM not available on this device',
        type: LlmErrorType.unavailable,
      );
    }

    await _ensureModelInitialized();

    final prompt = buildPromptWithContext(request);

    try {
      final response = await _client.generateText(
        prompt: prompt,
        maxTokens: request.maxTokens,
        temperature: request.temperature,
      );

      return LlmResponse(
        content: response.text,
        providerInfo: providerInfo,
        tokensUsed: response.tokenCount,
        latency: response.generationTimeMs != null
            ? Duration(milliseconds: response.generationTimeMs!)
            : null,
      );
    } catch (e) {
      throw LlmError(
        message: 'On-device generation failed: $e',
        type: _mapErrorType(e.toString()),
        originalError: e,
      );
    }
  }

  @override
  Stream<String> doStreamResponse(LlmRequest request) async* {
    if (!_isOnDeviceAvailable) {
      throw const LlmError(
        message: 'On-device LLM not available on this device',
        type: LlmErrorType.unavailable,
      );
    }

    await _ensureModelInitialized();

    final prompt = buildPromptWithContext(request);

    try {
      // LocalAiClient doesn't support streaming natively,
      // so we generate the full response and simulate streaming
      final response = await _client.generateText(
        prompt: prompt,
        maxTokens: request.maxTokens,
        temperature: request.temperature,
      );

      // Simulate streaming by yielding words with delays
      final words = response.text.split(' ');
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final suffix = i < words.length - 1 ? ' ' : '';
        yield word + suffix;

        // Add slight random variation to delay for natural feel
        await Future.delayed(
          Duration(milliseconds: streamingDelayMs + _random.nextInt(20)),
        );
      }
    } catch (e) {
      throw LlmError(
        message: 'On-device streaming failed: $e',
        type: _mapErrorType(e.toString()),
        originalError: e,
      );
    }
  }

  @override
  void doDispose() {
    _isModelInitialized = false;
    _client.dispose();
  }

  /// Map error messages to error types
  LlmErrorType _mapErrorType(String error) {
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
    if (lowerError.contains('model') || lowerError.contains('initialize')) {
      return LlmErrorType.modelNotLoaded;
    }
    if (lowerError.contains('invalid')) {
      return LlmErrorType.invalidRequest;
    }
    if (lowerError.contains('-101') || lowerError.contains('aicore')) {
      // Android AICore not installed error
      return LlmErrorType.unavailable;
    }

    return LlmErrorType.unknown;
  }

  /// Open platform-specific AI setup
  /// e.g., Google AICore in the Play Store on Android
  Future<bool> openPlatformSetup() async {
    return _client.openPlatformSetup();
  }
}
