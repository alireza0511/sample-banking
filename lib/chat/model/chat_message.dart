import 'package:equatable/equatable.dart';

/// Role of a chat message sender
enum ChatRole {
  user,
  assistant,
  system,
}

/// A single chat message
class ChatMessage extends Equatable {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isPrivate;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isPrivate = true,
  });

  /// Create a user message
  factory ChatMessage.user({
    required String content,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  /// Create an assistant message
  factory ChatMessage.assistant({
    required String content,
    String? id,
    bool isPrivate = true,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isPrivate: isPrivate,
    );
  }

  /// Create a pending assistant message (for streaming)
  factory ChatMessage.pending({String? id}) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: MessageStatus.pending,
    );
  }

  /// Create a copy with updated content (for streaming)
  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      status: status ?? this.status,
      isPrivate: isPrivate,
    );
  }

  /// Check if this is a user message
  bool get isUser => role == ChatRole.user;

  /// Check if this is an assistant message
  bool get isAssistant => role == ChatRole.assistant;

  /// Check if message is still loading
  bool get isPending => status == MessageStatus.pending;

  /// Check if message failed
  bool get isError => status == MessageStatus.error;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'isPrivate': isPrivate,
    };
  }

  /// Create from JSON for loading from storage
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
      isPrivate: json['isPrivate'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, role, content, timestamp, status, isPrivate];
}

/// Status of a message
enum MessageStatus {
  pending,
  sent,
  error,
}

/// Welcome message shown at chat start
class WelcomeMessage {
  static const String title = "Hi! I'm your Kind Banking assistant.";
  static const String subtitle = "I can help you with:";
  static const List<String> capabilities = [
    "Check your account balance",
    "Make transfers",
    "View recent transactions",
    "Manage your cards",
    "Pay bills",
  ];
  static const String privacyNote =
      "All conversations are processed on your device and stay completely private.";
}
