import 'package:flutter/material.dart';

import '../model/chat_message.dart';

/// Suggested question or action
class Suggestion {
  final String text;
  final String displayText;
  final IconData? icon;

  const Suggestion({
    required this.text,
    required this.displayText,
    this.icon,
  });
}

/// Service for generating context-aware suggestions
class SuggestionService {
  /// Get suggestions based on conversation context
  List<Suggestion> getSuggestions(List<ChatMessage> messages) {
    // If empty chat, show welcome suggestions
    if (messages.isEmpty) {
      return _welcomeSuggestions;
    }

    // Get last few messages for context
    final recentMessages = messages.length > 3 ? messages.sublist(messages.length - 3) : messages;

    // Analyze last assistant message for context
    final lastAssistantMessage = recentMessages.lastWhere(
      (m) => m.isAssistant && !m.isPending && !m.isError,
      orElse: () => ChatMessage.assistant(content: ''),
    );

    if (lastAssistantMessage.content.isEmpty) {
      return _defaultSuggestions;
    }

    final content = lastAssistantMessage.content.toLowerCase();

    // Balance mentioned → suggest transactions
    if (content.contains('balance') || content.contains('\$') || content.contains('account')) {
      return _afterBalanceSuggestions;
    }

    // Transactions mentioned → suggest filtering or transfers
    if (content.contains('transaction') || content.contains('payment')) {
      return _afterTransactionsSuggestions;
    }

    // Cards mentioned → suggest card management
    if (content.contains('card') || content.contains('debit') || content.contains('credit')) {
      return _afterCardsSuggestions;
    }

    // Transfer mentioned → suggest another transfer or bills
    if (content.contains('transfer') || content.contains('sent')) {
      return _afterTransferSuggestions;
    }

    return _defaultSuggestions;
  }

  // Welcome suggestions (empty chat)
  static const List<Suggestion> _welcomeSuggestions = [
    Suggestion(
      text: "What's my account balance?",
      displayText: "Check balance",
    ),
    Suggestion(
      text: "Show my recent transactions",
      displayText: "Recent transactions",
    ),
    Suggestion(
      text: "How do I transfer money?",
      displayText: "Transfer money",
    ),
  ];

  // Default suggestions
  static const List<Suggestion> _defaultSuggestions = [
    Suggestion(
      text: "What's my account balance?",
      displayText: "Check balance",
    ),
    Suggestion(
      text: "Show my recent transactions",
      displayText: "View transactions",
    ),
    Suggestion(
      text: "Show my cards",
      displayText: "My cards",
    ),
  ];

  // After balance inquiry
  static const List<Suggestion> _afterBalanceSuggestions = [
    Suggestion(
      text: "Show my recent transactions",
      displayText: "Recent transactions",
    ),
    Suggestion(
      text: "Transfer money to someone",
      displayText: "Transfer money",
    ),
    Suggestion(
      text: "Pay my bills",
      displayText: "Pay bills",
    ),
  ];

  // After transactions inquiry
  static const List<Suggestion> _afterTransactionsSuggestions = [
    Suggestion(
      text: "Show only this month's transactions",
      displayText: "Filter by month",
    ),
    Suggestion(
      text: "What's my biggest expense?",
      displayText: "Biggest expense",
    ),
    Suggestion(
      text: "Transfer money",
      displayText: "Transfer",
    ),
  ];

  // After cards inquiry
  static const List<Suggestion> _afterCardsSuggestions = [
    Suggestion(
      text: "Freeze my debit card",
      displayText: "Freeze card",
    ),
    Suggestion(
      text: "Show my card transactions",
      displayText: "Card transactions",
    ),
    Suggestion(
      text: "What's my credit limit?",
      displayText: "Credit limit",
    ),
  ];

  // After transfer
  static const List<Suggestion> _afterTransferSuggestions = [
    Suggestion(
      text: "Show my updated balance",
      displayText: "Updated balance",
    ),
    Suggestion(
      text: "Transfer to someone else",
      displayText: "Another transfer",
    ),
    Suggestion(
      text: "Pay bills",
      displayText: "Pay bills",
    ),
  ];
}
