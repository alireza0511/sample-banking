import 'package:clean_framework/clean_framework.dart';

import '../../core/llm/llm_service.dart';
import '../model/chat_message.dart';
import 'chat_entity.dart';

/// View model for the chat screen
class ChatViewModel extends ViewModel {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? errorMessage;
  final LlmProviderInfo? providerInfo;
  final bool isLlmAvailable;
  final bool canSendMessage;
  final bool isOnDevice;

  ChatViewModel({
    required this.messages,
    required this.isLoading,
    required this.isTyping,
    this.errorMessage,
    this.providerInfo,
    required this.isLlmAvailable,
    required this.canSendMessage,
    required this.isOnDevice,
  });

  factory ChatViewModel.fromEntity(ChatEntity entity) {
    return ChatViewModel(
      messages: entity.messages,
      isLoading: entity.isLoading,
      isTyping: entity.isTyping,
      errorMessage: entity.errorMessage,
      providerInfo: entity.providerInfo,
      isLlmAvailable: entity.isLlmAvailable,
      canSendMessage: entity.canSendMessage,
      isOnDevice: entity.isOnDevice,
    );
  }

  factory ChatViewModel.initial() {
    return ChatViewModel(
      messages: const [],
      isLoading: true,
      isTyping: false,
      isLlmAvailable: false,
      canSendMessage: false,
      isOnDevice: false,
    );
  }

  /// Check if we have an error
  bool get hasError => errorMessage != null;

  /// Check if chat is empty (no messages)
  bool get isEmpty => messages.isEmpty;

  /// Get the privacy indicator text
  String get privacyText {
    if (providerInfo == null) return 'AI';
    if (providerInfo!.isOnDevice) {
      return 'On-device';
    }
    return providerInfo!.name;
  }

  /// Get provider display name
  String get providerName => providerInfo?.name ?? 'AI Assistant';

  /// Get model name if available
  String? get modelName => providerInfo?.modelName;

  @override
  List<Object?> get props => [
        messages,
        isLoading,
        isTyping,
        errorMessage,
        providerInfo,
        isLlmAvailable,
        canSendMessage,
        isOnDevice,
      ];
}
