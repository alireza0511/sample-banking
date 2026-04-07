import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'config/app_config.dart';

/// Dependency injection setup using Provider
/// All services and repositories are registered here
class AppLocator {
  AppLocator._();

  /// Initialize all dependencies
  static Future<void> init() async {
    // Set environment (can be configured via build flags)
    AppConfig.setEnvironment(Environment.development);

    // Initialize services that need async setup
    // TODO: Add service initialization
  }

  /// Get all providers for the app
  static List<SingleChildWidget> get providers => [
        // Auth state provider
        ChangeNotifierProvider(
          create: (_) => AuthStateNotifier(),
        ),

        // TODO: Add more providers as features are implemented
        // - ApiClient provider
        // - AuthBloc provider
        // - HubBloc provider
        // - etc.
      ];
}

/// Auth state notifier for Provider
/// Simple implementation for M1, will be replaced with full AuthBloc in M1.10
class AuthStateNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userName;
  String? _authToken;

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
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userId = null;
    _userName = null;
    _authToken = null;
    notifyListeners();
  }
}
