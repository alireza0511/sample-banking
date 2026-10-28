import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_link_flutter/plaid_link_flutter.dart';
import 'package:plaid_link_flutter/plaid_link_flutter_platform_interface.dart';
import 'package:sample_banking/core/account_linking/account_linking_service.dart';
import 'package:sample_banking/core/account_linking/plaid_account_linking_service.dart';

/// Stands in for the native plugin; open() replays [onOpen].
class FakePlaidPlatform extends PlaidLinkFlutterPlatform {
  final success = StreamController<LinkSuccess>.broadcast();
  final exit = StreamController<LinkExit>.broadcast();
  final events = StreamController<LinkEvent>.broadcast();
  void Function() onOpen = () {};
  Object? createError;

  @override
  Stream<LinkSuccess> onSuccessForSession(int sessionId) => success.stream;
  @override
  Stream<LinkExit> onExitForSession(int sessionId) => exit.stream;
  @override
  Stream<LinkEvent> onEventForSession(int sessionId) => events.stream;

  @override
  Future<void> createPlaidLinkSession(String token, int sessionId) async {
    if (createError != null) throw createError!;
  }

  @override
  Future<void> openLinkSession(bool fullScreen) async => onOpen();
}

const _exitMetadata = LinkExitMetadata(linkSessionId: 's', requestId: 'r');

void main() {
  late FakePlaidPlatform platform;
  final service = PlaidAccountLinkingService();

  setUp(() {
    platform = FakePlaidPlatform();
    PlaidLinkFlutterPlatform.instance = platform;
  });

  test('onSuccess maps to AccountLinkSuccess', () async {
    platform.onOpen = () => platform.success.add(const LinkSuccess(
          publicToken: 'public-sandbox-abc',
          metadata: LinkSuccessMetadata(accounts: [], linkSessionId: 's'),
        ));

    final result = await service.link('link-token');

    expect((result as AccountLinkSuccess).publicToken, 'public-sandbox-abc');
  });

  test('onExit without error maps to a plain cancel', () async {
    platform.onOpen =
        () => platform.exit.add(const LinkExit(metadata: _exitMetadata));

    final result = await service.link('link-token');

    expect((result as AccountLinkCancelled).errorMessage, isNull);
  });

  test('onExit with error prefers the display message', () async {
    platform.onOpen = () => platform.exit.add(const LinkExit(
          metadata: _exitMetadata,
          error: LinkError(
            errorCode: 'INSTITUTION_DOWN',
            errorType: LinkErrorType('INSTITUTION_ERROR'),
            errorMessage: 'raw',
            displayMessage: 'Bank is down',
          ),
        ));

    final result = await service.link('link-token');

    expect((result as AccountLinkCancelled).errorMessage, 'Bank is down');
  });

  test('PlaidLinkException becomes AccountLinkException', () async {
    platform.createError = PlaidLinkException.fromPlatformException(
      PlatformException(code: 'INVALID_TOKEN', message: 'Bad token'),
    );

    expect(
      () => service.link('link-token'),
      throwsA(isA<AccountLinkException>()
          .having((e) => e.message, 'message', 'Bad token')),
    );
  });
}
