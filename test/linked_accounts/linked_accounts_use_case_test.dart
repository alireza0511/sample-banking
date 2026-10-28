import 'dart:convert';

import 'package:clean_framework/clean_framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample_banking/core/account_linking/account_linking_service.dart';
import 'package:sample_banking/core/network/api_client.dart';
import 'package:sample_banking/linked_accounts/bloc/linked_accounts_use_case.dart';
import 'package:sample_banking/linked_accounts/bloc/linked_accounts_view_model.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeLinkingService implements AccountLinkingService {
  final Future<AccountLinkResult> Function() onLink;
  String? linkedWith;

  FakeLinkingService(this.onLink);

  @override
  String get serviceName => 'Fake';

  @override
  Future<AccountLinkResult> link(String linkToken) {
    linkedWith = linkToken;
    return onLink();
  }
}

const _accountsJson = {
  'accounts': [
    {
      'id': 'acc-1',
      'institution': 'First Platypus Bank',
      'name': 'Plaid Checking',
      'mask': '0000',
      'type': 'checking',
      'balance': 110.0,
      'currency': 'USD',
    },
  ],
};

void main() {
  late MockApiClient api;
  late List<LinkedAccountsViewModel> states;

  void stub(String path, RestResponseType type, Object body) {
    when(() => api.request(
          method: any(named: 'method'),
          path: path,
          requestBody: any(named: 'requestBody'),
        )).thenAnswer((_) async => RestResponse<String>(
          type: type,
          uri: Uri.parse('http://localhost/$path'),
          content: jsonEncode(body),
        ));
  }

  LinkedAccountsUseCase useCase(AccountLinkingService linkingService) {
    return LinkedAccountsUseCase(
      (viewModel) {
        states.add(viewModel);
        return true;
      },
      apiClient: api,
      linkingService: linkingService,
    );
  }

  setUpAll(() => registerFallbackValue(RestMethod.get));

  setUp(() {
    api = MockApiClient();
    states = [];
    stub('api/v1/plaid/link-token', RestResponseType.success,
        {'link_token': 'link-sandbox-123'});
    stub('api/v1/plaid/exchange', RestResponseType.success, _accountsJson);
  });

  test('success exchanges the public token and shows accounts', () async {
    final linking = FakeLinkingService(
        () async => const AccountLinkSuccess('public-sandbox-abc'));

    await useCase(linking).linkAccount();

    expect(linking.linkedWith, 'link-sandbox-123');
    verify(() => api.request(
          method: RestMethod.post,
          path: 'api/v1/plaid/exchange',
          requestBody: {'public_token': 'public-sandbox-abc'},
        )).called(1);
    expect(states.last.isLinking, isFalse);
    expect(states.last.accounts.single.mask, '0000');
  });

  test('cancel without an error is not shown as an error', () async {
    await useCase(FakeLinkingService(() async => const AccountLinkCancelled()))
        .linkAccount();

    expect(states.last.isLinking, isFalse);
    expect(states.last.hasError, isFalse);
  });

  test('cancel with an error shows it', () async {
    await useCase(FakeLinkingService(
      () async => const AccountLinkCancelled(errorMessage: 'Bank is down'),
    )).linkAccount();

    expect(states.last.errorMessage, 'Bank is down');
  });

  test('missing server keys surface the server message', () async {
    stub('api/v1/plaid/link-token', RestResponseType.unknown,
        {'message': 'Plaid keys not set.'});
    final linking =
        FakeLinkingService(() async => const AccountLinkCancelled());

    await useCase(linking).linkAccount();

    expect(linking.linkedWith, isNull);
    expect(states.last.errorMessage, 'Plaid keys not set.');
  });

  test('a provider that cannot open is shown as an error', () async {
    await useCase(FakeLinkingService(
      () async => throw const AccountLinkException('Link failed'),
    )).linkAccount();

    expect(states.last.errorMessage, 'Link failed');
    expect(states.last.isLinking, isFalse);
  });
}
