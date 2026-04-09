import 'package:clean_framework/clean_framework.dart';

import '../../core/speech/speech_manager.dart';
import '../../core/tts/tts_manager.dart';
import 'chat_use_case.dart';
import 'chat_view_model.dart';

export 'chat_view_model.dart';

/// Bloc for managing chat screen
class ChatBloc extends Bloc {
  late final ChatUseCase _useCase;

  final viewModelPipe = Pipe<ChatViewModel>();
  final sendMessagePipe = Pipe<String>();
  final clearChatPipe = EventPipe();
  final retryPipe = EventPipe();
  final refreshPipe = EventPipe();
  final toggleVoiceInputPipe = EventPipe();
  final toggleVoiceOutputPipe = EventPipe();

  @override
  void dispose() {
    viewModelPipe.dispose();
    sendMessagePipe.dispose();
    clearChatPipe.dispose();
    retryPipe.dispose();
    refreshPipe.dispose();
    toggleVoiceInputPipe.dispose();
    toggleVoiceOutputPipe.dispose();
    _useCase.dispose();
  }

  ChatBloc({
    SpeechManager? speechManager,
    TtsManager? ttsManager,
  }) {
    _useCase = ChatUseCase(
      viewModelPipe.send,
      speechManager: speechManager,
      ttsManager: ttsManager,
    );

    // Initialize when first listened to
    viewModelPipe.whenListenedDo(_useCase.initialize);

    // Handle send message
    sendMessagePipe.receive.listen((message) {
      if (message.isNotEmpty) {
        _useCase.sendMessage(message);
      }
    });

    // Handle clear chat
    clearChatPipe.listen(_useCase.clearChat);

    // Handle retry
    retryPipe.listen(_useCase.retryLastMessage);

    // Handle refresh
    refreshPipe.listen(_useCase.refreshLlmStatus);

    // Handle voice input toggle
    toggleVoiceInputPipe.listen(_useCase.toggleVoiceInput);

    // Handle voice output toggle
    toggleVoiceOutputPipe.listen(_useCase.toggleVoiceOutput);
  }
}
