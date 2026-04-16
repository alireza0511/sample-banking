import 'dart:developer' as developer;

import 'package:clean_framework/clean_framework.dart';

import '../../core/locator.dart';
import '../../core/network/api_client.dart';
import '../model/account.dart';
import 'balance_entity.dart';
import 'balance_view_model.dart';

void _log(String message) {
  developer.log(message, name: 'BalanceUseCase');
  // ignore: avoid_print
  print('[BalanceUseCase] $message');
}

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
    _log('loadAccounts() called');
    // Set loading state
    _entity = _entity.merge(isLoading: true, errorMessage: null);
    _notifyListeners();

    try {
      _log('Calling API: api/v1/accounts');
      final response = await _apiClient.get<Map<String, dynamic>>(
        'api/v1/accounts',
      );

      _log('API response received: isSuccess=${response.isSuccess}');

      response.fold(
        onSuccess: (data) {
          _log('Success! Data keys: ${data.keys.toList()}');
          _log('Data[data] type: ${data['data']?.runtimeType}');
          final accountsResponse =
              AccountsResponse.fromJson({'data': data['data']});
          _log('Parsed ${accountsResponse.accounts.length} accounts');
          _entity = _entity.merge(
            accounts: accountsResponse.accounts,
            totalBalance: accountsResponse.totalBalance,
            netWealth: accountsResponse.netWealth,
            isLoading: false,
          );
          _notifyListeners();
        },
        onError: (error, type) {
          _log('Error: $error, type: $type');
          _entity = _entity.merge(
            isLoading: false,
            errorMessage: error,
          );
          _notifyListeners();
        },
      );
    } catch (e, stackTrace) {
      _log('Exception: $e');
      _log('Stack: $stackTrace');
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
