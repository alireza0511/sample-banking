import '../routing/routes.dart';

/// Routes that handle credentials, money movement, card data, or anything
/// else that an overlay-tapjacking attacker would target.
///
/// Both **path prefixes** and **go_router names** are matched, because
/// `Route.settings.name` may carry either depending on go_router's internals
/// for a given page (`builder:` vs `pageBuilder:`, `name:` set on the route,
/// etc.). Matching on both keeps the observer robust to those variations.
class SensitiveRoutes {
  SensitiveRoutes._();

  /// Path prefixes (e.g. `/transfer` matches `/transfer/confirm`).
  static const Set<String> pathPrefixes = {
    Routes.login,
    Routes.transfer,
    Routes.cards,
    Routes.payBills,
    Routes.balance,
    Routes.settingsPrivacy,
  };

  /// go_router route names — kept in sync with `app_router.dart`.
  static const Set<String> names = {
    'login',
    'transfer',
    'transferConfirm',
    'cards',
    'cardDetail',
    'payBills',
    'balance',
    'settingsPrivacy',
  };

  /// True if [identifier] (a path like `/transfer/confirm` or a route name like
  /// `transferConfirm`) should engage the fraud-protection overlay guard.
  static bool matches(String? identifier) {
    if (identifier == null || identifier.isEmpty) return false;
    if (names.contains(identifier)) return true;
    for (final prefix in pathPrefixes) {
      if (identifier == prefix || identifier.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }
}
