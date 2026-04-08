import 'package:equatable/equatable.dart';

/// Biller model
class Biller extends Equatable {
  final String id;
  final String name;
  final String accountNumber;
  final DateTime nextDueDate;
  final double amountDue;
  final bool autopay;
  final String category;
  final String? logo;

  const Biller({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.nextDueDate,
    required this.amountDue,
    required this.autopay,
    required this.category,
    this.logo,
  });

  factory Biller.fromJson(Map<String, dynamic> json) {
    return Biller(
      id: json['id'] as String,
      name: json['name'] as String,
      accountNumber: json['accountNumber'] as String,
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      amountDue: (json['amountDue'] as num).toDouble(),
      autopay: json['autopay'] as bool? ?? false,
      category: json['category'] as String,
      logo: json['logo'] as String?,
    );
  }

  bool get isDueSoon {
    final now = DateTime.now();
    final diff = nextDueDate.difference(now).inDays;
    return diff <= 7 && diff >= 0;
  }

  bool get isOverdue {
    return nextDueDate.isBefore(DateTime.now());
  }

  String get formattedDueDate {
    return '${nextDueDate.month}/${nextDueDate.day}/${nextDueDate.year}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        accountNumber,
        nextDueDate,
        amountDue,
        autopay,
        category,
        logo,
      ];
}

/// Bill payment request
class BillPaymentRequest extends Equatable {
  final String billerId;
  final double amount;
  final DateTime scheduledDate;
  final String? fromAccountId;

  const BillPaymentRequest({
    required this.billerId,
    required this.amount,
    required this.scheduledDate,
    this.fromAccountId,
  });

  Map<String, dynamic> toJson() {
    return {
      'billerId': billerId,
      'amount': amount,
      'scheduledDate': scheduledDate.toIso8601String(),
      if (fromAccountId != null) 'fromAccountId': fromAccountId,
    };
  }

  @override
  List<Object?> get props => [billerId, amount, scheduledDate, fromAccountId];
}
