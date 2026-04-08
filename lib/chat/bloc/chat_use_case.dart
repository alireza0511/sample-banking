import 'dart:async';

import 'package:clean_framework/clean_framework.dart';

import '../../core/llm/llm_manager.dart';
import '../../core/llm/llm_service.dart';
import '../model/chat_message.dart';
import 'chat_entity.dart';
import 'chat_view_model.dart';

/// Use case for managing chat functionality
class ChatUseCase extends UseCase {
  final ViewModelCallback<ChatViewModel> _viewModelCallback;
  final LlmManager _llmManager;

  ChatEntity _entity = ChatEntity();
  StreamSubscription<String>? _streamSubscription;

  /// System prompt for banking assistant
  static const String _systemPrompt = '''
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

  /// Maximum messages to keep in context
  static const int _maxContextMessages = 10;

  ChatUseCase(
    this._viewModelCallback, {
    LlmManager? llmManager,
  }) : _llmManager = llmManager ?? LlmManager();

  /// Initialize the chat and check LLM availability
  Future<void> initialize() async {
    _entity = _entity.merge(isLoading: true, errorMessage: null);
    _notifyListeners();

    try {
      await _llmManager.initialize();

      final isAvailable = await _llmManager.isAvailable();

      _entity = _entity.merge(
        isLoading: false,
        isLlmAvailable: isAvailable,
        providerInfo: _llmManager.providerInfo,
      );
      _notifyListeners();
    } catch (e) {
      _entity = _entity.merge(
        isLoading: false,
        isLlmAvailable: false,
        errorMessage: 'Failed to initialize AI: $e',
      );
      _notifyListeners();
    }
  }

  /// Send a message and get a response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (!_entity.canSendMessage) return;

    // Add user message
    final userMessage = ChatMessage.user(content: content.trim());
    final updatedMessages = [..._entity.messages, userMessage];

    // Add pending assistant message
    final pendingMessage = ChatMessage.pending();
    final messagesWithPending = [...updatedMessages, pendingMessage];

    _entity = _entity.merge(
      messages: messagesWithPending,
      isTyping: true,
      errorMessage: null,
      currentInput: '',
    );
    _notifyListeners();

    try {
      // Build context from recent messages
      final contextMessages = _buildContext(updatedMessages);

      final request = LlmRequest(
        prompt: content.trim(),
        context: contextMessages,
        systemPrompt: _systemPrompt,
      );

      // Use streaming for better UX
      final responseBuffer = StringBuffer();

      await for (final token in _llmManager.streamResponse(request)) {
        responseBuffer.write(token);

        // Update the pending message with streamed content
        final currentMessages = List<ChatMessage>.from(_entity.messages);
        if (currentMessages.isNotEmpty && currentMessages.last.isPending) {
          currentMessages[currentMessages.length - 1] = currentMessages.last.copyWith(
            content: responseBuffer.toString(),
          );
          _entity = _entity.merge(messages: currentMessages);
          _notifyListeners();
        }
      }

      // Finalize the assistant message
      final assistantMessage = ChatMessage.assistant(
        content: responseBuffer.toString(),
        id: pendingMessage.id,
        isPrivate: _llmManager.isOnDevice,
      );

      final finalMessages = List<ChatMessage>.from(_entity.messages);
      if (finalMessages.isNotEmpty) {
        finalMessages[finalMessages.length - 1] = assistantMessage;
      }

      _entity = _entity.merge(
        messages: finalMessages,
        isTyping: false,
      );
      _notifyListeners();
    } on LlmError catch (e) {
      _handleError(e.message, pendingMessage.id);
    } catch (e) {
      _handleError('An error occurred: $e', pendingMessage.id);
    }
  }

  /// Handle error and update the pending message to error state
  void _handleError(String errorMessage, String pendingMessageId) {
    final currentMessages = List<ChatMessage>.from(_entity.messages);

    // Find and update the pending message to error state
    final pendingIndex = currentMessages.indexWhere((m) => m.id == pendingMessageId);
    if (pendingIndex >= 0) {
      currentMessages[pendingIndex] = currentMessages[pendingIndex].copyWith(
        content: 'Sorry, I encountered an error. Please try again.',
        status: MessageStatus.error,
      );
    }

    _entity = _entity.merge(
      messages: currentMessages,
      isTyping: false,
      errorMessage: errorMessage,
    );
    _notifyListeners();
  }

  /// Build LLM context from chat messages
  List<LlmMessage> _buildContext(List<ChatMessage> messages) {
    // Take last N messages for context
    final recentMessages = messages.length > _maxContextMessages
        ? messages.sublist(messages.length - _maxContextMessages)
        : messages;

    return recentMessages.map((m) {
      return LlmMessage(
        role: m.role == ChatRole.user ? LlmRole.user : LlmRole.assistant,
        content: m.content,
        timestamp: m.timestamp,
      );
    }).toList();
  }

  /// Update current input text
  void updateInput(String input) {
    _entity = _entity.merge(currentInput: input);
    // Don't notify for input changes to avoid rebuilds
  }

  /// Clear chat history
  void clearChat() {
    _entity = _entity.merge(
      messages: [],
      errorMessage: null,
    );
    _notifyListeners();
  }

  /// Retry the last failed message
  Future<void> retryLastMessage() async {
    if (_entity.messages.isEmpty) return;

    // Find the last user message
    final lastUserIndex = _entity.messages.lastIndexWhere((m) => m.isUser);
    if (lastUserIndex < 0) return;

    final lastUserMessage = _entity.messages[lastUserIndex];

    // Remove messages after (and including) the failed assistant message
    final messagesBeforeError = _entity.messages.sublist(0, lastUserIndex);
    _entity = _entity.merge(messages: messagesBeforeError);
    _notifyListeners();

    // Resend the message
    await sendMessage(lastUserMessage.content);
  }

  /// Refresh LLM availability
  Future<void> refreshLlmStatus() async {
    await _llmManager.refresh();

    _entity = _entity.merge(
      isLlmAvailable: await _llmManager.isAvailable(),
      providerInfo: _llmManager.providerInfo,
    );
    _notifyListeners();
  }

  void _notifyListeners() {
    _viewModelCallback(ChatViewModel.fromEntity(_entity));
  }

  /// Dispose resources
  void dispose() {
    _streamSubscription?.cancel();
    _llmManager.dispose();
  }
}
