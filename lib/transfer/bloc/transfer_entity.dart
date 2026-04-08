import 'package:clean_framework/clean_framework.dart';
import 'package:equatable/equatable.dart';

import '../../balance/model/account.dart';
import '../model/payee.dart';

/// Transfer screen state
enum TransferStep {
  selectPayee,
  enterAmount,
  confirm,
  success,
}

/// Entity representing the transfer screen state
class TransferEntity extends Entity {
  final List<Payee> payees;
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

  TransferEntity({
    List<EntityFailure> errors = const [],
    this.payees = const [],
    this.accounts = const [],
    this.selectedPayee,
    this.selectedAccount,
    this.amount,
    this.memo,
    this.step = TransferStep.selectPayee,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.transferResult,
  }) : super(errors: errors);

  @override
  TransferEntity merge({
    List<EntityFailure>? errors,
    List<Payee>? payees,
    List<Account>? accounts,
    Payee? selectedPayee,
    Account? selectedAccount,
    double? amount,
    String? memo,
    TransferStep? step,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    TransferResult? transferResult,
  }) {
    return TransferEntity(
      errors: errors ?? this.errors,
      payees: payees ?? this.payees,
      accounts: accounts ?? this.accounts,
      selectedPayee: selectedPayee ?? this.selectedPayee,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      transferResult: transferResult ?? this.transferResult,
    );
  }

  bool get canProceed {
    switch (step) {
      case TransferStep.selectPayee:
        return selectedPayee != null;
      case TransferStep.enterAmount:
        return amount != null && amount! > 0 && selectedAccount != null;
      case TransferStep.confirm:
        return true;
      case TransferStep.success:
        return false;
    }
  }

  @override
  List<Object?> get props => [
        errors,
        payees,
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
      ];
}

/// Transfer result
class TransferResult extends Equatable {
  final String transferId;
  final String status;
  final DateTime? estimatedArrival;

  const TransferResult({
    required this.transferId,
    required this.status,
    this.estimatedArrival,
  });

  @override
  List<Object?> get props => [transferId, status, estimatedArrival];
}
