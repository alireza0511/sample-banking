import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../bloc/linked_accounts_bloc.dart';
import '../model/linked_account.dart';

/// External bank accounts linked through Plaid Link
class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  late final LinkedAccountsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = LinkedAccountsBloc();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<LinkedAccountsBloc>.value(
      value: _bloc,
      child: StreamBuilder<LinkedAccountsViewModel>(
        stream: _bloc.viewModelPipe.receive,
        builder: (context, snapshot) {
          final viewModel = snapshot.data;
          final canLink = viewModel != null && !viewModel.isLinking;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Linked Accounts'),
              bottom: viewModel?.isLinking == true
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(4),
                      child: LinearProgressIndicator(),
                    )
                  : null,
            ),
            floatingActionButton: viewModel != null && viewModel.accounts.isNotEmpty
                ? FloatingActionButton.extended(
                    onPressed: canLink ? () => _bloc.linkPipe.launch() : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Link account'),
                  )
                : null,
            body: _buildBody(viewModel, canLink),
          );
        },
      ),
    );
  }

  Widget _buildBody(LinkedAccountsViewModel? viewModel, bool canLink) {
    if (viewModel == null || viewModel.isLoading) {
      return const ShimmerList(itemCount: 3, itemHeight: 72);
    }

    if (viewModel.hasError) {
      return ErrorView(
        message: viewModel.errorMessage,
        onRetry: () => _bloc.refreshPipe.launch(),
      );
    }

    if (viewModel.isEmpty) {
      return EmptyView(
        title: 'No Linked Accounts',
        message: 'Link an account at another bank to see it here.',
        icon: Icons.account_balance_outlined,
        actionLabel: 'Link account',
        onAction: canLink ? () => _bloc.linkPipe.launch() : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _bloc.refreshPipe.launch(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: viewModel.accounts.map(_LinkedAccountTile.new).toList(),
      ),
    );
  }
}

class _LinkedAccountTile extends StatelessWidget {
  final LinkedAccount account;

  const _LinkedAccountTile(this.account);

  @override
  Widget build(BuildContext context) {
    final balance = account.balance;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance),
        title: Text(account.name),
        subtitle: Text(
          '${account.institution} · ${account.type} •••• ${account.mask}',
        ),
        trailing: Text(
          balance == null
              ? '—'
              : '${account.currency} ${balance.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
