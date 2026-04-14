import 'dart:async';

import 'package:clean_framework/clean_framework.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic_feedback_helper.dart';
import '../bloc/chat_bloc.dart';
import 'chat_screen.dart';

/// Presenter for chat feature
/// Handles stream subscription and state management
class ChatPresenter extends Presenter<ChatBloc, ChatViewModel, ChatScreen> {
  final String? initialPrompt;

  // ignore: use_key_in_widget_constructors
  ChatPresenter({this.initialPrompt});

  @override
  Stream<ChatViewModel> getViewModelStream(ChatBloc bloc) {
    return bloc.viewModelPipe.receive;
  }

  @override
  ChatScreen buildScreen(
    BuildContext context,
    ChatBloc bloc,
    ChatViewModel viewModel,
  ) {
    return ChatScreen(
      viewModel: viewModel,
      initialPrompt: initialPrompt,
      onSendMessage: (message) {
        HapticFeedbackHelper.lightImpact();
        bloc.sendMessagePipe.send(message);
      },
      onClearChat: () {
        bloc.clearChatPipe.launch();
      },
      onRetry: () {
        bloc.retryPipe.launch();
      },
      onRefresh: () {
        bloc.refreshPipe.launch();
      },
      onToggleVoiceInput: () {
        HapticFeedbackHelper.selection();
        bloc.toggleVoiceInputPipe.launch();
      },
      onToggleVoiceOutput: () {
        HapticFeedbackHelper.selection();
        bloc.toggleVoiceOutputPipe.launch();
      },
    );
  }

  @override
  Widget buildLoadingScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Initializing AI...'),
          ],
        ),
      ),
    );
  }

  @override
  void onViewModelUpdate(
    BuildContext context,
    ChatBloc bloc,
    ChatViewModel viewModel,
  ) {
    // Handle any side effects based on ViewModel changes
    // Error dialogs could be shown here if needed
  }
}
