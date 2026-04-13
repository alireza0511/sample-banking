import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/speech/speech_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/tts/tts_manager.dart';
import '../../core/utils/haptic_feedback_helper.dart';
import '../../core/widgets/widgets.dart';
import '../bloc/chat_bloc.dart';
import '../model/chat_message.dart';
import '../services/chat_storage_service.dart';
import '../services/suggestion_service.dart';
import '../widgets/rich_message_content.dart';
import '../widgets/voice_mode_overlay.dart';

/// Chat screen with AI assistant
class ChatScreen extends StatefulWidget {
  /// Optional initial prompt (from deep link)
  final String? initialPrompt;

  const ChatScreen({super.key, this.initialPrompt});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _bloc;
  bool _blocInitialized = false;
  bool _isVoiceModeActive = false;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Create bloc with voice services from Provider
    if (!_blocInitialized) {
      _initializeBloc();
      _blocInitialized = true;

      // Handle initial prompt from deep link
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _inputController.text = widget.initialPrompt!;
        });
      }
    }
  }

  Future<void> _initializeBloc() async {
    final speechManager = Provider.of<SpeechManager>(context, listen: false);
    final ttsManager = Provider.of<TtsManager>(context, listen: false);

    // Initialize SharedPreferences for chat storage
    final prefs = await SharedPreferences.getInstance();
    final storageService = ChatStorageService(prefs);

    _bloc = ChatBloc(
      speechManager: speechManager,
      ttsManager: ttsManager,
      storageService: storageService,
    );
  }

  @override
  void dispose() {
    _bloc.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _inputController.text.trim();
    if (message.isEmpty) return;

    HapticFeedbackHelper.lightImpact();
    _bloc.sendMessagePipe.send(message);
    _inputController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider<ChatBloc>.value(
      value: _bloc,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
          title: const Text('Chat'),
          actions: [
            StreamBuilder<ChatViewModel>(
              stream: _bloc.viewModelPipe.receive,
              builder: (context, snapshot) {
                final viewModel = snapshot.data;
                return _PrivacyIndicator(
                  isOnDevice: viewModel?.isOnDevice ?? false,
                  providerName: viewModel?.privacyText ?? 'AI',
                );
              },
            ),
            // Voice output toggle
            StreamBuilder<ChatViewModel>(
              stream: _bloc.viewModelPipe.receive,
              builder: (context, snapshot) {
                final viewModel = snapshot.data;
                final voiceEnabled = viewModel?.voiceOutputEnabled ?? false;

                return Semantics(
                  label: voiceEnabled
                      ? 'Voice output enabled. Tap to disable.'
                      : 'Voice output disabled. Tap to enable.',
                  button: true,
                  enabled: true,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedbackHelper.selection();
                      _bloc.toggleVoiceOutputPipe.launch();
                    },
                    icon: Icon(
                      voiceEnabled ? Icons.volume_up : Icons.volume_off,
                      color: voiceEnabled ? AppColors.primaryBlue : null,
                    ),
                    tooltip: voiceEnabled ? 'Disable voice output' : 'Enable voice output',
                  ),
                );
              },
            ),
            // Voice mode button
            IconButton(
              onPressed: () {
                setState(() {
                  _isVoiceModeActive = true;
                });
              },
              icon: const Icon(Icons.graphic_eq),
              tooltip: 'Voice mode',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _bloc.clearChatPipe.launch();
                } else if (value == 'refresh') {
                  _bloc.refreshPipe.launch();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear chat'),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Text('Refresh AI status'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<ChatViewModel>(
                stream: _bloc.viewModelPipe.receive,
                builder: (context, snapshot) {
                  final viewModel = snapshot.data;

                  if (viewModel == null || viewModel.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: AppSpacing.md),
                          Text('Initializing AI...'),
                        ],
                      ),
                    );
                  }

                  if (!viewModel.isLlmAvailable) {
                    return ErrorView(
                      message: viewModel.errorMessage ?? 'AI assistant is not available',
                      onRetry: () => _bloc.refreshPipe.launch(),
                    );
                  }

                  if (viewModel.isEmpty) {
                    return const _WelcomeView();
                  }

                  return _ChatMessageList(
                    messages: viewModel.messages,
                    isTyping: viewModel.isTyping,
                    scrollController: _scrollController,
                    onRetry: () => _bloc.retryPipe.launch(),
                  );
                },
              ),
            ),
            // Suggestions
            StreamBuilder<ChatViewModel>(
              stream: _bloc.viewModelPipe.receive,
              builder: (context, snapshot) {
                final viewModel = snapshot.data;
                final suggestions = viewModel?.suggestions ?? [];

                if (suggestions.isEmpty || viewModel?.isTyping == true) {
                  return const SizedBox.shrink();
                }

                return _SuggestionsRow(
                  suggestions: suggestions,
                  onSuggestionTap: (suggestion) {
                    _inputController.text = suggestion.text;
                    _inputFocusNode.requestFocus();
                  },
                );
              },
            ),
            StreamBuilder<ChatViewModel>(
              stream: _bloc.viewModelPipe.receive,
              builder: (context, snapshot) {
                final viewModel = snapshot.data;
                final canSend = viewModel?.canSendMessage ?? false;

                return _ChatInput(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  enabled: canSend,
                  isTyping: viewModel?.isTyping ?? false,
                  onSend: _sendMessage,
                  isListening: viewModel?.isListening ?? false,
                  voiceInputText: viewModel?.voiceInputText ?? '',
                  onToggleVoiceInput: () {
                    HapticFeedbackHelper.selection();
                    _bloc.toggleVoiceInputPipe.launch();
                  },
                );
              },
            ),
          ],
        ),
            ),
          ),
          // Voice mode overlay
          if (_isVoiceModeActive)
            StreamBuilder<ChatViewModel>(
              stream: _bloc.viewModelPipe.receive,
              builder: (context, snapshot) {
                final viewModel = snapshot.data;
                return VoiceModeOverlay(
                  isListening: viewModel?.isListening ?? false,
                  isSpeaking: false, // TODO: Track TTS speaking state
                  transcriptionText: viewModel?.voiceInputText ?? '',
                  onClose: () {
                    setState(() {
                      _isVoiceModeActive = false;
                    });
                    // Stop listening if active
                    if (viewModel?.isListening == true) {
                      HapticFeedbackHelper.selection();
                      _bloc.toggleVoiceInputPipe.launch();
                    }
                  },
                  onToggleListening: () {
                    HapticFeedbackHelper.selection();
                    _bloc.toggleVoiceInputPipe.launch();
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Privacy indicator badge
class _PrivacyIndicator extends StatelessWidget {
  final bool isOnDevice;
  final String providerName;

  const _PrivacyIndicator({
    required this.isOnDevice,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOnDevice
            ? AppColors.privacyOnDevice.withValues(alpha: 0.1)
            : AppColors.privacyCloud.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isOnDevice ? AppColors.privacyOnDevice : AppColors.privacyCloud,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnDevice ? Icons.phone_android : Icons.cloud_outlined,
            size: 14,
            color: isOnDevice ? AppColors.privacyOnDevice : AppColors.privacyCloud,
          ),
          const SizedBox(width: 4),
          Text(
            providerName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isOnDevice ? AppColors.privacyOnDevice : AppColors.privacyCloud,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Welcome view shown when chat is empty
class _WelcomeView extends StatelessWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Welcome icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Center(
            child: Text(
              WelcomeMessage.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Subtitle
          Center(
            child: Text(
              WelcomeMessage.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Capabilities
          ...WelcomeMessage.capabilities.map((capability) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      capability,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )),

          const SizedBox(height: AppSpacing.xl),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.privacyOnDevice.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.privacyOnDevice.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: AppColors.privacyOnDevice,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    WelcomeMessage.privacyNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.privacyOnDevice,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List of chat messages
class _ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final ScrollController scrollController;
  final VoidCallback onRetry;

  const _ChatMessageList({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // Dismiss keyboard when user starts scrolling
        if (scrollNotification is ScrollStartNotification) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md,
        ),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _MessageBubble(
            message: message,
            onRetry: message.isError ? onRetry : null,
          );
        },
      ),
    );
  }
}

/// Single message bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Semantics(
      label: isUser
          ? 'You said: ${message.content}'
          : message.isError
              ? 'Error: ${message.content}'
              : 'Assistant said: ${message.content}',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _Avatar(isUser: false),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primaryBlue
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.radiusMd),
                      topRight: const Radius.circular(AppSpacing.radiusMd),
                      bottomLeft:
                          Radius.circular(isUser ? AppSpacing.radiusMd : AppSpacing.radiusSm),
                      bottomRight:
                          Radius.circular(isUser ? AppSpacing.radiusSm : AppSpacing.radiusMd),
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: message.isPending
                      ? const _TypingIndicator()
                      : RichMessageContent(
                          content: message.content,
                          isUser: isUser,
                        ),
                ),
                if (message.isError && onRetry != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            _Avatar(isUser: true),
          ],
        ],
        ),
      ),
    );
  }
}

/// Avatar for user or assistant
class _Avatar extends StatelessWidget {
  final bool isUser;

  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.primaryBlue.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy_outlined,
        size: 18,
        color: isUser ? AppColors.primaryBlue : AppColors.success,
      ),
    );
  }
}

/// Typing indicator animation
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final opacity = (value < 0.5 ? value : 1 - value) * 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3 + (opacity * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Chat input field
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isTyping;
  final VoidCallback onSend;
  final bool isListening;
  final String voiceInputText;
  final VoidCallback onToggleVoiceInput;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isTyping,
    required this.onSend,
    required this.isListening,
    required this.voiceInputText,
    required this.onToggleVoiceInput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice input indicator
          if (isListening) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Listening...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (voiceInputText.isNotEmpty)
                    Expanded(
                      child: Text(
                        voiceInputText,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          // Input row
          Row(
            children: [
              // Voice input button
              Semantics(
                label: isListening
                    ? 'Listening. Tap to stop voice input.'
                    : 'Voice input. Tap to start speaking.',
                button: true,
                enabled: enabled,
                child: IconButton(
                  onPressed: enabled ? onToggleVoiceInput : null,
                  icon: Icon(
                    isListening ? Icons.mic_off : Icons.mic,
                    color: isListening ? AppColors.error : AppColors.primaryBlue,
                  ),
                  tooltip: isListening ? 'Stop listening' : 'Voice input',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Text input
              Expanded(
                child: Semantics(
                  label: 'Message input field',
                  hint: isTyping
                      ? 'AI is typing, please wait'
                      : isListening
                          ? 'Voice input active'
                          : 'Type your message here',
                  textField: true,
                  enabled: enabled && !isListening,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled && !isListening,
                    decoration: InputDecoration(
                      hintText: isTyping
                          ? 'AI is typing...'
                          : isListening
                              ? 'Listening...'
                              : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Send button
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return Semantics(
                    label: hasText && enabled && !isListening
                        ? 'Send message'
                        : 'Send message. Disabled. Type a message first.',
                    button: true,
                    enabled: hasText && enabled && !isListening,
                    child: IconButton.filled(
                      onPressed: hasText && enabled && !isListening ? onSend : null,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            hasText && enabled && !isListening ? AppColors.primaryBlue : AppColors.divider,
                        foregroundColor:
                            hasText && enabled && !isListening ? Colors.white : AppColors.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Suggestions row widget
class _SuggestionsRow extends StatelessWidget {
  final List<Suggestion> suggestions;
  final void Function(Suggestion) onSuggestionTap;

  const _SuggestionsRow({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Semantics(
                label: 'Suggestion: ${suggestion.displayText}. Tap to use.',
                button: true,
                child: ActionChip(
                  label: Text(suggestion.displayText),
                  onPressed: () => onSuggestionTap(suggestion),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  side: BorderSide(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
