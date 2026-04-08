import 'package:clean_framework/clean_framework.dart';

import 'balance_use_case.dart';
import 'balance_view_model.dart';

export 'balance_view_model.dart';

/// Bloc for managing balance screen
class BalanceBloc extends Bloc {
  late final BalanceUseCase _useCase;

  final viewModelPipe = Pipe<BalanceViewModel>();
  final refreshPipe = EventPipe();
  final toggleVisibilityPipe = EventPipe();
  final selectAccountPipe = Pipe<String>();

  @override
  void dispose() {
    viewModelPipe.dispose();
    refreshPipe.dispose();
    toggleVisibilityPipe.dispose();
    selectAccountPipe.dispose();
  }

  BalanceBloc() {
    _useCase = BalanceUseCase(viewModelPipe.send);
    viewModelPipe.whenListenedDo(_useCase.loadAccounts);

    refreshPipe.listen(_useCase.refresh);
    toggleVisibilityPipe.listen(_useCase.toggleBalanceVisibility);
    selectAccountPipe.receive.listen((accountId) {
      if (accountId.isNotEmpty) {
        _useCase.selectAccount(accountId);
      }
    });
  }
}
