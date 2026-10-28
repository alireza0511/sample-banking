import 'package:clean_framework/clean_framework.dart';

import '../../core/account_linking/account_linking.dart';
import '../../core/config/app_config.dart';
import '../../core/locator.dart';
import '../../core/network/api_client.dart';
import '../model/linked_account.dart';
import 'linked_accounts_entity.dart';
import 'linked_accounts_view_model.dart';

/// Use case for linking external bank accounts
class LinkedAccountsUseCase extends UseCase {
  final ViewModelCallback<LinkedAccountsViewModel> _viewModelCallback;
  final ApiClient _apiClient;
  final AccountLinkingService _linkingService;

  LinkedAccountsEntity _entity = LinkedAccountsEntity();

  LinkedAccountsUseCase(
    this._viewModelCallback, {
    ApiClient? apiClient,
    AccountLinkingService? linkingService,
  })  : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.plaidServerUrl),
        _linkingService = linkingService ?? AppLocator.accountLinkingService;

  /// Load accounts already linked on the token server
  Future<void> loadAccounts() async {
    _entity = _entity.merge(isLoading: true);
    _notifyListeners();

    final response =
        await _apiClient.get<Map<String, dynamic>>('api/v1/plaid/accounts');
    _applyAccounts(response);
  }

  /// Fetch a link token, open the provider's UI, then exchange the result
  Future<void> linkAccount() async {
    if (_entity.isLinking) return;
    _entity = _entity.merge(isLinking: true);
    _notifyListeners();

    final response =
        await _apiClient.post<Map<String, dynamic>>('api/v1/plaid/link-token');
    final linkToken = response.data?['link_token'] as String?;
    if (linkToken == null) {
      _fail(response.errorMessage ?? 'No link token returned');
      return;
    }

    final AccountLinkResult result;
    try {
      result = await _linkingService.link(linkToken);
    } on AccountLinkException catch (e) {
      _fail(e.message);
      return;
    }

    switch (result) {
      case AccountLinkSuccess(:final publicToken):
        // publicToken goes straight to the server; it is never stored here.
        _applyAccounts(await _apiClient.post<Map<String, dynamic>>(
          'api/v1/plaid/exchange',
          body: {'public_token': publicToken},
        ));
      case AccountLinkCancelled(:final errorMessage):
        _entity = _entity.merge(isLinking: false, errorMessage: errorMessage);
        _notifyListeners();
    }
  }

  Future<void> refresh() => loadAccounts();

  void _applyAccounts(ApiResponse<Map<String, dynamic>> response) {
    response.fold(
      onSuccess: (data) {
        _entity = _entity.merge(
          accounts: LinkedAccount.listFromJson(data),
          isLoading: false,
          isLinking: false,
        );
        _notifyListeners();
      },
      onError: (error, _) => _fail(error),
    );
  }

  void _fail(String message) {
    _entity = _entity.merge(
      isLoading: false,
      isLinking: false,
      errorMessage: message,
    );
    _notifyListeners();
  }

  void _notifyListeners() {
    _viewModelCallback(LinkedAccountsViewModel.fromEntity(_entity));
  }
}
