import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await AppLocator.init();

  runApp(const KindBankingApp());
}

/// Kind Banking - Banking for Everyone
/// A Flutter banking app with adaptive UI and voice assistant integration
class KindBankingApp extends StatelessWidget {
  const KindBankingApp({super.key});

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
