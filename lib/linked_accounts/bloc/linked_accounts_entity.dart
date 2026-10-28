import 'package:clean_framework/clean_framework.dart';

import '../model/linked_account.dart';

/// Entity representing the linked accounts screen state
class LinkedAccountsEntity extends Entity {
  final List<LinkedAccount> accounts;
  final bool isLoading;
  final bool isLinking;
  final String? errorMessage;

  LinkedAccountsEntity({
    List<EntityFailure> errors = const [],
    this.accounts = const [],
    this.isLoading = false,
    this.isLinking = false,
    this.errorMessage,
  }) : super(errors: errors);

  @override
  LinkedAccountsEntity merge({
    List<EntityFailure>? errors,
    List<LinkedAccount>? accounts,
    bool? isLoading,
    bool? isLinking,
    String? errorMessage,
  }) {
    return LinkedAccountsEntity(
      errors: errors ?? this.errors,
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      isLinking: isLinking ?? this.isLinking,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [errors, accounts, isLoading, isLinking, errorMessage];
}
