import 'package:clean_framework/clean_framework.dart';

import '../model/linked_account.dart';
import 'linked_accounts_entity.dart';

/// View model for the linked accounts screen
class LinkedAccountsViewModel extends ViewModel {
  final List<LinkedAccount> accounts;
  final bool isLoading;
  final bool isLinking;
  final String? errorMessage;

  LinkedAccountsViewModel({
    required this.accounts,
    required this.isLoading,
    required this.isLinking,
    this.errorMessage,
  });

  factory LinkedAccountsViewModel.fromEntity(LinkedAccountsEntity entity) {
    return LinkedAccountsViewModel(
      accounts: entity.accounts,
      isLoading: entity.isLoading,
      isLinking: entity.isLinking,
      errorMessage: entity.errorMessage,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isEmpty => !isLoading && !hasError && accounts.isEmpty;

  @override
  List<Object?> get props => [accounts, isLoading, isLinking, errorMessage];
}
