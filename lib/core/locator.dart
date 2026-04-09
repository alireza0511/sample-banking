import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'config/app_config.dart';
import 'intents/intent_service.dart';
import 'llm/llm_manager.dart';
import 'network/api_client.dart';
import 'routing/deep_link_service.dart';

/// Dependency injection setup using Provider
/// All services and repositories are registered here
class AppLocator {
  AppLocator._();

  static ApiClient? _apiClient;
  static DeepLinkService? _deepLinkService;
  static LlmManager? _llmManager;
  static IntentService? _intentService;

  /// Get the shared ApiClient instance
  static ApiClient get apiClient {
    _apiClient ??= ApiClient();
    return _apiClient!;
  }

  /// Get the shared DeepLinkService instance
  static DeepLinkService get deepLinkService {
    _deepLinkService ??= DeepLinkService();
    return _deepLinkService!;
  }

  /// Get the shared LlmManager instance
  static LlmManager get llmManager {
    _llmManager ??= LlmManager();
    return _llmManager!;
  }

  /// Get the shared IntentService instance
  static IntentService get intentService {
    _intentService ??= IntentService(deepLinkService: deepLinkService);
    return _intentService!;
  }

  /// Initialize all dependencies
  static Future<void> init() async {
    // Set environment (can be configured via build flags)
    AppConfig.setEnvironment(Environment.development);

    // Initialize API client
    _apiClient = ApiClient();

    // Initialize deep link service
    _deepLinkService = DeepLinkService();
    await _deepLinkService!.init();

    // Initialize LLM manager with fallback chain
    _llmManager = LlmManager();
    await _llmManager!.initialize();

    // Initialize intent service for Siri/voice commands
    _intentService = IntentService(deepLinkService: deepLinkService);
    await _intentService!.init();
  }

  /// Get all providers for the app
  static List<SingleChildWidget> get providers => [
        // API Client provider (singleton)
        Provider<ApiClient>.value(value: apiClient),

        // Deep Link Service provider (singleton)
        Provider<DeepLinkService>.value(value: deepLinkService),

        // LLM Manager provider (singleton with fallback chain)
        Provider<LlmManager>.value(value: llmManager),

        // Intent Service provider (singleton for voice commands)
        Provider<IntentService>.value(value: intentService),

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
