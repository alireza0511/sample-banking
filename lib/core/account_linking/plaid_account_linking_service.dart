import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:plaid_link_flutter/plaid_link_flutter.dart';

import 'account_linking_service.dart';

/// [AccountLinkingService] backed by Plaid Link.
/// The only file in the app that imports plaid_link_flutter.
class PlaidAccountLinkingService implements AccountLinkingService {
  @override
  String get serviceName => 'Plaid';

  @override
  Future<AccountLinkResult> link(String linkToken) async {
    final result = Completer<AccountLinkResult>();
    void complete(AccountLinkResult value) {
      if (!result.isCompleted) result.complete(value);
    }

    PlaidLinkSession? session;
    try {
      session = await createPlaidLinkSession(LinkTokenConfiguration(
        token: linkToken,
        onSuccess: (success) => complete(AccountLinkSuccess(success.publicToken)),
        onExit: (exit) {
          final error = exit.error;
          complete(AccountLinkCancelled(
            errorMessage: error == null
                ? null
                : (error.displayMessage ?? error.errorMessage),
          ));
        },
        onEvent: _logEvent,
      ));
      await session.open();
    } on PlaidLinkException catch (e) {
      session?.dispose();
      throw AccountLinkException(e.message);
    }
    return result.future;
  }

  void _logEvent(LinkEvent event) {
    if (!kDebugMode) return;
    final institution = event.metadata.institutionName;
    developer.log(
      '${event.eventName.value}${institution == null ? '' : ' ($institution)'}',
      name: 'PlaidLink',
    );
  }
}
