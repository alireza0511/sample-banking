import 'package:clean_framework/clean_framework.dart';

import '../../core/locator.dart';
import '../../core/network/api_client.dart';
import '../model/account.dart';
import 'balance_entity.dart';
import 'balance_view_model.dart';

/// Use case for managing balance screen state
class BalanceUseCase extends UseCase {
  final ViewModelCallback<BalanceViewModel> _viewModelCallback;
  final ApiClient _apiClient;

  BalanceEntity _entity = BalanceEntity();

  BalanceUseCase(
    this._viewModelCallback, {
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? AppLocator.apiClient;

  /// Load accounts from API
  Future<void> loadAccounts() async {
    // Set loading state
    _entity = _entity.merge(isLoading: true, errorMessage: null);
    _notifyListeners();

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'api/v1/accounts',
      );

      response.fold(
        onSuccess: (data) {
          final accountsResponse =
              AccountsResponse.fromJson({'data': data['data']});
          _entity = _entity.merge(
            accounts: accountsResponse.accounts,
            totalBalance: accountsResponse.totalBalance,
            netWealth: accountsResponse.netWealth,
            isLoading: false,
          );
          _notifyListeners();
        },
        onError: (error, type) {
          _entity = _entity.merge(
            isLoading: false,
            errorMessage: error,
          );
          _notifyListeners();
        },
      );
    } catch (e) {
      _entity = _entity.merge(
        isLoading: false,
        errorMessage: 'Failed to load accounts: $e',
      );
      _notifyListeners();
    }
  }

  /// Toggle balance visibility
  void toggleBalanceVisibility() {
    _entity = _entity.merge(isBalanceHidden: !_entity.isBalanceHidden);
    _notifyListeners();
  }

  /// Select an account
  void selectAccount(String accountId) {
    _entity = _entity.merge(selectedAccountId: accountId);
    _notifyListeners();
  }

  /// Refresh accounts
  Future<void> refresh() => loadAccounts();

  void _notifyListeners() {
    _viewModelCallback(BalanceViewModel.fromEntity(_entity));
  }
}
