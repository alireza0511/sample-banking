import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import 'deep_link_handler.dart';
import '../security/sensitive_route_observer.dart';
import '../../ai_dashboard/ui/ai_dashboard_screen.dart';
import '../../auth/ui/login_screen.dart';
import '../../balance/ui/balance_screen.dart';
import '../../bills/ui/bills_screen.dart';
import '../../cards/ui/cards_screen.dart';
import '../../chat/ui/chat_feature_widget.dart';
import '../../transactions/ui/transactions_screen.dart';
import '../../transfer/ui/transfer_screen.dart';
import '../../hub/ui/simple_hub_screen.dart';
import '../../dev/deep_link_test_screen.dart';
import '../../dev/llm_status_screen.dart';

/// App router configuration using go_router
/// Handles navigation, deep links, and auth redirects
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Auth state notifier for redirect logic
  static final ValueNotifier<bool> _isAuthenticated = ValueNotifier(false);

  /// Set authentication state
  static void setAuthenticated(bool value) {
    _isAuthenticated.value = value;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => _isAuthenticated.value;

  /// Pending redirect after login
  static String? _pendingRedirect;

  /// Set pending redirect (called when deep link requires auth)
  static void setPendingRedirect(String? location) {
    _pendingRedirect = location;
  }

  /// Get and clear pending redirect
  static String? consumePendingRedirect() {
    final redirect = _pendingRedirect;
    _pendingRedirect = null;
    return redirect;
  }

  /// The main router instance
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.hub,
    debugLogDiagnostics: true,
    refreshListenable: _isAuthenticated,

    // Engage fraud-protection overlay guard automatically whenever a
    // sensitive route (login, transfer, cards, …) is on top of the stack.
    observers: [SensitiveRouteObserver()],

    // Redirect logic for auth
    redirect: (context, state) {
      final isLoggedIn = _isAuthenticated.value;
      final isLoginRoute = state.matchedLocation == Routes.login;

      // Parse deep link to check if auth is required
      final deepLinkResult = DeepLinkHandler.parse(state.uri);

      // If not logged in and trying to access protected route
      if (!isLoggedIn && deepLinkResult.requiresAuth) {
        // Store the intended destination
        _pendingRedirect = state.matchedLocation;
        // Redirect to login with redirect parameter
        return '${Routes.login}?${RouteParams.redirect}=${Uri.encodeComponent(state.matchedLocation)}';
      }

      // If logged in and on login page, redirect to hub or pending redirect
      if (isLoggedIn && isLoginRoute) {
        final redirect = consumePendingRedirect();
        return redirect ?? Routes.hub;
      }

      // No redirect needed
      return null;
    },

    // Route definitions
    routes: [
      // Login route
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) {
          final redirect = state.uri.queryParameters[RouteParams.redirect];
          return LoginScreen(redirectTo: redirect);
        },
      ),

      // Hub (main screen) - using SimpleHubScreen until dynamic hub is developed
      GoRoute(
        path: Routes.hub,
        name: 'hub',
        builder: (context, state) => const SimpleHubScreen(),
      ),

      // Balance screen
      GoRoute(
        path: Routes.balance,
        name: 'balance',
        builder: (context, state) {
          final accountId = state.uri.queryParameters[RouteParams.accountId];
          return BalanceScreen(initialAccountId: accountId);
        },
      ),

      // Transfer screen
      GoRoute(
        path: Routes.transfer,
        name: 'transfer',
        builder: (context, state) {
          final to = state.uri.queryParameters[RouteParams.to];
          final amount = state.uri.queryParameters[RouteParams.amount];
          return TransferScreen(
            initialRecipient: to,
            initialAmount: amount,
          );
        },
        routes: [
          GoRoute(
            path: 'confirm',
            name: 'transferConfirm',
            builder: (context, state) {
              final transferId =
                  state.uri.queryParameters[RouteParams.transferId];
              return _PlaceholderScreen(
                title: 'Confirm Transfer',
                params: {'transferId': transferId},
              );
            },
          ),
        ],
      ),

      // Transactions screen
      GoRoute(
        path: Routes.transactions,
        name: 'transactions',
        builder: (context, state) {
          final accountId = state.uri.queryParameters[RouteParams.accountId];
          final filter = state.uri.queryParameters[RouteParams.filter];
          return TransactionsScreen(
            accountId: accountId,
            filter: filter,
          );
        },
      ),

      // Transaction detail (parameterized route)
      GoRoute(
        path: '/transactions/:id',
        name: 'transactionDetail',
        builder: (context, state) {
          final id = state.pathParameters[RouteParams.id];
          return _PlaceholderScreen(
            title: 'Transaction Detail',
            params: {'id': id},
          );
        },
      ),

      // Pay bills screen
      GoRoute(
        path: Routes.payBills,
        name: 'payBills',
        builder: (context, state) {
          final billerId = state.uri.queryParameters[RouteParams.billerId];
          final amount = state.uri.queryParameters[RouteParams.amount];
          return BillsScreen(
            initialBillerId: billerId,
            initialAmount: amount,
          );
        },
      ),

      // Cards screen
      GoRoute(
        path: Routes.cards,
        name: 'cards',
        builder: (context, state) => const CardsScreen(),
      ),

      // Card detail (parameterized route)
      GoRoute(
        path: '/cards/:id',
        name: 'cardDetail',
        builder: (context, state) {
          final id = state.pathParameters[RouteParams.id];
          final action = state.uri.queryParameters[RouteParams.action];
          return _PlaceholderScreen(
            title: 'Card Detail',
            params: {'id': id, 'action': action},
          );
        },
      ),

      // Chat screen
      GoRoute(
        path: Routes.chat,
        name: 'chat',
        builder: (context, state) {
          final prompt = state.uri.queryParameters[RouteParams.prompt];
          return ChatFeatureWidget(initialPrompt: prompt);
        },
      ),

      // AI Dashboard screen
      GoRoute(
        path: Routes.aiDashboard,
        name: 'aiDashboard',
        builder: (context, state) => const AiDashboardScreen(),
      ),

      // Settings screen
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) {
          final section = state.uri.queryParameters[RouteParams.section];
          return _PlaceholderScreen(
            title: 'Settings',
            params: {'section': section},
          );
        },
        routes: [
          GoRoute(
            path: 'privacy',
            name: 'settingsPrivacy',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Privacy Settings'),
          ),
        ],
      ),

      // Dev routes (debug mode only)
      if (kDebugMode) ...[
        GoRoute(
          path: Routes.devDeepLinkTest,
          name: 'devDeepLinkTest',
          builder: (context, state) => const DeepLinkTestScreen(),
        ),
        GoRoute(
          path: Routes.devLlmStatus,
          name: 'devLlmStatus',
          builder: (context, state) => const LlmStatusScreen(),
        ),
      ],
    ],

    // Error handling
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final Map<String, String?>? params;

  const _PlaceholderScreen({
    required this.title,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('Screen coming soon...'),
            if (params != null && params!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Parameters:'),
              ...params!.entries
                  .where((e) => e.value != null)
                  .map((e) => Text('${e.key}: ${e.value}')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error screen for invalid routes
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.hub),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
