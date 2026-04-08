import 'dart:async';

import 'llm_service.dart';

/// Base class for LLM providers with common functionality
/// Handles context management, error handling, and lifecycle
abstract class LlmProvider implements LlmService {
  bool _isInitialized = false;
  bool _isDisposed = false;

  /// Maximum number of messages to keep in context
  final int maxContextMessages;

  /// Timeout for LLM operations
  final Duration timeout;

  LlmProvider({
    this.maxContextMessages = 10,
    this.timeout = const Duration(seconds: 30),
  });

  /// Check if provider is initialized
  bool get isInitialized => _isInitialized;

  /// Check if provider is disposed
  bool get isDisposed => _isDisposed;

  @override
  Future<void> initialize() async {
    if (_isDisposed) {
      throw const LlmError(
        message: 'Cannot initialize disposed provider',
        type: LlmErrorType.unavailable,
      );
    }
    if (_isInitialized) return;

    await doInitialize();
    _isInitialized = true;
  }

  /// Subclass implementation of initialization
  Future<void> doInitialize();

  @override
  Future<LlmResponse> generateResponse(LlmRequest request) async {
    _ensureReady();

    final stopwatch = Stopwatch()..start();
    try {
      final response = await doGenerateResponse(request).timeout(timeout);
      stopwatch.stop();

      return LlmResponse(
        content: response.content,
        providerInfo: providerInfo,
        tokensUsed: response.tokensUsed,
        latency: stopwatch.elapsed,
      );
    } on TimeoutException {
      throw const LlmError(
        message: 'LLM request timed out',
        type: LlmErrorType.timeout,
      );
    } catch (e) {
      if (e is LlmError) rethrow;
      throw LlmError(
        message: 'LLM generation failed: $e',
        type: LlmErrorType.unknown,
        originalError: e,
      );
    }
  }

  /// Subclass implementation of response generation
  Future<LlmResponse> doGenerateResponse(LlmRequest request);

  @override
  Stream<String> streamResponse(LlmRequest request) async* {
    _ensureReady();

    try {
      await for (final token in doStreamResponse(request).timeout(timeout)) {
        yield token;
      }
    } on TimeoutException {
      throw const LlmError(
        message: 'LLM stream timed out',
        type: LlmErrorType.timeout,
      );
    } catch (e) {
      if (e is LlmError) rethrow;
      throw LlmError(
        message: 'LLM streaming failed: $e',
        type: LlmErrorType.unknown,
        originalError: e,
      );
    }
  }

  /// Subclass implementation of streaming
  Stream<String> doStreamResponse(LlmRequest request);

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    doDispose();
  }

  /// Subclass implementation of disposal
  void doDispose();

  /// Ensure provider is ready for use
  void _ensureReady() {
    if (_isDisposed) {
      throw const LlmError(
        message: 'Provider has been disposed',
        type: LlmErrorType.unavailable,
      );
    }
    if (!_isInitialized) {
      throw const LlmError(
        message: 'Provider not initialized. Call initialize() first.',
        type: LlmErrorType.unavailable,
      );
    }
  }

  /// Truncate context to max messages
  List<LlmMessage> truncateContext(List<LlmMessage> context) {
    if (context.length <= maxContextMessages) return context;
    return context.sublist(context.length - maxContextMessages);
  }

  /// Build prompt with context
  String buildPromptWithContext(LlmRequest request) {
    final buffer = StringBuffer();

    // Add system prompt if provided
    if (request.systemPrompt != null) {
      buffer.writeln('System: ${request.systemPrompt}');
      buffer.writeln();
    }

    // Add conversation context
    final truncatedContext = truncateContext(request.context);
    for (final message in truncatedContext) {
      final role = message.role == LlmRole.user ? 'User' : 'Assistant';
      buffer.writeln('$role: ${message.content}');
    }

    // Add current prompt
    buffer.writeln('User: ${request.prompt}');
    buffer.writeln('Assistant:');

    return buffer.toString();
  }
}
