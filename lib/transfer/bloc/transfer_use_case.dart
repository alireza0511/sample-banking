import 'package:clean_framework/clean_framework.dart';

import '../../balance/model/account.dart';
import '../../core/locator.dart';
import '../../core/network/api_client.dart';
import '../model/payee.dart';
import 'transfer_entity.dart';
import 'transfer_view_model.dart';

/// Use case for managing transfer flow
class TransferUseCase extends UseCase {
  final ViewModelCallback<TransferViewModel> _viewModelCallback;
  final ApiClient _apiClient;

  TransferEntity _entity = TransferEntity();

  TransferUseCase(
    this._viewModelCallback, {
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? AppLocator.apiClient;

  /// Initialize with pre-filled data from deep link
  void initialize({String? recipientId, double? amount}) {
    if (amount != null) {
      _entity = _entity.merge(amount: amount);
    }
    // If recipientId provided, we'll select it after payees load
    loadData(preSelectedPayeeId: recipientId);
  }

  /// Load payees and accounts
  Future<void> loadData({String? preSelectedPayeeId}) async {
    _entity = _entity.merge(isLoading: true, errorMessage: null);
    _notifyListeners();

    try {
      // Load payees and accounts in parallel
      final payeesResponse =
          await _apiClient.get<Map<String, dynamic>>('api/v1/payees');
      final accountsResponse =
          await _apiClient.get<Map<String, dynamic>>('api/v1/accounts');

      List<Payee> payees = [];
      List<Account> accounts = [];
      Payee? preSelectedPayee;

      payeesResponse.fold(
        onSuccess: (data) {
          final payeeList = (data['data']['payees'] as List)
              .map((e) => Payee.fromJson(e as Map<String, dynamic>))
              .toList();
          payees = payeeList;

          // Find pre-selected payee if ID provided
          if (preSelectedPayeeId != null) {
            preSelectedPayee = payees.firstWhere(
              (p) =>
                  p.id == preSelectedPayeeId ||
                  p.identifier == preSelectedPayeeId,
              orElse: () => payees.first,
            );
          }
        },
        onError: (error, type) {
          _entity = _entity.merge(isLoading: false, errorMessage: error);
          _notifyListeners();
          return;
        },
      );

      accountsResponse.fold(
        onSuccess: (data) {
          final accountList = (data['data']['accounts'] as List)
              .map((e) => Account.fromJson(e as Map<String, dynamic>))
              .toList();
          accounts = accountList;
        },
        onError: (error, type) {
          _entity = _entity.merge(isLoading: false, errorMessage: error);
          _notifyListeners();
          return;
        },
      );

      // Select default account (primary or first)
      final defaultAccount = accounts.isNotEmpty
          ? accounts.firstWhere((a) => a.isPrimary, orElse: () => accounts.first)
          : null;

      _entity = _entity.merge(
        payees: payees,
        accounts: accounts,
        selectedAccount: defaultAccount,
        selectedPayee: preSelectedPayee,
        isLoading: false,
        step: preSelectedPayee != null
            ? TransferStep.enterAmount
            : TransferStep.selectPayee,
      );
      _notifyListeners();
    } catch (e) {
      _entity = _entity.merge(
        isLoading: false,
        errorMessage: 'Failed to load data: $e',
      );
      _notifyListeners();
    }
  }

  /// Select a payee
  void selectPayee(Payee payee) {
    _entity = _entity.merge(
      selectedPayee: payee,
      step: TransferStep.enterAmount,
    );
    _notifyListeners();
  }

  /// Select source account
  void selectAccount(Account account) {
    _entity = _entity.merge(selectedAccount: account);
    _notifyListeners();
  }

  /// Set transfer amount
  void setAmount(double amount) {
    _entity = _entity.merge(amount: amount);
    _notifyListeners();
  }

  /// Set memo
  void setMemo(String memo) {
    _entity = _entity.merge(memo: memo);
    _notifyListeners();
  }

  /// Proceed to next step
  void nextStep() {
    if (!_entity.canProceed) return;

    switch (_entity.step) {
      case TransferStep.selectPayee:
        _entity = _entity.merge(step: TransferStep.enterAmount);
        break;
      case TransferStep.enterAmount:
        _entity = _entity.merge(step: TransferStep.confirm);
        break;
      case TransferStep.confirm:
        submitTransfer();
        return;
      case TransferStep.success:
        break;
    }
    _notifyListeners();
  }

  /// Go back to previous step
  void previousStep() {
    switch (_entity.step) {
      case TransferStep.selectPayee:
        break;
      case TransferStep.enterAmount:
        _entity = _entity.merge(step: TransferStep.selectPayee);
        break;
      case TransferStep.confirm:
        _entity = _entity.merge(step: TransferStep.enterAmount);
        break;
      case TransferStep.success:
        break;
    }
    _notifyListeners();
  }

  /// Submit the transfer
  Future<void> submitTransfer() async {
    if (_entity.selectedPayee == null ||
        _entity.selectedAccount == null ||
        _entity.amount == null) {
      return;
    }

    _entity = _entity.merge(isSubmitting: true, errorMessage: null);
    _notifyListeners();

    try {
      final request = TransferRequest(
        fromAccountId: _entity.selectedAccount!.id,
        toPayeeId: _entity.selectedPayee!.id,
        amount: _entity.amount!,
        memo: _entity.memo,
      );

      final response = await _apiClient.post<Map<String, dynamic>>(
        'api/v1/transfers',
        body: request.toJson(),
      );

      response.fold(
        onSuccess: (data) {
          _entity = _entity.merge(
            isSubmitting: false,
            step: TransferStep.success,
            transferResult: TransferResult(
              transferId: data['data']['transferId'] as String,
              status: data['data']['status'] as String,
            ),
          );
          _notifyListeners();
        },
        onError: (error, type) {
          _entity = _entity.merge(
            isSubmitting: false,
            errorMessage: error,
          );
          _notifyListeners();
        },
      );
    } catch (e) {
      _entity = _entity.merge(
        isSubmitting: false,
        errorMessage: 'Transfer failed: $e',
      );
      _notifyListeners();
    }
  }

  /// Reset for new transfer
  void reset() {
    _entity = TransferEntity();
    _notifyListeners();
    loadData();
  }

  void _notifyListeners() {
    _viewModelCallback(TransferViewModel.fromEntity(_entity));
  }
}
