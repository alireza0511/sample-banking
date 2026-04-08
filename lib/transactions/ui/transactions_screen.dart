import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../bloc/transactions_bloc.dart';
import '../model/transaction.dart';

/// Transactions screen showing transaction history
class TransactionsScreen extends StatefulWidget {
  final String? accountId;
  final String? filter;

  const TransactionsScreen({
    super.key,
    this.accountId,
    this.filter,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TransactionsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TransactionsBloc(
      initialAccountId: widget.accountId,
      initialFilter: widget.filter,
    );
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<TransactionsBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterSheet(context),
            ),
          ],
        ),
        body: StreamBuilder<TransactionsViewModel>(
          stream: _bloc.viewModelPipe.receive,
          builder: (context, snapshot) {
            final viewModel = snapshot.data;

            if (viewModel == null || viewModel.isLoading) {
              return const ShimmerList();
            }

            if (viewModel.hasError) {
              return ErrorView(
                message: viewModel.errorMessage,
                onRetry: () => _bloc.refreshPipe.launch(),
              );
            }

            if (viewModel.isEmpty) {
              return EmptyView.noTransactions();
            }

            return RefreshIndicator(
              onRefresh: () async => _bloc.refreshPipe.launch(),
              child: _TransactionsList(viewModel: viewModel, bloc: _bloc),
            );
          },
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet(
        onFilterSelected: (filter) {
          Navigator.pop(context);
          _bloc.filterPipe.send(filter);
        },
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final TransactionsViewModel viewModel;
  final TransactionsBloc bloc;

  const _TransactionsList({required this.viewModel, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final grouped = viewModel.groupedByDate;
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: keys.length + (viewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= keys.length) {
          // Load more indicator
          if (!viewModel.isLoadingMore) {
            bloc.loadMorePipe.launch();
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final dateKey = keys[index];
        final transactions = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...transactions.map((txn) => _TransactionTile(transaction: txn)),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getCategoryColor(transaction.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: _getCategoryColor(transaction.category),
            size: 22,
          ),
        ),
        title: Text(
          transaction.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Text(
          transaction.categoryDisplayName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        trailing: Text(
          transaction.formattedAmount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.isCredit ? AppColors.success : null,
              ),
        ),
        onTap: () => _showTransactionDetail(context, transaction),
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, Transaction txn) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TransactionDetailSheet(transaction: txn),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.utilities:
        return Icons.bolt;
      case TransactionCategory.income:
        return Icons.attach_money;
      case TransactionCategory.transfer:
        return Icons.swap_horiz;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.travel:
        return Icons.flight;
      case TransactionCategory.health:
        return Icons.medical_services;
      case TransactionCategory.other:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.shopping:
        return Colors.purple;
      case TransactionCategory.food:
        return Colors.orange;
      case TransactionCategory.utilities:
        return Colors.blue;
      case TransactionCategory.income:
        return Colors.green;
      case TransactionCategory.transfer:
        return AppColors.primaryBlue;
      case TransactionCategory.entertainment:
        return Colors.pink;
      case TransactionCategory.travel:
        return Colors.teal;
      case TransactionCategory.health:
        return Colors.red;
      case TransactionCategory.other:
        return Colors.grey;
    }
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetailSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              transaction.formattedAmount,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: transaction.isCredit ? AppColors.success : null,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              transaction.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          _DetailRow(label: 'Category', value: transaction.categoryDisplayName),
          _DetailRow(
            label: 'Date',
            value: '${transaction.date.month}/${transaction.date.day}/${transaction.date.year}',
          ),
          _DetailRow(label: 'Status', value: transaction.status.toUpperCase()),
          _DetailRow(
            label: 'Balance After',
            value: '\$${transaction.balance.toStringAsFixed(2)}',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final ValueChanged<String?> onFilterSelected;

  const _FilterSheet({required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('All', null),
      ('Income', 'income'),
      ('Shopping', 'shopping'),
      ('Food & Dining', 'food'),
      ('Utilities', 'utilities'),
      ('Transfers', 'transfer'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          ...filters.map((f) => ListTile(
                title: Text(f.$1),
                onTap: () => onFilterSelected(f.$2),
              )),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
