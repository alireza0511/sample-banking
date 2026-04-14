import 'package:clean_framework/clean_framework.dart';
import 'package:flutter/material.dart';

import '../../core/locator.dart';
import '../bloc/chat_bloc.dart';
import 'chat_presenter.dart';

/// Feature widget that provides DI for the chat feature
/// Following clean_framework pattern
class ChatFeatureWidget extends StatefulWidget {
  /// Optional initial prompt (from deep link)
  final String? initialPrompt;

  const ChatFeatureWidget({super.key, this.initialPrompt});

  @override
  State<ChatFeatureWidget> createState() => _ChatFeatureWidgetState();
}

class _ChatFeatureWidgetState extends State<ChatFeatureWidget> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeManagers();
  }

  Future<void> _initializeManagers() async {
    try {
      // Initialize LLM manager with fallback chain
      await AppLocator.llmManager.initialize();

      // Initialize speech manager with fallback chain
      await AppLocator.speechManager.initialize();

      // Initialize TTS manager with fallback chain
      await AppLocator.ttsManager.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize chat: $_initError',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initError = null;
                    });
                    _initializeManagers();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocProvider(
      create: (_) => ChatBloc(),
      child: ChatPresenter(initialPrompt: widget.initialPrompt),
    );
  }
}
