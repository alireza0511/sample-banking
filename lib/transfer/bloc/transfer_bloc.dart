import 'package:clean_framework/clean_framework.dart';

import '../../balance/model/account.dart';
import '../model/payee.dart';
import 'transfer_use_case.dart';
import 'transfer_view_model.dart';

export 'transfer_entity.dart' show TransferStep;
export 'transfer_view_model.dart';

/// Bloc for managing transfer screen
class TransferBloc extends Bloc {
  final String? initialRecipient;
  final double? initialAmount;

  late final TransferUseCase _useCase;

  final viewModelPipe = Pipe<TransferViewModel>();
  final selectPayeePipe = Pipe<Payee>();
  final selectAccountPipe = Pipe<Account>();
  final setAmountPipe = Pipe<double>();
  final setMemoPipe = Pipe<String>();
  final nextStepPipe = EventPipe();
  final previousStepPipe = EventPipe();
  final submitPipe = EventPipe();
  final resetPipe = EventPipe();

  @override
  void dispose() {
    viewModelPipe.dispose();
    selectPayeePipe.dispose();
    selectAccountPipe.dispose();
    setAmountPipe.dispose();
    setMemoPipe.dispose();
    nextStepPipe.dispose();
    previousStepPipe.dispose();
    submitPipe.dispose();
    resetPipe.dispose();
  }

  TransferBloc({this.initialRecipient, this.initialAmount}) {
    _useCase = TransferUseCase(viewModelPipe.send);

    // Initialize with deep link params when pipe is listened to
    viewModelPipe.whenListenedDo(() {
      _useCase.initialize(
        recipientId: initialRecipient,
        amount: initialAmount,
      );
    });

    // Input handlers
    selectPayeePipe.receive.listen((payee) => _useCase.selectPayee(payee));
    selectAccountPipe.receive.listen((account) => _useCase.selectAccount(account));
    setAmountPipe.receive.listen((amount) => _useCase.setAmount(amount));
    setMemoPipe.receive.listen((memo) => _useCase.setMemo(memo));
    nextStepPipe.listen(_useCase.nextStep);
    previousStepPipe.listen(_useCase.previousStep);
    submitPipe.listen(_useCase.submitTransfer);
    resetPipe.listen(_useCase.reset);
  }
}
