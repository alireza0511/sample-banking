import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../widgets/account_summary.dart';
import '../widgets/quick_transfer.dart';
import '../widgets/transaction_item.dart';

/// Banking-specific widget catalog for GenUI/A2UI integration.
///
/// This catalog provides banking UI components that AI agents can use
/// to generate dynamic interfaces for banking applications.
class BankingCatalog {
  BankingCatalog._();

  /// Returns all banking catalog items
  static List<CatalogItem> get items => [
        accountSummaryItem,
        quickTransferItem,
        transactionItemItem,
        transactionListItem,
      ];

  /// Returns the banking catalog combined with core items
  static Catalog asCatalog() {
    return CoreCatalogItems.asCatalog().copyWith(items);
  }

  // Schemas
  static final _accountSummarySchema = S.object(
    description: 'Displays an account card with name, type, and balance.',
    properties: {
      'accountName': S.string(
        description: 'The name of the account (e.g., "Primary Checking")',
      ),
      'balance': S.number(
        description: 'The current balance of the account',
      ),
      'accountType': S.string(
        description: 'The type: "checking", "savings", "investment", "credit", or "loan"',
      ),
      'accountNumber': S.string(
        description: 'The masked account number (e.g., "****1234")',
      ),
      'hideBalance': S.boolean(
        description: 'Whether to hide the balance for privacy',
      ),
    },
    required: ['accountName', 'balance', 'accountType'],
  );

  static final _quickTransferSchema = S.object(
    description: 'Displays a transfer form for moving money between accounts.',
    properties: {
      'fromAccount': S.string(description: 'The source account name'),
      'toAccount': S.string(description: 'The destination account or recipient'),
      'initialAmount': S.number(description: 'Pre-filled amount (optional)'),
      'memo': S.string(description: 'Optional memo or note'),
    },
    required: ['fromAccount', 'toAccount'],
  );

  static final _transactionItemSchema = S.object(
    description: 'Displays a single transaction with merchant, amount, and date.',
    properties: {
      'merchant': S.string(description: 'The merchant or description'),
      'amount': S.number(description: 'Amount (negative for debits)'),
      'date': S.string(description: 'Date in ISO 8601 format'),
      'category': S.string(description: 'Category like "food", "shopping", etc.'),
      'isPending': S.boolean(description: 'Whether pending'),
    },
    required: ['merchant', 'amount', 'date'],
  );

  static final _transactionSchema = S.object(
    properties: {
      'id': S.string(description: 'Transaction ID'),
      'merchant': S.string(description: 'Merchant name'),
      'amount': S.number(description: 'Transaction amount'),
      'date': S.string(description: 'Date in ISO 8601 format'),
      'category': S.string(description: 'Transaction category'),
      'isPending': S.boolean(description: 'Is pending'),
    },
    required: ['id', 'merchant', 'amount', 'date'],
  );

  static final _transactionListSchema = S.object(
    description: 'Displays a list of transactions with an optional header.',
    properties: {
      'header': S.string(description: 'Optional header text'),
      'transactions': S.list(
        description: 'Array of transaction objects',
        items: _transactionSchema,
      ),
    },
    required: ['transactions'],
  );

  /// AccountSummary catalog item
  static final accountSummaryItem = CatalogItem(
    name: 'AccountSummary',
    dataSchema: _accountSummarySchema,
    widgetBuilder: (itemContext) {
      final json = itemContext.data as Map<String, Object?>? ?? {};
      return AccountSummary(
        accountName: json['accountName'] as String? ?? 'Account',
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        accountType: json['accountType'] as String? ?? 'checking',
        accountNumber: json['accountNumber'] as String?,
        hideBalance: json['hideBalance'] as bool? ?? false,
      );
    },
  );

  /// QuickTransfer catalog item
  static final quickTransferItem = CatalogItem(
    name: 'QuickTransfer',
    dataSchema: _quickTransferSchema,
    widgetBuilder: (itemContext) {
      final json = itemContext.data as Map<String, Object?>? ?? {};
      return QuickTransfer(
        fromAccount: json['fromAccount'] as String? ?? 'Select Account',
        toAccount: json['toAccount'] as String? ?? 'Select Recipient',
        initialAmount: (json['initialAmount'] as num?)?.toDouble(),
        memo: json['memo'] as String?,
        onSubmit: (amount, memo) {
          itemContext.dispatchEvent(
            UserActionEvent(
              name: 'transfer_submitted',
              sourceComponentId: itemContext.id,
              context: {
                'amount': amount,
                'memo': memo,
                'fromAccount': json['fromAccount'],
                'toAccount': json['toAccount'],
              },
            ),
          );
        },
        onCancel: () {
          itemContext.dispatchEvent(
            UserActionEvent(
              name: 'transfer_cancelled',
              sourceComponentId: itemContext.id,
            ),
          );
        },
      );
    },
  );

  /// TransactionItem catalog item
  static final transactionItemItem = CatalogItem(
    name: 'TransactionItem',
    dataSchema: _transactionItemSchema,
    widgetBuilder: (itemContext) {
      final json = itemContext.data as Map<String, Object?>? ?? {};
      DateTime date;
      try {
        date = DateTime.parse(json['date'] as String? ?? '');
      } catch (_) {
        date = DateTime.now();
      }

      return TransactionItem(
        merchant: json['merchant'] as String? ?? 'Unknown',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: date,
        category: json['category'] as String?,
        isPending: json['isPending'] as bool? ?? false,
      );
    },
  );

  /// TransactionList catalog item
  static final transactionListItem = CatalogItem(
    name: 'TransactionList',
    dataSchema: _transactionListSchema,
    widgetBuilder: (itemContext) {
      final json = itemContext.data as Map<String, Object?>? ?? {};
      final transactionsData = json['transactions'] as List<dynamic>? ?? [];
      final transactions = transactionsData.map((t) {
        final txn = t as Map<String, Object?>;
        DateTime date;
        try {
          date = DateTime.parse(txn['date'] as String? ?? '');
        } catch (_) {
          date = DateTime.now();
        }
        return TransactionData(
          id: txn['id'] as String? ?? '',
          merchant: txn['merchant'] as String? ?? 'Unknown',
          amount: (txn['amount'] as num?)?.toDouble() ?? 0.0,
          date: date,
          category: txn['category'] as String?,
          isPending: txn['isPending'] as bool? ?? false,
        );
      }).toList();

      return TransactionList(
        header: json['header'] as String?,
        transactions: transactions,
        onTransactionTap: (transaction) {
          itemContext.dispatchEvent(
            UserActionEvent(
              name: 'transaction_tapped',
              sourceComponentId: itemContext.id,
              context: {
                'transactionId': transaction.id,
              },
            ),
          );
        },
      );
    },
  );
}
