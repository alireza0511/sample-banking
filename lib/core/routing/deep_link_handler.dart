import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'routes.dart';

/// Configuration for a deep link route
class DeepLinkConfig {
  final bool requiresAuth;
  final List<String> params;

  const DeepLinkConfig({
    required this.requiresAuth,
    this.params = const [],
  });
}

/// Handles deep link parsing, validation, and routing
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Supported routes with their configurations
  static const Map<String, DeepLinkConfig> _routes = {
    '/hub': DeepLinkConfig(requiresAuth: true),
    '/balance': DeepLinkConfig(
      requiresAuth: true,
      params: [RouteParams.accountId],
    ),
    '/transfer': DeepLinkConfig(
      requiresAuth: true,
      params: [RouteParams.to, RouteParams.amount, RouteParams.accountId],
    ),
    '/transfer/confirm': DeepLinkConfig(
      requiresAuth: true,
      params: [RouteParams.transferId],
    ),
    '/pay-bills': DeepLinkConfig(
      requiresAuth: true,
      params: [RouteParams.billerId, RouteParams.amount],
    ),
    '/transactions': DeepLinkConfig(
      requiresAuth: true,
      params: [RouteParams.accountId, RouteParams.filter],
    ),
    '/cards': DeepLinkConfig(requiresAuth: true),
    '/chat': DeepLinkConfig(
      requiresAuth: true,
      params: [RouteParams.prompt],
    ),
    '/settings': DeepLinkConfig(
      requiresAuth: true,
      params: [RouteParams.section],
    ),
    '/settings/privacy': DeepLinkConfig(requiresAuth: true),
    '/login': DeepLinkConfig(
      requiresAuth: false,
      params: [RouteParams.redirect],
    ),
  };

  /// Parse a URI and return the normalized path and validated parameters
  static DeepLinkResult parse(Uri uri) {
    // Normalize the path (handle both custom scheme and universal links)
    final path = _normalizePath(uri);

    // Find matching route config
    final config = _matchRoute(path);
    if (config == null) {
      debugPrint('DeepLinkHandler: Unknown route $path, falling back to hub');
      return const DeepLinkResult(
        path: Routes.hub,
        params: {},
        requiresAuth: true,
      );
    }

    // Validate and sanitize parameters
    final params = _validateParams(uri.queryParameters, config);

    return DeepLinkResult(
      path: path,
      params: params,
      requiresAuth: config.requiresAuth,
    );
  }

  /// Normalize path from URI (custom scheme or universal link)
  static String _normalizePath(Uri uri) {
    if (uri.scheme == AppConfig.deepLinkScheme) {
      // Custom scheme: kindbanking://balance → /balance
      // Host becomes first path segment
      final host = uri.host;
      final path = uri.path;
      if (host.isNotEmpty) {
        return '/$host$path';
      }
      return path.isEmpty ? Routes.hub : path;
    }

    // Universal link: already has path
    return uri.path.isEmpty ? Routes.hub : uri.path;
  }

  /// Find matching route configuration
  static DeepLinkConfig? _matchRoute(String path) {
    // Direct match
    if (_routes.containsKey(path)) {
      return _routes[path];
    }

    // Check for parameterized routes (e.g., /transactions/:id)
    for (final entry in _routes.entries) {
      if (_pathMatches(entry.key, path)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Check if a route pattern matches a path
  static bool _pathMatches(String pattern, String path) {
    final patternSegments = pattern.split('/');
    final pathSegments = path.split('/');

    if (patternSegments.length != pathSegments.length) {
      return false;
    }

    for (var i = 0; i < patternSegments.length; i++) {
      final patternSegment = patternSegments[i];
      final pathSegment = pathSegments[i];

      // Skip parameter segments (starting with :)
      if (patternSegment.startsWith(':')) {
        continue;
      }

      if (patternSegment != pathSegment) {
        return false;
      }
    }

    return true;
  }

  /// Validate and sanitize query parameters
  static Map<String, String> _validateParams(
    Map<String, String> raw,
    DeepLinkConfig config,
  ) {
    final validated = <String, String>{};

    for (final key in config.params) {
      if (raw.containsKey(key)) {
        final value = raw[key]!;
        // Sanitize: remove potential injection characters
        final sanitized = _sanitize(value);

        // Special validation for amount
        if (key == RouteParams.amount) {
          final amount = double.tryParse(sanitized);
          if (amount != null && amount > 0 && amount <= 100000) {
            validated[key] = sanitized;
          }
        } else {
          validated[key] = sanitized;
        }
      }
    }

    return validated;
  }

  /// Sanitize a parameter value
  static String _sanitize(String value) {
    // Remove potential XSS/injection characters
    return value.replaceAll(RegExp(r'[<>"\x27]'), '').trim();
  }

  /// Build a deep link URI for a given path and parameters
  static Uri buildUri(String path, [Map<String, String>? params]) {
    return Uri(
      scheme: AppConfig.deepLinkScheme,
      host: path.split('/').where((s) => s.isNotEmpty).firstOrNull ?? 'hub',
      path: path.split('/').skip(2).join('/'),
      queryParameters: params?.isNotEmpty == true ? params : null,
    );
  }
}

/// Result of parsing a deep link
class DeepLinkResult {
  final String path;
  final Map<String, String> params;
  final bool requiresAuth;

  const DeepLinkResult({
    required this.path,
    required this.params,
    required this.requiresAuth,
  });

  /// Build the full location string with query parameters
  String get location {
    if (params.isEmpty) {
      return path;
    }
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$path?$query';
  }
}
