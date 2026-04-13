import 'package:clean_framework/clean_framework.dart';

import '../../core/llm/llm_service.dart';
import '../model/chat_message.dart';
import '../services/suggestion_service.dart';

/// Entity representing the chat screen state
class ChatEntity extends Entity {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? errorMessage;
  final LlmProviderInfo? providerInfo;
  final bool isLlmAvailable;
  final String currentInput;
  final bool isListening;
  final bool voiceOutputEnabled;
  final String voiceInputText;
  final List<Suggestion> suggestions;

  ChatEntity({
    List<EntityFailure> errors = const [],
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.errorMessage,
    this.providerInfo,
    this.isLlmAvailable = false,
    this.currentInput = '',
    this.isListening = false,
    this.voiceOutputEnabled = false,
    this.voiceInputText = '',
    this.suggestions = const [],
  }) : super(errors: errors);

  @override
  ChatEntity merge({
    List<EntityFailure>? errors,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? errorMessage,
    LlmProviderInfo? providerInfo,
    bool? isLlmAvailable,
    String? currentInput,
    bool? isListening,
    bool? voiceOutputEnabled,
    String? voiceInputText,
    List<Suggestion>? suggestions,
  }) {
    return ChatEntity(
      errors: errors ?? this.errors,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage,
      providerInfo: providerInfo ?? this.providerInfo,
      isLlmAvailable: isLlmAvailable ?? this.isLlmAvailable,
      currentInput: currentInput ?? this.currentInput,
      isListening: isListening ?? this.isListening,
      voiceOutputEnabled: voiceOutputEnabled ?? this.voiceOutputEnabled,
      voiceInputText: voiceInputText ?? this.voiceInputText,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  /// Get last N messages for context
  List<ChatMessage> getContextMessages(int count) {
    if (messages.length <= count) return messages;
    return messages.sublist(messages.length - count);
  }

  /// Check if chat has messages
  bool get hasMessages => messages.isNotEmpty;

  /// Check if we can send a message
  bool get canSendMessage => !isTyping && !isLoading && isLlmAvailable;

  /// Check if we're using on-device LLM
  bool get isOnDevice => providerInfo?.isOnDevice ?? false;

  @override
  List<Object?> get props => [
        errors,
        messages,
        isLoading,
        isTyping,
        errorMessage,
        providerInfo,
        isLlmAvailable,
        currentInput,
        isListening,
        voiceOutputEnabled,
        voiceInputText,
        suggestions,
      ];
}
