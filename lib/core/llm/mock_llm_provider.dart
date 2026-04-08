import 'dart:async';
import 'dart:math';

import 'llm_provider.dart';
import 'llm_service.dart';

/// Mock LLM provider for testing and demo purposes
/// Provides canned responses with simulated typing delay
class MockLlmProvider extends LlmProvider {
  final Random _random = Random();

  /// Simulated typing delay per character (ms)
  final int typingDelayMs;

  /// Whether to simulate occasional errors
  final bool simulateErrors;

  MockLlmProvider({
    super.maxContextMessages = 10,
    super.timeout = const Duration(seconds: 30),
    this.typingDelayMs = 30,
    this.simulateErrors = false,
  });

  @override
  LlmProviderInfo get providerInfo => const LlmProviderInfo(
        name: 'Demo AI',
        type: LlmProviderType.mock,
        isPrivate: true,
        modelName: 'Mock Model (Demo)',
      );

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> doInitialize() async {
    // Simulate model loading delay
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<LlmResponse> doGenerateResponse(LlmRequest request) async {
    if (simulateErrors && _random.nextDouble() < 0.1) {
      throw const LlmError(
        message: 'Simulated error for testing',
        type: LlmErrorType.unknown,
      );
    }

    final response = _generateMockResponse(request.prompt);

    // Simulate processing delay
    await Future.delayed(Duration(milliseconds: response.length * 2));

    return LlmResponse(
      content: response,
      providerInfo: providerInfo,
      tokensUsed: response.split(' ').length,
    );
  }

  @override
  Stream<String> doStreamResponse(LlmRequest request) async* {
    if (simulateErrors && _random.nextDouble() < 0.1) {
      throw const LlmError(
        message: 'Simulated streaming error',
        type: LlmErrorType.unknown,
      );
    }

    final response = _generateMockResponse(request.prompt);
    final words = response.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final suffix = i < words.length - 1 ? ' ' : '';
      yield word + suffix;
      await Future.delayed(Duration(milliseconds: typingDelayMs + _random.nextInt(20)));
    }
  }

  @override
  void doDispose() {
    // Nothing to dispose for mock provider
  }

  /// Generate a mock response based on the prompt
  String _generateMockResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    // Balance-related queries
    if (_containsAny(lowerPrompt, ['balance', 'how much', 'money', 'account'])) {
      return _getRandomResponse(_balanceResponses);
    }

    // Transfer-related queries
    if (_containsAny(lowerPrompt, ['transfer', 'send', 'pay', 'payment'])) {
      return _getRandomResponse(_transferResponses);
    }

    // Transaction-related queries
    if (_containsAny(lowerPrompt, ['transaction', 'history', 'spent', 'recent'])) {
      return _getRandomResponse(_transactionResponses);
    }

    // Card-related queries
    if (_containsAny(lowerPrompt, ['card', 'freeze', 'lock', 'credit'])) {
      return _getRandomResponse(_cardResponses);
    }

    // Bill-related queries
    if (_containsAny(lowerPrompt, ['bill', 'utility', 'due'])) {
      return _getRandomResponse(_billResponses);
    }

    // Help/greeting queries
    if (_containsAny(lowerPrompt, ['help', 'what can', 'hello', 'hi', 'hey'])) {
      return _getRandomResponse(_helpResponses);
    }

    // General banking questions
    if (_containsAny(lowerPrompt, ['savings', 'interest', 'rate', 'loan'])) {
      return _getRandomResponse(_bankingResponses);
    }

    // Default response
    return _getRandomResponse(_defaultResponses);
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String _getRandomResponse(List<String> responses) {
    return responses[_random.nextInt(responses.length)];
  }

  // Response templates
  static const _balanceResponses = [
    "Your checking account balance is \$12,450.00 and your savings account has \$25,000.00. Your total available balance across all accounts is \$37,450.00. Would you like me to show you recent transactions?",
    "I can see you have two accounts. Your Primary Checking shows \$12,450.00 available, and your Emergency Fund savings has \$25,000.00. Is there anything specific you'd like to do with these accounts?",
    "Your current balance is \$12,450.00 in checking. You also have \$25,000.00 in savings. Your net wealth across all accounts is \$37,450.00.",
  ];

  static const _transferResponses = [
    "I can help you transfer money. To get started, I'll need to know: 1) Which account to transfer from, 2) Who you'd like to send money to, and 3) The amount. Would you like me to open the transfer screen for you?",
    "Sure! I can help with that transfer. Your saved payees include John Smith, ABC Electric, and City Water. Who would you like to send money to, and how much?",
    "To make a transfer, you can use the Transfer screen. I can take you there now, or if you tell me the recipient and amount, I can pre-fill the form for you.",
  ];

  static const _transactionResponses = [
    "Looking at your recent transactions: You spent \$156.78 at Whole Foods yesterday, \$45.00 on Netflix subscription, and received a \$3,500.00 direct deposit last Friday. Would you like to see more details?",
    "Your last 5 transactions include: Coffee Shop (\$5.50), Gas Station (\$42.00), Amazon (\$89.99), Grocery Store (\$156.78), and a transfer to savings (\$500.00). Want me to filter by category?",
    "This month you've spent \$1,234.56 across 23 transactions. Your biggest categories are Groceries (\$450), Dining (\$280), and Transportation (\$180). Would you like a detailed breakdown?",
  ];

  static const _cardResponses = [
    "You have two cards on file: a Visa ending in 4582 (active) and a Mastercard ending in 7891 (active). Would you like to freeze a card, view details, or report an issue?",
    "I can help you manage your cards. You can freeze/unfreeze cards, view card numbers securely, or set spending limits. Which card would you like to manage?",
    "Your debit card ending in 4582 is currently active. If you need to freeze it for security, I can do that immediately. Just let me know.",
  ];

  static const _billResponses = [
    "You have 3 bills coming up: Electric bill (\$124.50, due in 5 days), Internet (\$79.99, due in 8 days), and Water (\$45.00, due in 12 days). Would you like to pay any of these now?",
    "I can help you pay bills. Your saved billers include ABC Electric, Comcast Internet, and City Water. Which bill would you like to pay?",
    "Looking at your bills: You have \$249.49 in upcoming bills this month. All bills are set up for manual payment. Would you like to schedule any payments?",
  ];

  static const _helpResponses = [
    "Hi! I'm your Kind Banking assistant. I can help you with:\n\n• Checking your account balance\n• Making transfers\n• Viewing transactions\n• Managing cards\n• Paying bills\n\nAll conversations stay private on your device. What would you like to do?",
    "Hello! I'm here to help with your banking needs. I can check balances, help with transfers, show transactions, manage cards, and pay bills. Your data stays private - I run completely on your device. How can I assist you today?",
    "Welcome to Kind Banking! I'm your AI assistant, running privately on your device. I can help you navigate your accounts, make payments, and answer questions about your finances. What would you like to know?",
  ];

  static const _bankingResponses = [
    "Your savings account currently earns 4.5% APY on balances over \$1,000. With your current balance of \$25,000, you're earning approximately \$93.75 per month in interest.",
    "Based on your account activity, I'd recommend keeping at least 3 months of expenses in your Emergency Fund. Your current savings cover about 4 months - great job!",
    "Interest rates for savings accounts at Kind Banking range from 3.5% to 4.5% APY depending on your balance tier. Would you like more details about our savings options?",
  ];

  static const _defaultResponses = [
    "I understand you're asking about something specific. As your banking assistant, I can help with account balances, transfers, transactions, cards, and bill payments. Could you tell me more about what you'd like to do?",
    "I'm here to help with your banking needs. I can assist with checking balances, making transfers, viewing transaction history, managing cards, or paying bills. What would you like help with?",
    "Thanks for your question! While I'm focused on banking tasks, I'll do my best to help. I can manage accounts, transfers, transactions, cards, and bills. Is there something specific I can help you with?",
  ];
}
