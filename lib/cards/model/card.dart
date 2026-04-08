import 'package:equatable/equatable.dart';

/// Card types
enum CardType {
  debit,
  credit,
}

/// Card networks
enum CardNetwork {
  visa,
  mastercard,
  amex,
  discover,
}

/// Card status
enum CardStatus {
  active,
  frozen,
  expired,
  cancelled,
}

/// Bank card model
class BankCard extends Equatable {
  final String id;
  final CardType type;
  final CardNetwork network;
  final String lastFour;
  final String cardholderName;
  final String expirationDate;
  final CardStatus status;
  final String? linkedAccountId;
  final bool isVirtual;
  final double? dailyLimit;
  final double? monthlyLimit;
  final double? creditLimit;
  final double? availableCredit;
  final double? currentBalance;

  const BankCard({
    required this.id,
    required this.type,
    required this.network,
    required this.lastFour,
    required this.cardholderName,
    required this.expirationDate,
    required this.status,
    this.linkedAccountId,
    this.isVirtual = false,
    this.dailyLimit,
    this.monthlyLimit,
    this.creditLimit,
    this.availableCredit,
    this.currentBalance,
  });

  factory BankCard.fromJson(Map<String, dynamic> json) {
    return BankCard(
      id: json['id'] as String,
      type: (json['type'] as String).toLowerCase() == 'credit'
          ? CardType.credit
          : CardType.debit,
      network: _parseNetwork(json['network'] as String),
      lastFour: json['lastFour'] as String,
      cardholderName: json['cardholderName'] as String,
      expirationDate: json['expirationDate'] as String,
      status: _parseStatus(json['status'] as String),
      linkedAccountId: json['linkedAccountId'] as String?,
      isVirtual: json['isVirtual'] as bool? ?? false,
      dailyLimit: (json['dailyLimit'] as num?)?.toDouble(),
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble(),
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      availableCredit: (json['availableCredit'] as num?)?.toDouble(),
      currentBalance: (json['currentBalance'] as num?)?.toDouble(),
    );
  }

  static CardNetwork _parseNetwork(String network) {
    switch (network.toLowerCase()) {
      case 'visa':
        return CardNetwork.visa;
      case 'mastercard':
        return CardNetwork.mastercard;
      case 'amex':
        return CardNetwork.amex;
      case 'discover':
        return CardNetwork.discover;
      default:
        return CardNetwork.visa;
    }
  }

  static CardStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return CardStatus.active;
      case 'frozen':
        return CardStatus.frozen;
      case 'expired':
        return CardStatus.expired;
      case 'cancelled':
        return CardStatus.cancelled;
      default:
        return CardStatus.active;
    }
  }

  bool get isActive => status == CardStatus.active;
  bool get isFrozen => status == CardStatus.frozen;
  bool get isCredit => type == CardType.credit;
  bool get isDebit => type == CardType.debit;

  String get maskedNumber => '**** **** **** $lastFour';

  String get networkDisplayName {
    switch (network) {
      case CardNetwork.visa:
        return 'Visa';
      case CardNetwork.mastercard:
        return 'Mastercard';
      case CardNetwork.amex:
        return 'American Express';
      case CardNetwork.discover:
        return 'Discover';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CardStatus.active:
        return 'Active';
      case CardStatus.frozen:
        return 'Frozen';
      case CardStatus.expired:
        return 'Expired';
      case CardStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        network,
        lastFour,
        cardholderName,
        expirationDate,
        status,
        linkedAccountId,
        isVirtual,
        dailyLimit,
        monthlyLimit,
        creditLimit,
        availableCredit,
        currentBalance,
      ];
}

/// Revealed card details
class CardDetails extends Equatable {
  final String cardNumber;
  final String cvv;
  final String expirationDate;
  final int expiresInSeconds;

  const CardDetails({
    required this.cardNumber,
    required this.cvv,
    required this.expirationDate,
    required this.expiresInSeconds,
  });

  factory CardDetails.fromJson(Map<String, dynamic> json) {
    return CardDetails(
      cardNumber: json['cardNumber'] as String,
      cvv: json['cvv'] as String,
      expirationDate: json['expirationDate'] as String,
      expiresInSeconds: json['expiresIn'] as int? ?? 60,
    );
  }

  @override
  List<Object?> get props => [cardNumber, cvv, expirationDate, expiresInSeconds];
}
