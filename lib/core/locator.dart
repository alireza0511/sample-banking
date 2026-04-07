import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'config/app_config.dart';
import 'network/api_client.dart';

/// Dependency injection setup using Provider
/// All services and repositories are registered here
class AppLocator {
  AppLocator._();

  static ApiClient? _apiClient;

  /// Get the shared ApiClient instance
  static ApiClient get apiClient {
    _apiClient ??= ApiClient();
    return _apiClient!;
  }

  /// Initialize all dependencies
  static Future<void> init() async {
    // Set environment (can be configured via build flags)
    AppConfig.setEnvironment(Environment.development);

    // Initialize API client
    _apiClient = ApiClient();
  }

  /// Get all providers for the app
  static List<SingleChildWidget> get providers => [
        // API Client provider (singleton)
        Provider<ApiClient>.value(value: apiClient),

        // Auth state provider
        ChangeNotifierProxyProvider<ApiClient, AuthStateNotifier>(
          create: (context) => AuthStateNotifier(apiClient: apiClient),
          update: (context, api, auth) => auth ?? AuthStateNotifier(apiClient: api),
        ),
      ];
}

/// Auth state notifier for Provider
/// Simple implementation for M1, will be replaced with full AuthBloc in M1.10
class AuthStateNotifier extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isAuthenticated = false;
  String? _userId;
  String? _userName;
  String? _authToken;

  AuthStateNotifier({required ApiClient apiClient}) : _apiClient = apiClient;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get authToken => _authToken;

  void login({
    required String userId,
    required String userName,
    required String authToken,
  }) {
    _isAuthenticated = true;
    _userId = userId;
    _userName = userName;
    _authToken = authToken;

    // Sync auth token with API client
    _apiClient.setAuthToken(authToken);

    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userId = null;
    _userName = null;
    _authToken = null;

    // Clear auth token from API client
    _apiClient.clearAuthToken();

    notifyListeners();
  }
}
