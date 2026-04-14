import 'package:equatable/equatable.dart';

import '../../core/llm/llm_service.dart';

/// Request model for chat LLM service
class ChatServiceRequestModel extends Equatable {
  final String prompt;
  final List<LlmMessage> context;
  final String? systemPrompt;

  const ChatServiceRequestModel({
    required this.prompt,
    this.context = const [],
    this.systemPrompt,
  });

  /// Convert to LlmRequest
  LlmRequest toRequest() {
    return LlmRequest(
      prompt: prompt,
      context: context,
      systemPrompt: systemPrompt,
    );
  }

  @override
  List<Object?> get props => [prompt, context, systemPrompt];
}
