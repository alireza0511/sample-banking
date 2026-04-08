import 'dart:async';

/// LLM Provider types
enum LlmProviderType {
  onDevice,
  cloud,
  hybrid,
  mock,
}

/// Provider info for UI display
class LlmProviderInfo {
  final String name;
  final LlmProviderType type;
  final bool isPrivate;
  final String? modelName;

  const LlmProviderInfo({
    required this.name,
    required this.type,
    required this.isPrivate,
    this.modelName,
  });

  /// Check if data stays on device
  bool get isOnDevice => type == LlmProviderType.onDevice || type == LlmProviderType.mock;
}

/// Request for LLM generation
class LlmRequest {
  final String prompt;
  final List<LlmMessage> context;
  final String? systemPrompt;
  final double temperature;
  final int maxTokens;

  const LlmRequest({
    required this.prompt,
    this.context = const [],
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 1024,
  });
}

/// A message in the conversation context
class LlmMessage {
  final LlmRole role;
  final String content;
  final DateTime timestamp;

  const LlmMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

/// Role in conversation
enum LlmRole { user, assistant, system }

/// Response from LLM
class LlmResponse {
  final String content;
  final LlmProviderInfo providerInfo;
  final int? tokensUsed;
  final Duration? latency;

  const LlmResponse({
    required this.content,
    required this.providerInfo,
    this.tokensUsed,
    this.latency,
  });
}

/// Error during LLM operation
class LlmError implements Exception {
  final String message;
  final LlmErrorType type;
  final dynamic originalError;

  const LlmError({
    required this.message,
    required this.type,
    this.originalError,
  });

  @override
  String toString() => 'LlmError($type): $message';
}

/// Types of LLM errors
enum LlmErrorType {
  unavailable,
  timeout,
  invalidRequest,
  modelNotLoaded,
  outOfMemory,
  unknown,
}

/// Abstract LLM service interface - provider agnostic
/// Swap implementations without changing app code
abstract class LlmService {
  /// Check if this LLM provider is available
  Future<bool> isAvailable();

  /// Get provider info (name, type, privacy level)
  LlmProviderInfo get providerInfo;

  /// Generate a complete response (non-streaming)
  Future<LlmResponse> generateResponse(LlmRequest request);

  /// Stream response tokens as they're generated
  Stream<String> streamResponse(LlmRequest request);

  /// Initialize the service (load models, etc.)
  Future<void> initialize();

  /// Dispose resources
  void dispose();
}
