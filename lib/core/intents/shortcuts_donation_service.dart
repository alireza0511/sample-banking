import 'package:flutter/foundation.dart';
import 'package:flutter_app_intents/flutter_app_intents.dart';
import 'banking_intents.dart';

/// Service for donating user actions to Siri Suggestions and Spotlight
/// Helps iOS learn user patterns and suggest banking actions proactively
class ShortcutsDonationService {
  final FlutterAppIntentsClient _client;

  ShortcutsDonationService({FlutterAppIntentsClient? client})
      : _client = client ?? FlutterAppIntentsClient.instance;

  /// Donate "Show Balance" action to Siri
  /// Call this when user views their balance
  Future<void> donateShowBalance() async {
    try {
      await _client.donateIntent(
        BankingIntents.showBalanceId,
        {},
      );
      debugPrint('ShortcutsDonation: Donated ShowBalanceIntent');
    } catch (e) {
      debugPrint('ShortcutsDonation: Failed to donate ShowBalanceIntent: $e');
    }
  }

  /// Donate "Transfer Money" action to Siri
  /// Call this when user completes a successful transfer
  Future<void> donateTransfer({
    String? recipient,
    double? amount,
  }) async {
    try {
      final parameters = <String, dynamic>{};
      if (recipient != null) {
        parameters['recipient'] = recipient;
      }
      if (amount != null) {
        parameters['amount'] = amount;
      }

      await _client.donateIntent(
        BankingIntents.transferId,
        parameters,
      );
      debugPrint('ShortcutsDonation: Donated TransferIntent');
    } catch (e) {
      debugPrint('ShortcutsDonation: Failed to donate TransferIntent: $e');
    }
  }

  /// Donate "Pay Bills" action to Siri
  /// Call this when user completes a bill payment
  Future<void> donatePayBills({
    String? billerId,
    double? amount,
  }) async {
    try {
      final parameters = <String, dynamic>{};
      if (billerId != null) {
        parameters['billerId'] = billerId;
      }
      if (amount != null) {
        parameters['amount'] = amount;
      }

      await _client.donateIntent(
        BankingIntents.payBillsId,
        parameters,
      );
      debugPrint('ShortcutsDonation: Donated PayBillsIntent');
    } catch (e) {
      debugPrint('ShortcutsDonation: Failed to donate PayBillsIntent: $e');
    }
  }

  /// Donate "Show Cards" action to Siri
  /// Call this when user views their cards
  Future<void> donateShowCards() async {
    try {
      await _client.donateIntent(
        BankingIntents.showCardsId,
        {},
      );
      debugPrint('ShortcutsDonation: Donated ShowCardsIntent');
    } catch (e) {
      debugPrint('ShortcutsDonation: Failed to donate ShowCardsIntent: $e');
    }
  }

  /// Donate "Open Chat" action to Siri
  /// Call this when user opens the chat interface
  Future<void> donateOpenChat({String? prompt}) async {
    try {
      final parameters = <String, dynamic>{};
      if (prompt != null) {
        parameters['prompt'] = prompt;
      }

      await _client.donateIntent(
        BankingIntents.openChatId,
        parameters,
      );
      debugPrint('ShortcutsDonation: Donated OpenChatIntent');
    } catch (e) {
      debugPrint('ShortcutsDonation: Failed to donate OpenChatIntent: $e');
    }
  }

  /// Index all banking actions in Spotlight search
  /// Call this after user logs in to make actions searchable
  Future<void> indexAllActions() async {
    try {
      // Donate all core banking actions for Spotlight indexing
      await Future.wait([
        donateShowBalance(),
        donateTransfer(),
        donatePayBills(),
        donateShowCards(),
        donateOpenChat(),
      ]);
      debugPrint('ShortcutsDonation: Indexed all actions in Spotlight');
    } catch (e) {
      debugPrint('ShortcutsDonation: Failed to index actions: $e');
    }
  }

  /// Delete all donated shortcuts
  /// Call this when user logs out
  Future<void> deleteAllDonations() async {
    try {
      // Note: flutter_app_intents may not have a deleteAllDonatedIntents method
      // This is a placeholder for future implementation
      debugPrint('ShortcutsDonation: Delete all donations not yet implemented');
    } catch (e) {
      debugPrint('ShortcutsDonation: Failed to delete donations: $e');
    }
  }
}
