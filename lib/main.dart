import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies (includes DeepLinkService)
  await AppLocator.init();

  runApp(const KindBankingApp());
}

/// Kind Banking - Banking for Everyone
/// A Flutter banking app with adaptive UI and voice assistant integration
class KindBankingApp extends StatefulWidget {
  const KindBankingApp({super.key});

  @override
  State<KindBankingApp> createState() => _KindBankingAppState();
}

class _KindBankingAppState extends State<KindBankingApp> {
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkHandling();
  }

  void _initDeepLinkHandling() {
    final deepLinkService = AppLocator.deepLinkService;

    // Handle initial deep link (cold start)
    final initialLink = deepLinkService.consumeInitialLink();
    if (initialLink != null) {
      // Delay navigation to ensure router is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.router.go(initialLink.location);
      });
    }

    // Handle warm start deep links (app already running)
    _deepLinkSubscription = deepLinkService.deepLinkStream.listen((result) {
      debugPrint('Deep link received: ${result.location}');
      AppRouter.router.go(result.location);
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppLocator.providers,
      child: MaterialApp.router(
        title: 'Kind Banking',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,

        // Router configuration (go_router)
        routerConfig: AppRouter.router,
      ),
    );
  }
}
