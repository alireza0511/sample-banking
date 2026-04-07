import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'deep_link_handler.dart';

/// Service for handling deep links using app_links package
/// Handles both cold start (initial link) and warm start (link stream)
class DeepLinkService {
  final AppLinks _appLinks;

  /// Stream controller for broadcasting deep link events
  final _deepLinkController = StreamController<DeepLinkResult>.broadcast();

  /// Stream of parsed deep link results
  Stream<DeepLinkResult> get deepLinkStream => _deepLinkController.stream;

  /// The initial deep link that launched the app (cold start)
  DeepLinkResult? _initialLink;
  DeepLinkResult? get initialLink => _initialLink;

  /// Whether the service has been initialized
  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Subscription to the app links stream
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  /// Initialize the deep link service
  /// Call this early in app startup (before runApp or in main())
  Future<void> init() async {
    if (_initialized) {
      debugPrint('DeepLinkService: Already initialized');
      return;
    }

    try {
      // Handle cold start - get initial link
      await _handleInitialLink();

      // Handle warm start - listen for incoming links
      _listenForLinks();

      _initialized = true;
      debugPrint('DeepLinkService: Initialized successfully');
    } catch (e) {
      debugPrint('DeepLinkService: Initialization error: $e');
    }
  }

  /// Handle cold start - app launched via deep link
  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('DeepLinkService: Initial link received: $initialUri');
        _initialLink = DeepLinkHandler.parse(initialUri);
        _deepLinkController.add(_initialLink!);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error getting initial link: $e');
    }
  }

  /// Handle warm start - app already running, receives deep link
  void _listenForLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('DeepLinkService: Link received: $uri');
        final result = DeepLinkHandler.parse(uri);
        _deepLinkController.add(result);
      },
      onError: (error) {
        debugPrint('DeepLinkService: Link stream error: $error');
      },
    );
  }

  /// Manually handle a deep link URI (useful for testing)
  void handleUri(Uri uri) {
    final result = DeepLinkHandler.parse(uri);
    _deepLinkController.add(result);
  }

  /// Check if there's a pending initial link that hasn't been consumed
  bool get hasPendingInitialLink => _initialLink != null;

  /// Consume and clear the initial link (call after handling)
  DeepLinkResult? consumeInitialLink() {
    final link = _initialLink;
    _initialLink = null;
    return link;
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
