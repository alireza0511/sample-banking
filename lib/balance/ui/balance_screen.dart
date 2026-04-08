import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../bloc/balance_bloc.dart';
import '../model/account.dart';

/// Balance screen showing account summary and balances
class BalanceScreen extends StatefulWidget {
  final String? initialAccountId;

  const BalanceScreen({super.key, this.initialAccountId});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  late final BalanceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BalanceBloc();

    // Select initial account if provided via deep link
    if (widget.initialAccountId != null) {
      _bloc.selectAccountPipe.send(widget.initialAccountId!);
    }
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<BalanceBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
          actions: [
            StreamBuilder<BalanceViewModel>(
              stream: _bloc.viewModelPipe.receive,
              builder: (context, snapshot) {
                final isHidden = snapshot.data?.isBalanceHidden ?? false;
                return IconButton(
                  icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => _bloc.toggleVisibilityPipe.launch(),
                  tooltip: isHidden ? 'Show balances' : 'Hide balances',
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<BalanceViewModel>(
          stream: _bloc.viewModelPipe.receive,
          builder: (context, snapshot) {
            final viewModel = snapshot.data;

            if (viewModel == null || viewModel.isLoading) {
              return const ShimmerList(itemCount: 3, itemHeight: 100);
            }

            if (viewModel.hasError) {
              return ErrorView(
                message: viewModel.errorMessage,
                onRetry: () => _bloc.refreshPipe.launch(),
              );
            }

            if (viewModel.isEmpty) {
              return EmptyView.noAccounts();
            }

            return RefreshIndicator(
              onRefresh: () async => _bloc.refreshPipe.launch(),
              child: _BalanceContent(viewModel: viewModel),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceContent extends StatelessWidget {
  final BalanceViewModel viewModel;

  const _BalanceContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Net Wealth Card
        _NetWealthCard(
          netWealth: viewModel.netWealth,
          isHidden: viewModel.isBalanceHidden,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Section header
        Text(
          'Your Accounts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Account cards
        ...viewModel.accounts.map(
          (account) => _AccountCard(
            account: account,
            isHidden: viewModel.isBalanceHidden,
            isSelected: account.id == viewModel.selectedAccount?.id,
          ),
        ),
      ],
    );
  }
}

class _NetWealthCard extends StatelessWidget {
  final double netWealth;
  final bool isHidden;

  const _NetWealthCard({
    required this.netWealth,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Wealth',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isHidden ? '••••••' : '\$${netWealth.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final bool isHidden;
  final bool isSelected;

  const _AccountCard({
    required this.account,
    required this.isHidden,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        elevation: isSelected ? 2 : 1,
        child: InkWell(
          onTap: () {
            // Navigate to transactions for this account
            context.push(
              '${Routes.transactions}?${RouteParams.accountId}=${account.id}',
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primaryBlue, width: 2),
                  )
                : null,
            child: Row(
              children: [
                // Account type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getAccountColor(account.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    _getAccountIcon(account.type),
                    color: _getAccountColor(account.type),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Account info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            account.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (account.isPrimary) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Primary',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.primaryBlue,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${account.typeDisplayName} ${account.accountNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isHidden ? '••••••' : '\$${account.balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Available: ${isHidden ? '••••' : '\$${account.availableBalance.toStringAsFixed(2)}'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),

                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return Icons.account_balance_wallet;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.loan:
        return Icons.account_balance;
    }
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return AppColors.primaryBlue;
      case AccountType.savings:
        return Colors.green;
      case AccountType.investment:
        return Colors.purple;
      case AccountType.loan:
        return Colors.orange;
    }
  }
}
