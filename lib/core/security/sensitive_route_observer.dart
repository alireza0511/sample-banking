import 'package:flutter/widgets.dart';

import 'fraud_protection_service.dart';
import 'sensitive_routes.dart';

/// [NavigatorObserver] that engages [FraudProtectionService] when a sensitive
/// route is pushed/replaced onto the stack and disengages when it leaves.
///
/// We track per-route engagement in [_engagedRoutes] so the same Route is
/// never double-counted (e.g. when `didReplace` fires).
class SensitiveRouteObserver extends NavigatorObserver {
  final Set<Route<dynamic>> _engagedRoutes = <Route<dynamic>>{};

  bool _isSensitive(Route<dynamic>? route) {
    return SensitiveRoutes.matches(route?.settings.name);
  }

  void _engage(Route<dynamic> route) {
    if (_engagedRoutes.add(route)) {
      FraudProtectionService.instance.engage();
    }
  }

  void _disengage(Route<dynamic> route) {
    if (_engagedRoutes.remove(route)) {
      FraudProtectionService.instance.disengage();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isSensitive(route)) _engage(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _disengage(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _disengage(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _disengage(oldRoute);
    if (newRoute != null && _isSensitive(newRoute)) _engage(newRoute);
  }
}
