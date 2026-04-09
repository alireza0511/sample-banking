import 'package:flutter/foundation.dart';
import 'package:flutter_app_intents/flutter_app_intents.dart';
import '../routing/deep_link_service.dart';
import 'banking_intents.dart';

/// Service that integrates voice intents with the deep link system
/// Translates Siri voice commands into deep link URIs and triggers navigation
class IntentService {
  final DeepLinkService _deepLinkService;
  final FlutterAppIntentsClient _client;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  IntentService({
    required DeepLinkService deepLinkService,
    FlutterAppIntentsClient? client,
  })  : _deepLinkService = deepLinkService,
        _client = client ?? FlutterAppIntentsClient.instance;

  /// Initialize the intent service and register all intent handlers
  Future<void> init() async {
    if (_initialized) {
      debugPrint('IntentService: Already initialized');
      return;
    }

    try {
      debugPrint('IntentService: Initializing...');

      // Register all banking intent handlers
      await _registerShowBalanceIntent();
      await _registerTransferIntent();
      await _registerPayBillsIntent();
      await _registerShowCardsIntent();
      await _registerOpenChatIntent();

      _initialized = true;
      debugPrint('IntentService: Initialized successfully');
    } catch (e) {
      debugPrint('IntentService: Initialization error: $e');
    }
  }

  /// Register handler for "Show my balance" intent
  Future<void> _registerShowBalanceIntent() async {
    try {
      final intent = BankingIntents.buildShowBalanceIntent();

      await _client.registerIntent(intent, (parameters) async {
        debugPrint('=== INTENT: ShowBalance triggered ===');
        final uri = Uri.parse('kindbanking://balance');
        debugPrint('INTENT: Built URI: $uri');
        _deepLinkService.handleUri(uri);
        debugPrint('INTENT: Triggered deep link');

        return AppIntentResult.successful(
          value: 'Opening balance screen',
          needsToContinueInApp: true,
        );
      });

      debugPrint('IntentService: Registered ShowBalanceIntent');
    } catch (e) {
      debugPrint('IntentService: Failed to register ShowBalanceIntent: $e');
    }
  }

  /// Register handler for "Transfer money" intent
  /// Supports optional recipient and amount parameters
  Future<void> _registerTransferIntent() async {
    try {
      final intent = BankingIntents.buildTransferIntent();

      await _client.registerIntent(intent, (parameters) async {
        debugPrint('=== INTENT: Transfer triggered ===');
        debugPrint('INTENT: Parameters: $parameters');

        // Extract parameters
        final recipient = parameters['recipient'] as String?;
        final amount = parameters['amount'] as double?;

        // Build query parameters
        final queryParams = <String, String>{};
        if (recipient != null && recipient.isNotEmpty) {
          queryParams['to'] = recipient;
        }
        if (amount != null) {
          queryParams['amount'] = amount.toStringAsFixed(2);
        }

        // Build URI with parameters
        final uri = Uri(
          scheme: 'kindbanking',
          host: 'transfer',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        debugPrint('INTENT: Built URI: $uri');
        _deepLinkService.handleUri(uri);
        debugPrint('INTENT: Triggered deep link');

        return AppIntentResult.successful(
          value: 'Opening transfer screen',
          needsToContinueInApp: true,
        );
      });

      debugPrint('IntentService: Registered TransferIntent');
    } catch (e) {
      debugPrint('IntentService: Failed to register TransferIntent: $e');
    }
  }

  /// Register handler for "Pay bills" intent
  /// Supports optional billerId and amount parameters
  Future<void> _registerPayBillsIntent() async {
    try {
      final intent = BankingIntents.buildPayBillsIntent();

      await _client.registerIntent(intent, (parameters) async {
        debugPrint('=== INTENT: PayBills triggered ===');
        debugPrint('INTENT: Parameters: $parameters');

        // Extract parameters
        final billerId = parameters['billerId'] as String?;
        final amount = parameters['amount'] as double?;

        // Build query parameters
        final queryParams = <String, String>{};
        if (billerId != null && billerId.isNotEmpty) {
          queryParams['billerId'] = billerId;
        }
        if (amount != null) {
          queryParams['amount'] = amount.toStringAsFixed(2);
        }

        // Build URI with parameters
        final uri = Uri(
          scheme: 'kindbanking',
          host: 'pay-bills',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        debugPrint('INTENT: Built URI: $uri');
        _deepLinkService.handleUri(uri);
        debugPrint('INTENT: Triggered deep link');

        return AppIntentResult.successful(
          value: 'Opening bill payment screen',
          needsToContinueInApp: true,
        );
      });

      debugPrint('IntentService: Registered PayBillsIntent');
    } catch (e) {
      debugPrint('IntentService: Failed to register PayBillsIntent: $e');
    }
  }

  /// Register handler for "Show my cards" intent
  Future<void> _registerShowCardsIntent() async {
    try {
      final intent = BankingIntents.buildShowCardsIntent();

      await _client.registerIntent(intent, (parameters) async {
        debugPrint('=== INTENT: ShowCards triggered ===');
        final uri = Uri.parse('kindbanking://cards');
        debugPrint('INTENT: Built URI: $uri');
        _deepLinkService.handleUri(uri);
        debugPrint('INTENT: Triggered deep link');

        return AppIntentResult.successful(
          value: 'Opening cards screen',
          needsToContinueInApp: true,
        );
      });

      debugPrint('IntentService: Registered ShowCardsIntent');
    } catch (e) {
      debugPrint('IntentService: Failed to register ShowCardsIntent: $e');
    }
  }

  /// Register handler for "Ask a question" intent
  /// Supports optional prompt parameter
  Future<void> _registerOpenChatIntent() async {
    try {
      final intent = BankingIntents.buildOpenChatIntent();

      await _client.registerIntent(intent, (parameters) async {
        debugPrint('=== INTENT: OpenChat triggered ===');
        debugPrint('INTENT: Parameters: $parameters');

        // Extract parameters
        final prompt = parameters['prompt'] as String?;

        // Build query parameters
        final queryParams = <String, String>{};
        if (prompt != null && prompt.isNotEmpty) {
          queryParams['prompt'] = prompt;
        }

        // Build URI with parameters
        final uri = Uri(
          scheme: 'kindbanking',
          host: 'chat',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        debugPrint('INTENT: Built URI: $uri');
        _deepLinkService.handleUri(uri);
        debugPrint('INTENT: Triggered deep link');

        return AppIntentResult.successful(
          value: 'Opening chat assistant',
          needsToContinueInApp: true,
        );
      });

      debugPrint('IntentService: Registered OpenChatIntent');
    } catch (e) {
      debugPrint('IntentService: Failed to register OpenChatIntent: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('IntentService: Disposing');
  }
}
