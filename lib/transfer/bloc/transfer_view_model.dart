import 'package:clean_framework/clean_framework.dart';

import '../../balance/model/account.dart';
import '../model/payee.dart';
import 'transfer_entity.dart';

/// View model for transfer screen
class TransferViewModel extends ViewModel {
  final List<Payee> payees;
  final List<Payee> favoritePayees;
  final List<Account> accounts;
  final Payee? selectedPayee;
  final Account? selectedAccount;
  final double? amount;
  final String? memo;
  final TransferStep step;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final TransferResult? transferResult;
  final bool canProceed;

  TransferViewModel({
    required this.payees,
    required this.favoritePayees,
    required this.accounts,
    this.selectedPayee,
    this.selectedAccount,
    this.amount,
    this.memo,
    required this.step,
    required this.isLoading,
    required this.isSubmitting,
    this.errorMessage,
    this.transferResult,
    required this.canProceed,
  });

  factory TransferViewModel.fromEntity(TransferEntity entity) {
    return TransferViewModel(
      payees: entity.payees,
      favoritePayees: entity.payees.where((p) => p.isFavorite).toList(),
      accounts: entity.accounts,
      selectedPayee: entity.selectedPayee,
      selectedAccount: entity.selectedAccount,
      amount: entity.amount,
      memo: entity.memo,
      step: entity.step,
      isLoading: entity.isLoading,
      isSubmitting: entity.isSubmitting,
      errorMessage: entity.errorMessage,
      transferResult: entity.transferResult,
      canProceed: entity.canProceed,
    );
  }

  factory TransferViewModel.initial() {
    return TransferViewModel(
      payees: const [],
      favoritePayees: const [],
      accounts: const [],
      step: TransferStep.selectPayee,
      isLoading: true,
      isSubmitting: false,
      canProceed: false,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isSuccess => step == TransferStep.success;

  String get stepTitle {
    switch (step) {
      case TransferStep.selectPayee:
        return 'Select Recipient';
      case TransferStep.enterAmount:
        return 'Enter Amount';
      case TransferStep.confirm:
        return 'Confirm Transfer';
      case TransferStep.success:
        return 'Success';
    }
  }

  @override
  List<Object?> get props => [
        payees,
        favoritePayees,
        accounts,
        selectedPayee,
        selectedAccount,
        amount,
        memo,
        step,
        isLoading,
        isSubmitting,
        errorMessage,
        transferResult,
        canProceed,
      ];
}
