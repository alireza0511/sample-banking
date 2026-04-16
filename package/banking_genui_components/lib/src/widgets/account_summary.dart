import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays an account summary card with balance information.
///
/// This widget is designed to be used with GenUI/A2UI for dynamic rendering
/// by AI agents in banking applications.
class AccountSummary extends StatelessWidget {
  /// The name of the account (e.g., "Primary Checking")
  final String accountName;

  /// The current balance of the account
  final double balance;

  /// The type of account (e.g., "checking", "savings", "investment")
  final String accountType;

  /// The masked account number (e.g., "****1234")
  final String? accountNumber;

  /// Whether to hide the balance (privacy mode)
  final bool hideBalance;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  const AccountSummary({
    super.key,
    required this.accountName,
    required this.balance,
    required this.accountType,
    this.accountNumber,
    this.hideBalance = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Account type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAccountColor(accountType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAccountIcon(accountType),
                  color: _getAccountColor(accountType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Account details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_getAccountTypeLabel(accountType)}${accountNumber != null ? ' $accountNumber' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
                    hideBalance ? '••••••' : currencyFormat.format(balance),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: balance >= 0
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.error,
                    ),
                  ),
                  Text(
                    'Available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checking':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'credit':
        return Icons.credit_card;
      case 'loan':
        return Icons.account_balance;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getAccountColor(String type) {
    switch (type.toLowerCase()) {
      case 'checking':
        return Colors.blue;
      case 'savings':
        return Colors.green;
      case 'investment':
        return Colors.purple;
      case 'credit':
        return Colors.orange;
      case 'loan':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getAccountTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'checking':
        return 'Checking';
      case 'savings':
        return 'Savings';
      case 'investment':
        return 'Investment';
      case 'credit':
        return 'Credit Card';
      case 'loan':
        return 'Loan';
      default:
        return type;
    }
  }
}
