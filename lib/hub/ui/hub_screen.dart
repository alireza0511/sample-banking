import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/app_router.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';

/// Main hub screen - the application's central navigation point
/// Layout adapts based on accessibility settings (implemented in M2)
class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kind Banking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              _BalanceCard(
                onTap: () => context.push(Routes.balance),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickActionsGrid(),
              const SizedBox(height: AppSpacing.lg),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => context.push(Routes.transactions),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _RecentTransactionsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.chat),
        tooltip: 'Chat Assistant',
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRouter.setAuthenticated(false);
              context.go(Routes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Balance card showing account summary
class _BalanceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BalanceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Balance',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {}, // TODO: Toggle balance visibility
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '\$12,450.00',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _AccountChip(
                    label: 'Checking',
                    amount: '\$8,200.00',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _AccountChip(
                    label: 'Savings',
                    amount: '\$4,250.00',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String label;
  final String amount;

  const _AccountChip({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '$label: $amount',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryDark,
            ),
      ),
    );
  }
}

/// Quick actions grid
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        _QuickActionButton(
          icon: Icons.send,
          label: 'Transfer',
          onTap: () => context.push(Routes.transfer),
        ),
        _QuickActionButton(
          icon: Icons.receipt_long,
          label: 'Pay Bills',
          onTap: () => context.push(Routes.payBills),
        ),
        _QuickActionButton(
          icon: Icons.credit_card,
          label: 'Cards',
          onTap: () => context.push(Routes.cards),
        ),
        _QuickActionButton(
          icon: Icons.history,
          label: 'History',
          onTap: () => context.push(Routes.transactions),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent transactions list
class _RecentTransactionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock data for demo
    final transactions = [
      _TransactionItem(
        title: 'Coffee Shop',
        subtitle: 'Today, 9:30 AM',
        amount: '-\$4.50',
        isDebit: true,
      ),
      _TransactionItem(
        title: 'Salary Deposit',
        subtitle: 'Yesterday',
        amount: '+\$3,500.00',
        isDebit: false,
      ),
      _TransactionItem(
        title: 'Electric Bill',
        subtitle: 'Mar 5',
        amount: '-\$125.00',
        isDebit: true,
      ),
    ];

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => transactions[index],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isDebit;

  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isDebit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDebit
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          color: isDebit ? AppColors.error : AppColors.success,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDebit ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
