import 'dart:async';

import '../../core/llm/llm_service.dart';
import '../api/chat_service.dart';
import '../api/chat_service_request_model.dart';
import '../api/chat_service_response_model.dart';
import '../model/chat_message.dart';
import 'chat_entity.dart';

/// Callback for streaming updates
typedef StreamingCallback = void Function(ChatEntity entity);

/// Service adapter for chat operations
/// Handles streaming responses and maps between Entity and Service models
class ChatServiceAdapter {
  final ChatService _service;

  ChatServiceAdapter({ChatService? service})
      : _service = service ?? ChatService();

  /// Check if the service is available
  Future<bool> isAvailable() => _service.isAvailable();

  /// Get provider info
  LlmProviderInfo? get providerInfo => _service.providerInfo;

  /// Check if using on-device LLM
  bool get isOnDevice => _service.isOnDevice;

  /// Initialize the service
  Future<void> initialize() => _service.initialize();

  /// Refresh service availability
  Future<void> refresh() => _service.refresh();

  /// Stream a chat response
  /// Takes the current entity and streams updates via callback
  Future<ChatEntity> streamResponse({
    required ChatEntity entity,
    required String prompt,
    required String systemPrompt,
    required StreamingCallback onUpdate,
  }) async {
    final request = createRequest(entity, prompt, systemPrompt);
    final pendingMessageId = _getPendingMessageId(entity);

    ChatEntity currentEntity = entity;

    await for (final response in _service.streamResponse(request)) {
      currentEntity = updateEntityFromResponse(
        currentEntity,
        response,
        pendingMessageId,
      );
      onUpdate(currentEntity);
    }

    // Finalize the message
    currentEntity = finalizeMessage(currentEntity, pendingMessageId);
    return currentEntity;
  }

  /// Create request model from entity
  ChatServiceRequestModel createRequest(
    ChatEntity entity,
    String prompt,
    String systemPrompt,
  ) {
    final contextMessages = _buildContext(entity.messages);
    return ChatServiceRequestModel(
      prompt: prompt,
      context: contextMessages,
      systemPrompt: systemPrompt,
    );
  }

  /// Update entity from streaming response
  ChatEntity updateEntityFromResponse(
    ChatEntity entity,
    ChatServiceResponseModel response,
    String pendingMessageId,
  ) {
    final currentMessages = List<ChatMessage>.from(entity.messages);

    final pendingIndex = currentMessages.indexWhere(
      (m) => m.id == pendingMessageId,
    );

    if (pendingIndex >= 0) {
      currentMessages[pendingIndex] = currentMessages[pendingIndex].copyWith(
        content: response.content,
      );
    }

    return entity.merge(messages: currentMessages);
  }

  /// Finalize the pending message to sent status
  ChatEntity finalizeMessage(ChatEntity entity, String pendingMessageId) {
    final currentMessages = List<ChatMessage>.from(entity.messages);

    final pendingIndex = currentMessages.indexWhere(
      (m) => m.id == pendingMessageId,
    );

    if (pendingIndex >= 0) {
      final pendingMessage = currentMessages[pendingIndex];
      currentMessages[pendingIndex] = ChatMessage.assistant(
        content: pendingMessage.content,
        id: pendingMessage.id,
        isPrivate: _service.isOnDevice,
      );
    }

    return entity.merge(
      messages: currentMessages,
      isTyping: false,
    );
  }

  /// Get the pending message ID from entity
  String _getPendingMessageId(ChatEntity entity) {
    final pendingMessage = entity.messages.lastWhere(
      (m) => m.isPending,
      orElse: () => throw StateError('No pending message found'),
    );
    return pendingMessage.id;
  }

  /// Build LLM context from chat messages
  List<LlmMessage> _buildContext(List<ChatMessage> messages) {
    const maxContextMessages = 10;

    // Filter out pending messages and take last N
    final validMessages = messages.where((m) => !m.isPending).toList();
    final recentMessages = validMessages.length > maxContextMessages
        ? validMessages.sublist(validMessages.length - maxContextMessages)
        : validMessages;

    return recentMessages.map((m) {
      return LlmMessage(
        role: m.role == ChatRole.user ? LlmRole.user : LlmRole.assistant,
        content: m.content,
        timestamp: m.timestamp,
      );
    }).toList();
  }
}
