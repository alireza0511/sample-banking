import 'package:clean_framework/clean_framework.dart';

import '../model/account.dart';

/// Entity representing the balance screen state
class BalanceEntity extends Entity {
  final List<Account> accounts;
  final double totalBalance;
  final double netWealth;
  final bool isLoading;
  final bool isBalanceHidden;
  final String? errorMessage;
  final String? selectedAccountId;

  BalanceEntity({
    List<EntityFailure> errors = const [],
    this.accounts = const [],
    this.totalBalance = 0,
    this.netWealth = 0,
    this.isLoading = false,
    this.isBalanceHidden = false,
    this.errorMessage,
    this.selectedAccountId,
  }) : super(errors: errors);

  @override
  BalanceEntity merge({
    List<EntityFailure>? errors,
    List<Account>? accounts,
    double? totalBalance,
    double? netWealth,
    bool? isLoading,
    bool? isBalanceHidden,
    String? errorMessage,
    String? selectedAccountId,
  }) {
    return BalanceEntity(
      errors: errors ?? this.errors,
      accounts: accounts ?? this.accounts,
      totalBalance: totalBalance ?? this.totalBalance,
      netWealth: netWealth ?? this.netWealth,
      isLoading: isLoading ?? this.isLoading,
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
      errorMessage: errorMessage,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
    );
  }

  /// Get the selected account or primary account
  Account? get selectedAccount {
    if (accounts.isEmpty) return null;
    if (selectedAccountId != null) {
      return accounts.firstWhere(
        (a) => a.id == selectedAccountId,
        orElse: () => accounts.first,
      );
    }
    return accounts.firstWhere((a) => a.isPrimary, orElse: () => accounts.first);
  }

  /// Check if we have data
  bool get hasData => accounts.isNotEmpty;

  @override
  List<Object?> get props => [
        errors,
        accounts,
        totalBalance,
        netWealth,
        isLoading,
        isBalanceHidden,
        errorMessage,
        selectedAccountId,
      ];
}
