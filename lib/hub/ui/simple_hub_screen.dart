import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/routing/routes.dart';

/// Simple Hub Screen - temporary hub until dynamic hub is developed
/// Shows net wealth, customizable quick actions, and chat bar
class SimpleHubScreen extends StatefulWidget {
  const SimpleHubScreen({super.key});

  @override
  State<SimpleHubScreen> createState() => _SimpleHubScreenState();
}

class _SimpleHubScreenState extends State<SimpleHubScreen> {
  // Default selected actions - showing key banking features
  List<String> selectedActions = [
    'Accounts',
    'Transfer',
    'Pay Bills',
    'Cards',
    'Transactions',
  ];

  // All available actions
  final List<String> allActions = [
    'Accounts',
    'Transfer',
    'Pay Bills',
    'Cards',
    'Transactions',
    'Zelle',
    'Loan Access',
    'Check Deposit',
    'Notification Alert',
    'More',
    'Profile',
  ];

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _EditActionsModal(
        allActions: allActions,
        selectedActions: selectedActions,
        onSelectionChanged: (newSelection) {
          setState(() {
            selectedActions = newSelection;
          });
        },
      ),
    );
  }

  void _showChatModal() {
    context.push(Routes.chat);
  }

  void _handleActionTap(String action) {
    final lowerAction = action.toLowerCase();

    if (lowerAction.contains('account') || lowerAction.contains('balance')) {
      context.push(Routes.balance);
    } else if (lowerAction.contains('transaction')) {
      context.push(Routes.transactions);
    } else if (lowerAction.contains('zelle') || lowerAction.contains('transfer')) {
      context.push(Routes.transfer);
    } else if (lowerAction.contains('pay') || lowerAction.contains('bill')) {
      context.push(Routes.payBills);
    } else if (lowerAction.contains('card')) {
      context.push(Routes.cards);
    } else if (lowerAction.contains('profile') || lowerAction.contains('setting')) {
      context.push(Routes.settings);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action - Coming soon!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRouter.setAuthenticated(false);
              context.go(Routes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () => context.push(Routes.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Net Wealth Section
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'NET WEALTH',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$45,200',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions Header with Edit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: _showEditModal,
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Tiles
                  ...selectedActions.map(
                    (action) => _ActionTile(
                      title: action,
                      onTap: () => _handleActionTap(action),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat Section at Bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How can I assist you?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showChatModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Type a message...',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                          Icon(Icons.mic, color: Colors.grey[500], size: 20),
                          const SizedBox(width: 8),
                          Icon(Icons.send, color: Colors.grey[500], size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action tile widget
class _ActionTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForAction(title),
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForAction(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('account') || lowerAction.contains('balance')) {
      return Icons.account_balance_wallet;
    } else if (lowerAction.contains('transaction')) {
      return Icons.receipt_long;
    } else if (lowerAction.contains('transfer')) {
      return Icons.swap_horiz;
    } else if (lowerAction.contains('zelle')) {
      return Icons.send_rounded;
    } else if (lowerAction.contains('pay') || lowerAction.contains('bill')) {
      return Icons.payment;
    } else if (lowerAction.contains('card')) {
      return Icons.credit_card;
    } else if (lowerAction.contains('loan')) {
      return Icons.account_balance;
    } else if (lowerAction.contains('deposit') || lowerAction.contains('check')) {
      return Icons.camera_alt;
    } else if (lowerAction.contains('notification') || lowerAction.contains('alert')) {
      return Icons.notifications;
    } else if (lowerAction.contains('more')) {
      return Icons.more_horiz;
    } else if (lowerAction.contains('profile') || lowerAction.contains('setting')) {
      return Icons.person;
    }
    return Icons.circle;
  }
}

/// Edit actions modal
class _EditActionsModal extends StatefulWidget {
  final List<String> allActions;
  final List<String> selectedActions;
  final Function(List<String>) onSelectionChanged;

  const _EditActionsModal({
    required this.allActions,
    required this.selectedActions,
    required this.onSelectionChanged,
  });

  @override
  State<_EditActionsModal> createState() => _EditActionsModalState();
}

class _EditActionsModalState extends State<_EditActionsModal> {
  late List<String> tempSelection;

  @override
  void initState() {
    super.initState();
    tempSelection = List.from(widget.selectedActions);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onSelectionChanged(tempSelection);
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.allActions.length,
                  itemBuilder: (context, index) {
                    final action = widget.allActions[index];
                    final isSelected = tempSelection.contains(action);

                    return CheckboxListTile(
                      title: Text(action),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (!tempSelection.contains(action)) {
                              tempSelection.add(action);
                            }
                          } else {
                            tempSelection.remove(action);
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
