import 'dart:async';
import 'dart:convert';

import 'package:banking_genui_components/banking_genui_components.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';

import '../../core/llm/llm_service.dart';
import '../../core/locator.dart';
import '../../core/routing/routes.dart';
import '../model/dashboard_config.dart';
import '../widgets/dashboard_loading.dart';

/// AI-powered dashboard screen using GenUI/A2UI
///
/// This screen uses the LLM to dynamically compose a personalized
/// banking dashboard using the BankingCatalog components.
class AiDashboardScreen extends StatefulWidget {
  const AiDashboardScreen({super.key});

  @override
  State<AiDashboardScreen> createState() => _AiDashboardScreenState();
}

class _AiDashboardScreenState extends State<AiDashboardScreen> {
  late final A2uiMessageProcessor _messageProcessor;
  StreamSubscription<UserUiInteractionMessage>? _eventSubscription;

  static const String _surfaceId = 'dashboard';

  bool _isLoading = true;
  String? _errorMessage;
  bool _isLlmAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    // Initialize message processor with catalog
    final catalog = BankingCatalog.asCatalog();
    _messageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

    // Listen for user actions from components
    _eventSubscription = _messageProcessor.onSubmit.listen(_handleUiMessage);

    // Initialize LLM and generate dashboard
    await _generateDashboard();
  }

  Future<void> _generateDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final llmManager = AppLocator.llmManager;
      await llmManager.initialize();

      _isLlmAvailable = await llmManager.isAvailable();

      if (_isLlmAvailable && llmManager.isOnDevice) {
        // Generate dashboard using LLM
        await _generateWithLlm(llmManager);
      } else {
        // Use default dashboard for demo
        _loadDefaultDashboard();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateWithLlm(LlmService llmManager) async {
    try {
      // Build the prompt with user context
      final prompt = DashboardConfig.buildDashboardPrompt(
        userName: 'User',
        totalBalance: 45200.00,
        accounts: const [
          AccountInfo(name: 'Primary Checking', type: 'checking', balance: 12450.00),
          AccountInfo(name: 'Savings', type: 'savings', balance: 32750.00),
        ],
        recentTransactions: [
          TransactionInfo(
            merchant: 'Whole Foods Market',
            amount: -87.32,
            date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          ),
          TransactionInfo(
            merchant: 'Netflix',
            amount: -15.99,
            date: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          ),
        ],
      );

      final response = await llmManager.generateResponse(
        LlmRequest(
          prompt: prompt,
          systemPrompt: DashboardConfig.systemPrompt,
          temperature: 0.3,
          maxTokens: 2048,
        ),
      );

      // Parse the LLM response and update surface
      final success = _parseAndUpdateSurface(response.content);
      if (!success) {
        _loadDefaultDashboard();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } on LlmError catch (e) {
      debugPrint('LLM Error: ${e.message}');
      _loadDefaultDashboard();
    }
  }

  void _loadDefaultDashboard() {
    _updateSurfaceFromJson(DashboardConfig.defaultDashboard);
    setState(() {
      _isLoading = false;
    });
  }

  bool _parseAndUpdateSurface(String response) {
    try {
      var jsonStr = response.trim();

      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, Object?>;
      _updateSurfaceFromJson(json);
      return true;
    } catch (e) {
      debugPrint('Failed to parse GenUI response: $e');
      return false;
    }
  }

  void _updateSurfaceFromJson(Map<String, Object?> json) {
    // Convert JSON tree to GenUI components
    final components = <String, Component>{};
    final rootId = _buildComponentTree(json, components);

    // Create surface update message
    final surfaceUpdate = SurfaceUpdate(
      surfaceId: _surfaceId,
      components: components.values.toList(),
    );
    _messageProcessor.handleMessage(surfaceUpdate);

    // Begin rendering
    final beginRendering = BeginRendering(
      surfaceId: _surfaceId,
      root: rootId,
      catalogId: null,
    );
    _messageProcessor.handleMessage(beginRendering);
  }

  String _buildComponentTree(
    Map<String, Object?> json,
    Map<String, Component> components,
  ) {
    final id = UniqueKey().toString();
    final type = json['type'] as String? ?? 'Column';
    final data = Map<String, Object?>.from(json['data'] as Map<String, Object?>? ?? {});
    final childrenJson = json['children'] as List<dynamic>?;

    // Process children
    if (childrenJson != null && childrenJson.isNotEmpty) {
      final childIds = <String>[];
      for (final child in childrenJson) {
        if (child is Map<String, Object?>) {
          final childId = _buildComponentTree(child, components);
          childIds.add(childId);
        }
      }
      data['children'] = childIds;
    }

    // Create component
    final component = Component(
      id: id,
      componentProperties: {type: data},
    );
    components[id] = component;

    return id;
  }

  void _handleUiMessage(UserUiInteractionMessage message) {
    try {
      final json = jsonDecode(message.text) as Map<String, Object?>;
      final userAction = json['userAction'] as Map<String, Object?>?;
      if (userAction != null) {
        final action = userAction['name'] as String?;
        final actionContext = userAction['context'] as Map<String, Object?>?;
        _handleUserAction(action, actionContext);
      }
    } catch (e) {
      debugPrint('Failed to handle UI message: $e');
    }
  }

  void _handleUserAction(String? action, Map<String, Object?>? actionContext) {
    if (action == null) return;

    debugPrint('User action: $action, context: $actionContext');

    switch (action) {
      case 'navigate_transfer':
        context.push(Routes.transfer);
        break;
      case 'navigate_bills':
        context.push(Routes.payBills);
        break;
      case 'navigate_balance':
        context.push(Routes.balance);
        break;
      case 'transfer_submitted':
        _handleTransferSubmitted(actionContext);
        break;
      case 'transfer_cancelled':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer cancelled')),
        );
        break;
      case 'transaction_tapped':
        final transactionId = actionContext?['transactionId'] as String?;
        if (transactionId != null) {
          context.push('/transactions/$transactionId');
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: $action')),
        );
    }
  }

  void _handleTransferSubmitted(Map<String, Object?>? actionContext) {
    final amount = actionContext?['amount'];
    final fromAccount = actionContext?['fromAccount'];
    final toAccount = actionContext?['toAccount'];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transfer \$$amount from $fromAccount to $toAccount'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => context.push(Routes.transactions),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _messageProcessor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AI Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateDashboard,
              tooltip: 'Regenerate',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Info',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const DashboardLoading();
    }

    if (_errorMessage != null) {
      return DashboardError(
        message: _errorMessage!,
        onRetry: _generateDashboard,
      );
    }

    return SingleChildScrollView(
      child: GenUiSurface(
        host: _messageProcessor,
        surfaceId: _surfaceId,
        defaultBuilder: (context) => const DashboardLoading(),
      ),
    );
  }

  void _showInfoDialog() {
    final llmManager = AppLocator.llmManager;
    final providerInfo = llmManager.providerInfo;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Dashboard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This dashboard is dynamically generated using AI.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Provider', providerInfo.name),
            _buildInfoRow('Type', providerInfo.type.name),
            _buildInfoRow('On-Device', providerInfo.isOnDevice ? 'Yes' : 'No'),
            if (providerInfo.modelName != null)
              _buildInfoRow('Model', providerInfo.modelName!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
