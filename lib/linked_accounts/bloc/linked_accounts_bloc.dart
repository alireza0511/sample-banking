import 'package:clean_framework/clean_framework.dart';

import 'linked_accounts_use_case.dart';
import 'linked_accounts_view_model.dart';

export 'linked_accounts_view_model.dart';

/// Bloc for the linked accounts screen
class LinkedAccountsBloc extends Bloc {
  late final LinkedAccountsUseCase _useCase;

  final viewModelPipe = Pipe<LinkedAccountsViewModel>();
  final refreshPipe = EventPipe();
  final linkPipe = EventPipe();

  @override
  void dispose() {
    viewModelPipe.dispose();
    refreshPipe.dispose();
    linkPipe.dispose();
  }

  LinkedAccountsBloc() {
    _useCase = LinkedAccountsUseCase(viewModelPipe.send);
    viewModelPipe.whenListenedDo(_useCase.loadAccounts);

    refreshPipe.listen(_useCase.refresh);
    linkPipe.listen(_useCase.linkAccount);
  }
}
