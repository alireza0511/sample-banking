import 'package:equatable/equatable.dart';

/// Account types
enum AccountType {
  checking,
  savings,
  investment,
  loan,
}

/// Account model representing a bank account
class Account extends Equatable {
  final String id;
  final AccountType type;
  final String name;
  final String accountNumber; // Masked: ****1234
  final double balance;
  final double availableBalance;
  final String currency;
  final bool isPrimary;

  const Account({
    required this.id,
    required this.type,
    required this.name,
    required this.accountNumber,
    required this.balance,
    required this.availableBalance,
    this.currency = 'USD',
    this.isPrimary = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      type: _parseAccountType(json['type'] as String),
      name: json['name'] as String,
      accountNumber: json['accountNumber'] as String,
      balance: (json['balance'] as num).toDouble(),
      availableBalance: (json['availableBalance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'accountNumber': accountNumber,
      'balance': balance,
      'availableBalance': availableBalance,
      'currency': currency,
      'isPrimary': isPrimary,
    };
  }

  static AccountType _parseAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'checking':
        return AccountType.checking;
      case 'savings':
        return AccountType.savings;
      case 'investment':
        return AccountType.investment;
      case 'loan':
        return AccountType.loan;
      default:
        return AccountType.checking;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case AccountType.checking:
        return 'Checking';
      case AccountType.savings:
        return 'Savings';
      case AccountType.investment:
        return 'Investment';
      case AccountType.loan:
        return 'Loan';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        accountNumber,
        balance,
        availableBalance,
        currency,
        isPrimary,
      ];
}

/// Response model for accounts list API
class AccountsResponse extends Equatable {
  final List<Account> accounts;
  final double totalBalance;
  final double netWealth;

  const AccountsResponse({
    required this.accounts,
    required this.totalBalance,
    required this.netWealth,
  });

  factory AccountsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final accountsList = (data['accounts'] as List)
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();

    return AccountsResponse(
      accounts: accountsList,
      totalBalance: (data['totalBalance'] as num).toDouble(),
      netWealth: (data['netWealth'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [accounts, totalBalance, netWealth];
}
