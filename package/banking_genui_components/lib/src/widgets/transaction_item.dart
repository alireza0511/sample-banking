import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays a single transaction item.
///
/// This widget is designed to be used with GenUI/A2UI for dynamic rendering
/// by AI agents in banking applications.
class TransactionItem extends StatelessWidget {
  /// The merchant or transaction description
  final String merchant;

  /// The transaction amount (negative for debits, positive for credits)
  final double amount;

  /// The transaction date
  final DateTime date;

  /// The category of the transaction (e.g., "food", "shopping", "utilities")
  final String? category;

  /// Whether the transaction is pending
  final bool isPending;

  /// Callback when the item is tapped
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.merchant,
    required this.amount,
    required this.date,
    this.category,
    this.isPending = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat.MMMd();
    final isDebit = amount < 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          merchant,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPending)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Pending',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateFormat.format(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (category != null) ...[
                        Text(
                          ' • ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _getCategoryLabel(category!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${isDebit ? '-' : '+'}${currencyFormat.format(amount.abs())}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDebit
                    ? theme.colorScheme.onSurface
                    : Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'dining':
        return Icons.restaurant;
      case 'shopping':
      case 'retail':
        return Icons.shopping_bag;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'utilities':
        return Icons.electrical_services;
      case 'transport':
      case 'transportation':
      case 'gas':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'income':
      case 'salary':
      case 'payroll':
        return Icons.payments;
      case 'transfer':
        return Icons.swap_horiz;
      case 'subscription':
        return Icons.repeat;
      case 'travel':
        return Icons.flight;
      case 'education':
        return Icons.school;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'dining':
        return Colors.orange;
      case 'shopping':
      case 'retail':
        return Colors.pink;
      case 'groceries':
        return Colors.green;
      case 'utilities':
        return Colors.blue;
      case 'transport':
      case 'transportation':
      case 'gas':
        return Colors.indigo;
      case 'entertainment':
        return Colors.purple;
      case 'health':
      case 'medical':
        return Colors.red;
      case 'income':
      case 'salary':
      case 'payroll':
        return Colors.teal;
      case 'transfer':
        return Colors.cyan;
      case 'subscription':
        return Colors.deepOrange;
      case 'travel':
        return Colors.amber;
      case 'education':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    // Capitalize first letter
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }
}

/// A widget that displays a list of transactions with an optional header.
class TransactionList extends StatelessWidget {
  /// List of transactions to display
  final List<TransactionData> transactions;

  /// Optional header text
  final String? header;

  /// Callback when a transaction is tapped
  final void Function(TransactionData transaction)? onTransactionTap;

  const TransactionList({
    super.key,
    required this.transactions,
    this.header,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                header!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1, indent: 74),
                TransactionItem(
                  merchant: transaction.merchant,
                  amount: transaction.amount,
                  date: transaction.date,
                  category: transaction.category,
                  isPending: transaction.isPending,
                  onTap: onTransactionTap != null
                      ? () => onTransactionTap!(transaction)
                      : null,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Data class for transaction information
class TransactionData {
  final String id;
  final String merchant;
  final double amount;
  final DateTime date;
  final String? category;
  final bool isPending;

  const TransactionData({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    this.category,
    this.isPending = false,
  });
}
