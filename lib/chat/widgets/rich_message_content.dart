import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Rich message content parser and renderer
class RichMessageContent extends StatelessWidget {
  final String content;
  final bool isUser;

  const RichMessageContent({
    super.key,
    required this.content,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    // For user messages, always show plain text
    if (isUser) {
      return Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
      );
    }

    // For assistant messages, check if it contains structured data
    final richContent = _parseContent(content);

    if (richContent != null) {
      return richContent;
    }

    // Default to plain text
    return Text(
      content,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget? _parseContent(String text) {
    // Check for balance pattern: "Your balance is $1,234.56" or "balance: $1,234.56"
    final balanceMatch = RegExp(r'balance[:\s]+\$?([0-9,]+\.?\d*)').firstMatch(text.toLowerCase());
    if (balanceMatch != null) {
      return _BalanceCard(
        amount: balanceMatch.group(1) ?? '0',
        message: text,
      );
    }

    // Check for transaction list pattern
    if (text.toLowerCase().contains('transaction') && text.contains('\n')) {
      return _TransactionList(message: text);
    }

    // Check for action buttons pattern: "[Transfer Money]" or "[Pay Bills]"
    final hasActions = RegExp(r'\[([^\]]+)\]').hasMatch(text);
    if (hasActions) {
      return _MessageWithActions(message: text);
    }

    return null;
  }
}

/// Balance card widget
class _BalanceCard extends StatelessWidget {
  final String amount;
  final String message;

  const _BalanceCard({
    required this.amount,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Balance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '\$$amount',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Transaction list widget
class _TransactionList extends StatelessWidget {
  final String message;

  const _TransactionList({required this.message});

  @override
  Widget build(BuildContext context) {
    final lines = message.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lines.isNotEmpty) ...[
          Text(
            lines.first,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...lines.skip(1).map((line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      line.trim(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

/// Message with action buttons
class _MessageWithActions extends StatelessWidget {
  final String message;

  const _MessageWithActions({required this.message});

  @override
  Widget build(BuildContext context) {
    // Extract text and actions
    var remainingText = message;
    final actionMatches = RegExp(r'\[([^\]]+)\]').allMatches(message);

    if (actionMatches.isEmpty) {
      return Text(message);
    }

    // Extract actions
    final actions = actionMatches.map((m) => m.group(1)!).toList();

    // Remove action markers from text
    remainingText = message.replaceAll(RegExp(r'\[([^\]]+)\]'), '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (remainingText.isNotEmpty) ...[
          Text(
            remainingText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: actions.map((action) {
            return FilledButton.tonalIcon(
              onPressed: () {
                // TODO: Handle action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Action: $action')),
                );
              },
              icon: _getActionIcon(action),
              label: Text(action),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                foregroundColor: AppColors.primaryBlue,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Icon _getActionIcon(String action) {
    final actionLower = action.toLowerCase();
    if (actionLower.contains('transfer')) {
      return const Icon(Icons.send, size: 18);
    } else if (actionLower.contains('bill')) {
      return const Icon(Icons.receipt, size: 18);
    } else if (actionLower.contains('card')) {
      return const Icon(Icons.credit_card, size: 18);
    } else if (actionLower.contains('transaction')) {
      return const Icon(Icons.list, size: 18);
    }
    return const Icon(Icons.arrow_forward, size: 18);
  }
}
