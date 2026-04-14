import 'dart:async';

import 'package:clean_framework/clean_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/llm/llm_service.dart';
import '../../core/locator.dart';
import '../../core/speech/speech_manager.dart';
import '../../core/tts/tts_manager.dart';
import '../model/chat_message.dart';
import '../services/chat_storage_service.dart';
import '../services/suggestion_service.dart';
import 'chat_entity.dart';
import 'chat_service_adapter.dart';
import 'chat_view_model.dart';

/// Use case for managing chat functionality
/// Following clean_framework pattern with service locator
class ChatUseCase extends UseCase {
  final ViewModelCallback<ChatViewModel> _viewModelCallback;
  final ChatServiceAdapter _serviceAdapter;
  final SuggestionService _suggestionService = SuggestionService();

  ChatEntity _entity = ChatEntity();
  ChatStorageService? _storageService;
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

  ChatUseCase(
    this._viewModelCallback, {
    ChatServiceAdapter? serviceAdapter,
  }) : _serviceAdapter = serviceAdapter ?? ChatServiceAdapter();

  /// Access managers via AppLocator
  SpeechManager get _speechManager => AppLocator.speechManager;
  TtsManager get _ttsManager => AppLocator.ttsManager;

  /// Initialize the chat (create method following clean_framework pattern)
  Future<void> create() async {
    _entity = _entity.merge(isLoading: true, errorMessage: null);
    _notifyListeners();

    try {
      // Initialize service adapter
      await _serviceAdapter.initialize();

      final isAvailable = await _serviceAdapter.isAvailable();

      // Initialize storage service
      final prefs = await SharedPreferences.getInstance();
      _storageService = ChatStorageService(prefs);

      // Load chat history from storage
      List<ChatMessage> messages = [];
      if (_storageService != null) {
        messages = await _storageService!.loadMessages();
      }

      _entity = _entity.merge(
        isLoading: false,
        isLlmAvailable: isAvailable,
        providerInfo: _serviceAdapter.providerInfo,
        messages: messages,
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
      // Use service adapter for streaming response
      _entity = await _serviceAdapter.streamResponse(
        entity: _entity,
        prompt: content.trim(),
        systemPrompt: _systemPrompt,
        onUpdate: (updatedEntity) {
          _entity = updatedEntity;
          _notifyListeners();
        },
      );
      _notifyListeners();

      // Save messages to storage
      await _saveMessages();

      // Speak the response if voice output is enabled
      if (_entity.voiceOutputEnabled) {
        final lastMessage = _entity.messages.lastOrNull;
        if (lastMessage != null && lastMessage.isAssistant && lastMessage.content.isNotEmpty) {
          await _ttsManager.speak(
            lastMessage.content,
            onError: (error) {
              // Silent fail for TTS errors - don't interrupt user experience
            },
          );
        }
      }
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

  /// Update current input text
  void updateInput(String input) {
    _entity = _entity.merge(currentInput: input);
    // Don't notify for input changes to avoid rebuilds
  }

  /// Clear chat history
  Future<void> clearChat() async {
    _entity = _entity.merge(
      messages: [],
      errorMessage: null,
    );
    _notifyListeners();

    // Clear storage
    if (_storageService != null) {
      await _storageService!.clearMessages();
    }
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
    await _serviceAdapter.refresh();

    _entity = _entity.merge(
      isLlmAvailable: await _serviceAdapter.isAvailable(),
      providerInfo: _serviceAdapter.providerInfo,
    );
    _notifyListeners();
  }

  /// Toggle voice input (start/stop listening)
  Future<void> toggleVoiceInput() async {
    if (_entity.isListening) {
      await _stopVoiceInput();
    } else {
      await _startVoiceInput();
    }
  }

  /// Start voice input
  Future<void> _startVoiceInput() async {
    // Check permission first
    if (!await _speechManager.hasPermission()) {
      final granted = await _speechManager.requestPermission();
      if (!granted) {
        _entity = _entity.merge(
          errorMessage: 'Microphone permission is required for voice input',
        );
        _notifyListeners();
        return;
      }
    }

    _entity = _entity.merge(
      isListening: true,
      voiceInputText: '',
      errorMessage: null,
    );
    _notifyListeners();

    try {
      await _speechManager.startListening(
        onResult: (result) {
          // Update partial results
          _entity = _entity.merge(voiceInputText: result.recognizedWords);
          _notifyListeners();

          // When final, send the message
          if (result.isFinal && result.recognizedWords.trim().isNotEmpty) {
            _stopVoiceInput();
            sendMessage(result.recognizedWords);
          }
        },
        onError: (error) {
          _entity = _entity.merge(
            isListening: false,
            errorMessage: 'Voice recognition error: $error',
          );
          _notifyListeners();
        },
        partialResults: true,
      );
    } catch (e) {
      _entity = _entity.merge(
        isListening: false,
        errorMessage: 'Failed to start voice input: $e',
      );
      _notifyListeners();
    }
  }

  /// Stop voice input
  Future<void> _stopVoiceInput() async {
    await _speechManager.stopListening();
    _entity = _entity.merge(
      isListening: false,
      voiceInputText: '',
    );
    _notifyListeners();
  }

  /// Toggle voice output (enable/disable TTS)
  Future<void> toggleVoiceOutput() async {
    final newValue = !_entity.voiceOutputEnabled;

    // If turning off, stop any ongoing speech
    if (!newValue && _ttsManager.isSpeaking) {
      await _ttsManager.stop();
    }

    _entity = _entity.merge(voiceOutputEnabled: newValue);
    _notifyListeners();
  }

  void _notifyListeners() {
    // Update suggestions based on current messages
    final suggestions = _suggestionService.getSuggestions(_entity.messages);
    _entity = _entity.merge(suggestions: suggestions);

    _viewModelCallback(ChatViewModel.fromEntity(_entity));
  }

  /// Save current messages to storage
  Future<void> _saveMessages() async {
    if (_storageService != null) {
      await _storageService!.saveMessages(_entity.messages);
    }
  }

  /// Dispose resources
  void dispose() {
    _streamSubscription?.cancel();
  }
}
