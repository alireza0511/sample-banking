import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/routing/deep_link_handler.dart';
import '../core/routing/routes.dart';

/// Development screen for testing deep links
/// Shows all available routes and allows testing them
class DeepLinkTestScreen extends StatefulWidget {
  const DeepLinkTestScreen({super.key});

  @override
  State<DeepLinkTestScreen> createState() => _DeepLinkTestScreenState();
}

class _DeepLinkTestScreenState extends State<DeepLinkTestScreen> {
  final _customUriController = TextEditingController();

  /// All testable deep link routes with sample parameters
  static final List<_TestRoute> _testRoutes = [
    _TestRoute(
      name: 'Hub',
      path: Routes.hub,
      description: 'Main hub screen',
    ),
    _TestRoute(
      name: 'Balance',
      path: Routes.balance,
      params: {RouteParams.accountId: 'acc_checking_001'},
      description: 'Account balance with account pre-selected',
    ),
    _TestRoute(
      name: 'Transfer',
      path: Routes.transfer,
      params: {
        RouteParams.to: 'jane.smith@email.com',
        RouteParams.amount: '50.00',
      },
      description: 'Transfer screen with recipient and amount pre-filled',
    ),
    _TestRoute(
      name: 'Transfer (Zelle)',
      path: Routes.transfer,
      params: {RouteParams.to: '+1-555-123-4567'},
      description: 'Zelle transfer with phone number',
    ),
    _TestRoute(
      name: 'Pay Bills',
      path: Routes.payBills,
      params: {
        RouteParams.billerId: 'biller_001',
        RouteParams.amount: '125.00',
      },
      description: 'Pay bills with biller and amount pre-filled',
    ),
    _TestRoute(
      name: 'Transactions',
      path: Routes.transactions,
      params: {RouteParams.accountId: 'acc_checking_001'},
      description: 'Transaction history for specific account',
    ),
    _TestRoute(
      name: 'Cards',
      path: Routes.cards,
      description: 'Card management screen',
    ),
    _TestRoute(
      name: 'Chat',
      path: Routes.chat,
      description: 'AI chat screen',
    ),
    _TestRoute(
      name: 'Chat with Prompt',
      path: Routes.chat,
      params: {RouteParams.prompt: 'Show my balance'},
      description: 'Chat with pre-filled prompt from Siri',
    ),
    _TestRoute(
      name: 'Settings',
      path: Routes.settings,
      description: 'Settings screen',
    ),
    _TestRoute(
      name: 'Settings (Privacy)',
      path: '${Routes.settings}/privacy',
      description: 'Privacy settings section',
    ),
  ];

  void _testRoute(_TestRoute route) {
    final location = route.fullPath;
    debugPrint('Testing deep link: $location');
    context.go(location);
  }

  void _copyDeepLink(_TestRoute route) {
    final uri = DeepLinkHandler.buildUri(route.path, route.params);
    Clipboard.setData(ClipboardData(text: uri.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $uri'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _testCustomUri() {
    final text = _customUriController.text.trim();
    if (text.isEmpty) return;

    try {
      final uri = Uri.parse(text);
      final result = DeepLinkHandler.parse(uri);
      debugPrint('Parsed deep link: ${result.location}');
      context.go(result.location);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid URI: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _customUriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Link Tester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom URI input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customUriController,
                    decoration: InputDecoration(
                      labelText: 'Custom Deep Link',
                      hintText: '${AppConfig.deepLinkScheme}://balance?account_id=123',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _customUriController.clear(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _testCustomUri,
                  child: const Text('Test'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Predefined test routes
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _testRoutes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final route = _testRoutes[index];
                return _RouteListTile(
                  route: route,
                  onTap: () => _testRoute(route),
                  onCopy: () => _copyDeepLink(route),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deep Link Testing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Test deep links by tapping routes or entering custom URIs.'),
            const SizedBox(height: 16),
            Text('Custom Scheme: ${AppConfig.deepLinkScheme}://'),
            const SizedBox(height: 8),
            const Text('Universal Link: https://app.kindbanking.com/'),
            const SizedBox(height: 16),
            const Text('Terminal testing:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: const SelectableText(
                'xcrun simctl openurl booted "kindbanking://balance"',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _TestRoute {
  final String name;
  final String path;
  final Map<String, String>? params;
  final String description;

  const _TestRoute({
    required this.name,
    required this.path,
    this.params,
    required this.description,
  });

  String get fullPath {
    if (params == null || params!.isEmpty) return path;
    final query = params!.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$path?$query';
  }

  String get deepLinkUri {
    return DeepLinkHandler.buildUri(path, params).toString();
  }
}

class _RouteListTile extends StatelessWidget {
  final _TestRoute route;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _RouteListTile({
    required this.route,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(route.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            route.fullPath,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: onCopy,
            tooltip: 'Copy deep link URI',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: onTap,
            tooltip: 'Test this route',
          ),
        ],
      ),
    );
  }
}
