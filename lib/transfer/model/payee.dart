import 'package:equatable/equatable.dart';

/// Payee types
enum PayeeType {
  zelle,
  ach,
  wire,
  internal,
}

/// Payee model representing a transfer recipient
class Payee extends Equatable {
  final String id;
  final String name;
  final PayeeType type;
  final String identifier; // Email, phone, or account number
  final bool isFavorite;

  const Payee({
    required this.id,
    required this.name,
    required this.type,
    required this.identifier,
    this.isFavorite = false,
  });

  factory Payee.fromJson(Map<String, dynamic> json) {
    return Payee(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parsePayeeType(json['type'] as String),
      identifier: json['identifier'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  static PayeeType _parsePayeeType(String type) {
    switch (type.toLowerCase()) {
      case 'zelle':
        return PayeeType.zelle;
      case 'ach':
        return PayeeType.ach;
      case 'wire':
        return PayeeType.wire;
      case 'internal':
        return PayeeType.internal;
      default:
        return PayeeType.zelle;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case PayeeType.zelle:
        return 'Zelle';
      case PayeeType.ach:
        return 'ACH';
      case PayeeType.wire:
        return 'Wire';
      case PayeeType.internal:
        return 'Internal';
    }
  }

  /// Get masked identifier for display
  String get maskedIdentifier {
    if (identifier.contains('@')) {
      // Email: show first 2 chars + *** + domain
      final parts = identifier.split('@');
      if (parts[0].length > 2) {
        return '${parts[0].substring(0, 2)}***@${parts[1]}';
      }
      return identifier;
    } else if (identifier.startsWith('+')) {
      // Phone: show last 4 digits
      if (identifier.length > 4) {
        return '***${identifier.substring(identifier.length - 4)}';
      }
      return identifier;
    }
    return identifier;
  }

  @override
  List<Object?> get props => [id, name, type, identifier, isFavorite];
}

/// Transfer request model
class TransferRequest extends Equatable {
  final String fromAccountId;
  final String toPayeeId;
  final double amount;
  final String? memo;
  final DateTime? scheduledDate;

  const TransferRequest({
    required this.fromAccountId,
    required this.toPayeeId,
    required this.amount,
    this.memo,
    this.scheduledDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromAccount': fromAccountId,
      'toAccount': toPayeeId,
      'amount': amount,
      if (memo != null) 'memo': memo,
      if (scheduledDate != null) 'scheduledDate': scheduledDate!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [fromAccountId, toPayeeId, amount, memo, scheduledDate];
}

/// Transfer response model
class TransferResponse extends Equatable {
  final String transferId;
  final String status;
  final DateTime? estimatedArrival;
  final String? confirmationNumber;

  const TransferResponse({
    required this.transferId,
    required this.status,
    this.estimatedArrival,
    this.confirmationNumber,
  });

  factory TransferResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TransferResponse(
      transferId: data['transferId'] as String,
      status: data['status'] as String,
      estimatedArrival: data['estimatedArrival'] != null
          ? DateTime.tryParse(data['estimatedArrival'] as String)
          : null,
      confirmationNumber: data['confirmationNumber'] as String?,
    );
  }

  @override
  List<Object?> get props => [transferId, status, estimatedArrival, confirmationNumber];
}
