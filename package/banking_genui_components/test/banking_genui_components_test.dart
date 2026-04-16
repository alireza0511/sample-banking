import 'package:flutter_test/flutter_test.dart';
import 'package:banking_genui_components/banking_genui_components.dart';

void main() {
  group('BankingCatalog', () {
    test('has all required catalog items', () {
      final items = BankingCatalog.items;
      expect(items.length, 4);
      expect(items.map((i) => i.name), containsAll([
        'AccountSummary',
        'QuickTransfer',
        'TransactionItem',
        'TransactionList',
      ]));
    });

    test('asCatalog returns combined catalog with core items', () {
      final catalog = BankingCatalog.asCatalog();
      expect(catalog, isNotNull);
    });
  });

  group('TransactionData', () {
    test('creates transaction data correctly', () {
      final transaction = TransactionData(
        id: 'txn_001',
        merchant: 'Coffee Shop',
        amount: -4.50,
        date: DateTime(2024, 1, 15),
        category: 'food',
      );

      expect(transaction.id, 'txn_001');
      expect(transaction.merchant, 'Coffee Shop');
      expect(transaction.amount, -4.50);
      expect(transaction.category, 'food');
      expect(transaction.isPending, false);
    });
  });
}
