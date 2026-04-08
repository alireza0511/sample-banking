import 'package:clean_framework/clean_framework.dart';

import '../model/account.dart';
import 'balance_entity.dart';

/// View model for the balance screen
class BalanceViewModel extends ViewModel {
  final List<Account> accounts;
  final double totalBalance;
  final double netWealth;
  final bool isLoading;
  final bool isBalanceHidden;
  final String? errorMessage;
  final Account? selectedAccount;

  BalanceViewModel({
    required this.accounts,
    required this.totalBalance,
    required this.netWealth,
    required this.isLoading,
    required this.isBalanceHidden,
    this.errorMessage,
    this.selectedAccount,
  });

  factory BalanceViewModel.fromEntity(BalanceEntity entity) {
    return BalanceViewModel(
      accounts: entity.accounts,
      totalBalance: entity.totalBalance,
      netWealth: entity.netWealth,
      isLoading: entity.isLoading,
      isBalanceHidden: entity.isBalanceHidden,
      errorMessage: entity.errorMessage,
      selectedAccount: entity.selectedAccount,
    );
  }

  factory BalanceViewModel.initial() {
    return BalanceViewModel(
      accounts: const [],
      totalBalance: 0,
      netWealth: 0,
      isLoading: true,
      isBalanceHidden: false,
    );
  }

  bool get hasData => accounts.isNotEmpty;
  bool get hasError => errorMessage != null;
  bool get isEmpty => !isLoading && !hasError && accounts.isEmpty;

  /// Format balance for display
  String formatBalance(double amount) {
    if (isBalanceHidden) return '••••••';
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        accounts,
        totalBalance,
        netWealth,
        isLoading,
        isBalanceHidden,
        errorMessage,
        selectedAccount,
      ];
}
