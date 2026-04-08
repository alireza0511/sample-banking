import 'package:equatable/equatable.dart';

/// Transaction types
enum TransactionType {
  debit,
  credit,
}

/// Transaction categories
enum TransactionCategory {
  shopping,
  food,
  utilities,
  income,
  transfer,
  entertainment,
  travel,
  health,
  other,
}

/// Transaction model
class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final double amount;
  final double balance;
  final DateTime date;
  final String status;
  final String? merchantLogo;

  const Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.balance,
    required this.date,
    required this.status,
    this.merchantLogo,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: (json['type'] as String).toLowerCase() == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
      category: _parseCategory(json['category'] as String),
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      merchantLogo: json['merchantLogo'] as String?,
    );
  }

  static TransactionCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return TransactionCategory.shopping;
      case 'food':
        return TransactionCategory.food;
      case 'utilities':
        return TransactionCategory.utilities;
      case 'income':
        return TransactionCategory.income;
      case 'transfer':
        return TransactionCategory.transfer;
      case 'entertainment':
        return TransactionCategory.entertainment;
      case 'travel':
        return TransactionCategory.travel;
      case 'health':
        return TransactionCategory.health;
      default:
        return TransactionCategory.other;
    }
  }

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;

  String get formattedAmount {
    final prefix = isCredit ? '+' : '';
    return '$prefix\$${amount.abs().toStringAsFixed(2)}';
  }

  String get categoryDisplayName {
    switch (category) {
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.food:
        return 'Food & Dining';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.income:
        return 'Income';
      case TransactionCategory.transfer:
        return 'Transfer';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        category,
        description,
        amount,
        balance,
        date,
        status,
        merchantLogo,
      ];
}

/// Pagination info
class PaginationInfo extends Equatable {
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalItems;
  final bool hasMore;

  const PaginationInfo({
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalItems,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, totalPages, totalItems, hasMore];
}
