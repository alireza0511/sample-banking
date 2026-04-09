import 'package:flutter_app_intents/flutter_app_intents.dart';

/// Banking intent identifiers and builders
/// These define the voice commands available via Siri
class BankingIntents {
  BankingIntents._();

  // Intent identifiers
  static const String showBalanceId = 'com.kindbanking.app.ShowBalance';
  static const String transferId = 'com.kindbanking.app.Transfer';
  static const String payBillsId = 'com.kindbanking.app.PayBills';
  static const String showCardsId = 'com.kindbanking.app.ShowCards';
  static const String openChatId = 'com.kindbanking.app.OpenChat';

  /// Build "Show Balance" intent
  /// "Hey Siri, show my balance in BankApp"
  static AppIntent buildShowBalanceIntent() {
    return AppIntentBuilder()
        .identifier(showBalanceId)
        .title('Show Balance')
        .description('View your account balance')
        .build();
  }

  /// Build "Transfer Money" intent with optional parameters
  /// "Hey Siri, transfer money in BankApp"
  /// "Hey Siri, transfer \$50 to John in BankApp"
  static AppIntent buildTransferIntent() {
    return AppIntentBuilder()
        .identifier(transferId)
        .title('Transfer Money')
        .description('Transfer money to someone')
        .parameter(
          const AppIntentParameter(
            name: 'recipient',
            title: 'Recipient',
            type: AppIntentParameterType.string,
            isOptional: true,
          ),
        )
        .parameter(
          const AppIntentParameter(
            name: 'amount',
            title: 'Amount',
            type: AppIntentParameterType.double,
            isOptional: true,
          ),
        )
        .build();
  }

  /// Build "Pay Bills" intent with optional parameters
  /// "Hey Siri, pay bills in BankApp"
  static AppIntent buildPayBillsIntent() {
    return AppIntentBuilder()
        .identifier(payBillsId)
        .title('Pay Bills')
        .description('Pay your bills')
        .parameter(
          const AppIntentParameter(
            name: 'billerId',
            title: 'Biller',
            type: AppIntentParameterType.string,
            isOptional: true,
          ),
        )
        .parameter(
          const AppIntentParameter(
            name: 'amount',
            title: 'Amount',
            type: AppIntentParameterType.double,
            isOptional: true,
          ),
        )
        .build();
  }

  /// Build "Show Cards" intent
  /// "Hey Siri, show my cards in BankApp"
  static AppIntent buildShowCardsIntent() {
    return AppIntentBuilder()
        .identifier(showCardsId)
        .title('Show Cards')
        .description('View your credit and debit cards')
        .build();
  }

  /// Build "Open Chat" intent with optional prompt
  /// "Hey Siri, ask BankApp a question"
  static AppIntent buildOpenChatIntent() {
    return AppIntentBuilder()
        .identifier(openChatId)
        .title('Ask a Question')
        .description('Ask Kind Banking a question')
        .parameter(
          const AppIntentParameter(
            name: 'prompt',
            title: 'Question',
            type: AppIntentParameterType.string,
            isOptional: true,
          ),
        )
        .build();
  }
}
