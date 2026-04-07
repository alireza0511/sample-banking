import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/app_router.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/action_tile.dart';
import 'widgets/edit_actions_modal.dart';

/// Main hub screen - the application's central navigation point
/// Simple design with net wealth, customizable quick actions, and chat bar
class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  // Default selected actions
  List<String> selectedActions = [
    'Checking Account ***1234\n\$14,250.50',
    'Zelle',
    'Transfer',
    'Check Deposit',
  ];

  // All available actions
  final List<String> allActions = [
    'Checking Account ***1234\n\$14,250.50',
    'Zelle',
    'Transfer',
    'Loan Access',
    'Check Deposit',
    'Pay Bills',
    'Cards',
    'Notification Alert',
    'More',
    'Profile',
  ];

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => EditActionsModal(
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
    // Navigate to chat screen
    context.push(Routes.chat);
  }

  void _handleActionTap(String action) {
    final lowerAction = action.toLowerCase();

    if (lowerAction.contains('checking') || lowerAction.contains('account')) {
      context.push(Routes.balance);
    } else if (lowerAction.contains('zelle') || lowerAction.contains('transfer')) {
      context.push(Routes.transfer);
    } else if (lowerAction.contains('pay') || lowerAction.contains('bill')) {
      context.push(Routes.payBills);
    } else if (lowerAction.contains('card')) {
      context.push(Routes.cards);
    } else if (lowerAction.contains('profile')) {
      context.push(Routes.settings);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tapped: $action')),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
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
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '\$45,200',
                          style:
                              Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick Actions Header
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
                  const SizedBox(height: AppSpacing.md),

                  // Action Tiles
                  ...selectedActions.map(
                    (action) => ActionTile(
                      title: action,
                      onTap: () => _handleActionTap(action),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat Section at Bottom
          _ChatBar(onTap: _showChatModal),
        ],
      ),
    );
  }
}

/// Chat bar widget at the bottom of the hub
class _ChatBar extends StatelessWidget {
  final VoidCallback onTap;

  const _ChatBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
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
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Type a message...',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                    Icon(Icons.mic, color: AppColors.textTertiary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.send, color: AppColors.textTertiary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
