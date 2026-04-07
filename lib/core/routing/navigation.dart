import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'deep_link_handler.dart';
import 'routes.dart';

/// Navigation helper that uses the deep link system for consistency
/// All in-app navigation goes through this class to ensure:
/// - Consistent routing behavior
/// - Parameter validation
/// - Deep link compatibility (Siri can use same routes)
class AppNavigation {
  AppNavigation._();

  /// Navigate to a route using the deep link system
  /// This ensures in-app navigation matches external deep link behavior
  static void navigateTo(
    BuildContext context,
    String path, {
    Map<String, String>? params,
    bool replace = false,
  }) {
    // Build location with validated params
    final location = _buildLocation(path, params);

    if (replace) {
      context.go(location);
    } else {
      context.push(location);
    }
  }

  /// Navigate using a deep link URI (for consistency with external links)
  static void navigateToUri(BuildContext context, Uri uri, {bool replace = false}) {
    final result = DeepLinkHandler.parse(uri);
    if (replace) {
      context.go(result.location);
    } else {
      context.push(result.location);
    }
  }

  // ============================================
  // Convenience methods for common destinations
  // ============================================

  /// Navigate to hub
  static void toHub(BuildContext context) {
    context.go(Routes.hub);
  }

  /// Navigate to balance screen
  static void toBalance(BuildContext context, {String? accountId}) {
    navigateTo(
      context,
      Routes.balance,
      params: accountId != null ? {RouteParams.accountId: accountId} : null,
    );
  }

  /// Navigate to transfer screen with optional pre-fill
  static void toTransfer(
    BuildContext context, {
    String? recipient,
    String? amount,
    String? accountId,
  }) {
    final params = <String, String>{};
    if (recipient != null) params[RouteParams.to] = recipient;
    if (amount != null) params[RouteParams.amount] = amount;
    if (accountId != null) params[RouteParams.accountId] = accountId;

    navigateTo(
      context,
      Routes.transfer,
      params: params.isNotEmpty ? params : null,
    );
  }

  /// Navigate to pay bills screen with optional pre-fill
  static void toPayBills(
    BuildContext context, {
    String? billerId,
    String? amount,
  }) {
    final params = <String, String>{};
    if (billerId != null) params[RouteParams.billerId] = billerId;
    if (amount != null) params[RouteParams.amount] = amount;

    navigateTo(
      context,
      Routes.payBills,
      params: params.isNotEmpty ? params : null,
    );
  }

  /// Navigate to transactions screen
  static void toTransactions(BuildContext context, {String? accountId, String? filter}) {
    final params = <String, String>{};
    if (accountId != null) params[RouteParams.accountId] = accountId;
    if (filter != null) params[RouteParams.filter] = filter;

    navigateTo(
      context,
      Routes.transactions,
      params: params.isNotEmpty ? params : null,
    );
  }

  /// Navigate to cards screen
  static void toCards(BuildContext context) {
    navigateTo(context, Routes.cards);
  }

  /// Navigate to chat screen with optional prompt
  static void toChat(BuildContext context, {String? prompt}) {
    navigateTo(
      context,
      Routes.chat,
      params: prompt != null ? {RouteParams.prompt: prompt} : null,
    );
  }

  /// Navigate to settings screen
  static void toSettings(BuildContext context, {String? section}) {
    navigateTo(
      context,
      Routes.settings,
      params: section != null ? {RouteParams.section: section} : null,
    );
  }

  /// Navigate to login
  static void toLogin(BuildContext context, {String? redirectTo}) {
    final params = redirectTo != null ? {RouteParams.redirect: redirectTo} : null;
    context.go(_buildLocation(Routes.login, params));
  }

  /// Log out and return to login
  static void logout(BuildContext context) {
    AppRouter.setAuthenticated(false);
    context.go(Routes.login);
  }

  // ============================================
  // Internal helpers
  // ============================================

  static String _buildLocation(String path, Map<String, String>? params) {
    if (params == null || params.isEmpty) return path;
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$path?$query';
  }
}

/// Extension on BuildContext for easy navigation
extension NavigationExtensions on BuildContext {
  /// Navigate using AppNavigation
  void navigateTo(String path, {Map<String, String>? params, bool replace = false}) {
    AppNavigation.navigateTo(this, path, params: params, replace: replace);
  }

  /// Quick access to common destinations
  void goToHub() => AppNavigation.toHub(this);
  void goToBalance({String? accountId}) => AppNavigation.toBalance(this, accountId: accountId);
  void goToTransfer({String? recipient, String? amount}) =>
      AppNavigation.toTransfer(this, recipient: recipient, amount: amount);
  void goToPayBills({String? billerId, String? amount}) =>
      AppNavigation.toPayBills(this, billerId: billerId, amount: amount);
  void goToTransactions({String? accountId}) =>
      AppNavigation.toTransactions(this, accountId: accountId);
  void goToCards() => AppNavigation.toCards(this);
  void goToChat({String? prompt}) => AppNavigation.toChat(this, prompt: prompt);
  void goToSettings() => AppNavigation.toSettings(this);
}
