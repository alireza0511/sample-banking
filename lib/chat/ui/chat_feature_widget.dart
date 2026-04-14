import 'package:clean_framework/clean_framework.dart';
import 'package:flutter/material.dart';

import '../bloc/chat_bloc.dart';
import 'chat_presenter.dart';

/// Feature widget that provides DI for the chat feature
/// Following clean_framework pattern
class ChatFeatureWidget extends StatelessWidget {
  /// Optional initial prompt (from deep link)
  final String? initialPrompt;

  const ChatFeatureWidget({super.key, this.initialPrompt});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(),
      child: ChatPresenter(initialPrompt: initialPrompt),
    );
  }
}
