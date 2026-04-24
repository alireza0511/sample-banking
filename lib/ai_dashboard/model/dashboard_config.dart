/// Configuration and prompts for the AI Dashboard feature
class DashboardConfig {
  DashboardConfig._();

  /// System prompt for dashboard generation
  static const String systemPrompt = '''
You are a banking assistant that generates personalized dashboard interfaces using GenUI components.

Available components:
- AccountSummary: Display account with accountName, balance, accountType ("checking", "savings", "investment", "credit", "loan"), accountNumber (masked), hideBalance
- QuickTransfer: Transfer form with fromAccount, toAccount, initialAmount, memo
- TransactionItem: Single transaction with merchant, amount (negative for debits), date (ISO 8601), category, isPending
- TransactionList: List with header and transactions array
- Row/Column: Layout containers with mainAxisAlignment, crossAxisAlignment
- Card: Container with elevation, borderRadius, padding, margin
- Heading: Header text with text, level (1-6)
- Label: Text with text, style, color, textAlign
- ActionButton: Button with label, action, variant ("filled", "outlined", "text"), icon
- Divider: Separator with height, thickness, indent
- Padding: Space around child with all, horizontal, vertical, left, top, right, bottom
- Spacer: Flexible space with flex

Respond ONLY with valid JSON matching this structure:
{
  "type": "ComponentName",
  "data": { ...properties },
  "children": [ ...nested components ]
}
''';

  /// Prompt template for generating personalized dashboard
  static String buildDashboardPrompt({
    required String userName,
    required double totalBalance,
    required List<AccountInfo> accounts,
    required List<TransactionInfo> recentTransactions,
  }) {
    final accountsList = accounts
        .map((a) =>
            '- ${a.name} (${a.type}): \$${a.balance.toStringAsFixed(2)}')
        .join('\n');

    final transactionsList = recentTransactions
        .map((t) =>
            '- ${t.merchant}: \$${t.amount.toStringAsFixed(2)} on ${t.date}')
        .join('\n');

    return '''
Generate a personalized banking dashboard for $userName.

User context:
- Total balance: \$${totalBalance.toStringAsFixed(2)}
- Accounts:
$accountsList

- Recent transactions:
$transactionsList

Create a dashboard layout with:
1. A greeting heading
2. Account summary cards (top accounts)
3. Quick actions section
4. Recent transactions list

Use Card containers for grouping, proper spacing, and make it visually appealing.
''';
  }

  /// Default dashboard JSON when LLM is unavailable or for demo
  static Map<String, Object?> get defaultDashboard => {
        'type': 'Column',
        'data': {
          'crossAxisAlignment': 'stretch',
        },
        'children': [
          {
            'type': 'Padding',
            'data': {'all': 16},
            'children': [
              {
                'type': 'Heading',
                'data': {
                  'text': 'Welcome back!',
                  'level': 2,
                },
              },
            ],
          },
          {
            'type': 'AccountSummary',
            'data': {
              'accountName': 'Primary Checking',
              'balance': 12450.00,
              'accountType': 'checking',
              'accountNumber': '****1234',
            },
          },
          {
            'type': 'AccountSummary',
            'data': {
              'accountName': 'Savings',
              'balance': 32750.00,
              'accountType': 'savings',
              'accountNumber': '****5678',
            },
          },
          {
            'type': 'Padding',
            'data': {'horizontal': 16, 'vertical': 8},
            'children': [
              {
                'type': 'Row',
                'data': {'mainAxisAlignment': 'spaceEvenly'},
                'children': [
                  {
                    'type': 'ActionButton',
                    'data': {
                      'label': 'Transfer',
                      'action': 'navigate_transfer',
                      'variant': 'filled',
                      'icon': 'swap_horiz',
                    },
                  },
                  {
                    'type': 'ActionButton',
                    'data': {
                      'label': 'Pay Bills',
                      'action': 'navigate_bills',
                      'variant': 'outlined',
                      'icon': 'payment',
                    },
                  },
                ],
              },
            ],
          },
          {
            'type': 'TransactionList',
            'data': {
              'header': 'Recent Transactions',
              'transactions': [
                {
                  'id': 'txn1',
                  'merchant': 'Whole Foods Market',
                  'amount': -87.32,
                  'date': DateTime.now()
                      .subtract(const Duration(days: 1))
                      .toIso8601String(),
                  'category': 'groceries',
                },
                {
                  'id': 'txn2',
                  'merchant': 'Netflix',
                  'amount': -15.99,
                  'date': DateTime.now()
                      .subtract(const Duration(days: 2))
                      .toIso8601String(),
                  'category': 'subscription',
                },
                {
                  'id': 'txn3',
                  'merchant': 'Direct Deposit - Payroll',
                  'amount': 3250.00,
                  'date': DateTime.now()
                      .subtract(const Duration(days: 3))
                      .toIso8601String(),
                  'category': 'income',
                },
              ],
            },
          },
        ],
      };
}

/// Account information for prompt generation
class AccountInfo {
  final String name;
  final String type;
  final double balance;

  const AccountInfo({
    required this.name,
    required this.type,
    required this.balance,
  });
}

/// Transaction information for prompt generation
class TransactionInfo {
  final String merchant;
  final double amount;
  final String date;

  const TransactionInfo({
    required this.merchant,
    required this.amount,
    required this.date,
  });
}
