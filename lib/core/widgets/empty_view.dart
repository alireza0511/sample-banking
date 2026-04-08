import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Full-screen empty state view
class EmptyView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  factory EmptyView.noAccounts({VoidCallback? onAction}) {
    return EmptyView(
      title: 'No Accounts',
      message: 'You don\'t have any accounts yet.',
      icon: Icons.account_balance_wallet_outlined,
      actionLabel: 'Add Account',
      onAction: onAction,
    );
  }

  factory EmptyView.noTransactions({VoidCallback? onAction}) {
    return EmptyView(
      title: 'No Transactions',
      message: 'Your transaction history will appear here.',
      icon: Icons.receipt_long_outlined,
    );
  }

  factory EmptyView.noCards({VoidCallback? onAction}) {
    return EmptyView(
      title: 'No Cards',
      message: 'You don\'t have any cards linked to your account.',
      icon: Icons.credit_card_outlined,
      actionLabel: 'Add Card',
      onAction: onAction,
    );
  }

  factory EmptyView.noBills({VoidCallback? onAction}) {
    return EmptyView(
      title: 'No Bills',
      message: 'Add billers to pay your bills quickly.',
      icon: Icons.receipt_outlined,
      actionLabel: 'Add Biller',
      onAction: onAction,
    );
  }

  factory EmptyView.noPayees({VoidCallback? onAction}) {
    return EmptyView(
      title: 'No Payees',
      message: 'Add contacts to send money easily.',
      icon: Icons.people_outline,
      actionLabel: 'Add Payee',
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
