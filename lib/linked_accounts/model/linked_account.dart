import 'package:equatable/equatable.dart';

/// An external bank account linked through Plaid
class LinkedAccount extends Equatable {
  final String id;
  final String institution;
  final String name;
  final String mask; // Last 4 digits only
  final String type;
  final double? balance;
  final String currency;

  const LinkedAccount({
    required this.id,
    required this.institution,
    required this.name,
    required this.mask,
    required this.type,
    this.balance,
    this.currency = 'USD',
  });

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      id: json['id'] as String,
      institution: json['institution'] as String? ?? '',
      name: json['name'] as String,
      mask: json['mask'] as String? ?? '',
      type: json['type'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  static List<LinkedAccount> listFromJson(Map<String, dynamic> json) {
    return (json['accounts'] as List)
        .map((e) => LinkedAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<Object?> get props =>
      [id, institution, name, mask, type, balance, currency];
}
