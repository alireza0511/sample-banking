import 'dart:async';

import '../../core/llm/llm_manager.dart';
import '../../core/llm/llm_service.dart';
import '../../core/locator.dart';
import 'chat_service_request_model.dart';
import 'chat_service_response_model.dart';

/// Service wrapper for LLM chat operations
/// Provides a clean interface between the use case and the LlmManager
class ChatService {
  final LlmManager _llmManager;

  ChatService({LlmManager? llmManager})
      : _llmManager = llmManager ?? AppLocator.llmManager;

  /// Check if LLM is available
  Future<bool> isAvailable() => _llmManager.isAvailable();

  /// Get provider info for UI display
  LlmProviderInfo? get providerInfo => _llmManager.providerInfo;

  /// Check if using on-device LLM
  bool get isOnDevice => _llmManager.isOnDevice;

  /// Initialize the LLM service
  Future<void> initialize() => _llmManager.initialize();

  /// Refresh LLM availability
  Future<void> refresh() => _llmManager.refresh();

  /// Stream response tokens for a given request
  /// Returns a stream of ChatServiceResponseModel for each token
  Stream<ChatServiceResponseModel> streamResponse(
    ChatServiceRequestModel request,
  ) async* {
    final llmRequest = request.toRequest();
    final buffer = StringBuffer();

    await for (final token in _llmManager.streamResponse(llmRequest)) {
      buffer.write(token);
      yield ChatServiceResponseModel.streaming(
        content: buffer.toString(),
        isOnDevice: isOnDevice,
      );
    }

    // Yield final complete response
    yield ChatServiceResponseModel.complete(
      content: buffer.toString(),
      isOnDevice: isOnDevice,
    );
  }

  /// Generate a complete response (non-streaming)
  Future<ChatServiceResponseModel> generateResponse(
    ChatServiceRequestModel request,
  ) async {
    final llmRequest = request.toRequest();
    final response = await _llmManager.generateResponse(llmRequest);

    return ChatServiceResponseModel.complete(
      content: response.content,
      isOnDevice: providerInfo?.isOnDevice ?? false,
    );
  }

  /// Dispose resources
  void dispose() {
    // LlmManager is managed by AppLocator, don't dispose here
  }
}
