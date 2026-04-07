import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// A tile widget for quick actions on the hub screen
class ActionTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? icon;

  const ActionTile({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    icon ?? _getIconForAction(title),
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForAction(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('checking') || lowerAction.contains('account')) {
      return Icons.account_balance_wallet;
    } else if (lowerAction.contains('zelle') || lowerAction.contains('send')) {
      return Icons.send_rounded;
    } else if (lowerAction.contains('transfer')) {
      return Icons.swap_horiz;
    } else if (lowerAction.contains('loan')) {
      return Icons.account_balance;
    } else if (lowerAction.contains('deposit') || lowerAction.contains('check')) {
      return Icons.camera_alt;
    } else if (lowerAction.contains('notification') || lowerAction.contains('alert')) {
      return Icons.notifications;
    } else if (lowerAction.contains('more')) {
      return Icons.more_horiz;
    } else if (lowerAction.contains('profile')) {
      return Icons.person;
    } else if (lowerAction.contains('bill') || lowerAction.contains('pay')) {
      return Icons.receipt_long;
    } else if (lowerAction.contains('card')) {
      return Icons.credit_card;
    }
    return Icons.circle;
  }
}
