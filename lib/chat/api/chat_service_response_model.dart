import 'package:equatable/equatable.dart';

/// Response model from chat LLM service
class ChatServiceResponseModel extends Equatable {
  final String content;
  final bool isOnDevice;
  final bool isComplete;

  const ChatServiceResponseModel({
    required this.content,
    required this.isOnDevice,
    this.isComplete = true,
  });

  /// Create a streaming (partial) response
  const ChatServiceResponseModel.streaming({
    required this.content,
    required this.isOnDevice,
  }) : isComplete = false;

  /// Create a completed response
  const ChatServiceResponseModel.complete({
    required this.content,
    required this.isOnDevice,
  }) : isComplete = true;

  @override
  List<Object?> get props => [content, isOnDevice, isComplete];
}
