import 'package:flutter/material.dart';

import '../core/llm/llm_manager.dart';
import '../core/llm/llm_service.dart';
import '../core/locator.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Developer screen showing LLM provider status
/// Access via Settings > Developer Options > LLM Status
class LlmStatusScreen extends StatefulWidget {
  const LlmStatusScreen({super.key});

  @override
  State<LlmStatusScreen> createState() => _LlmStatusScreenState();
}

class _LlmStatusScreenState extends State<LlmStatusScreen> {
  late LlmManager _llmManager;
  List<LlmProviderStatus> _providerStatuses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _llmManager = AppLocator.llmManager;
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statuses = await _llmManager.getProviderStatuses();
      setState(() {
        _providerStatuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _llmManager.refresh();
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh providers',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text('Error: $_error'),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: _loadStatus,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    _buildManagerStatusCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionHeader('Registered Providers'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._providerStatuses.map(_buildProviderCard),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTestCard(),
                  ],
                ),
    );
  }

  Widget _buildManagerStatusCard() {
    final activeProvider = _llmManager.activeProviderInfo;
    final status = _llmManager.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'LLM Manager',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Status', _getStatusText(status)),
            _buildInfoRow('Active Provider', activeProvider?.name ?? 'None'),
            _buildInfoRow('Model', activeProvider?.modelName ?? 'N/A'),
            _buildInfoRow('Type', activeProvider?.type.name ?? 'N/A'),
            _buildInfoRow('On-Device', _llmManager.isOnDevice ? 'Yes' : 'No'),
            _buildInfoRow('Private', activeProvider?.isPrivate == true ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildProviderCard(LlmProviderStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          _getProviderIcon(status.info.type),
          color: status.isActive
              ? AppColors.success
              : status.isAvailable
                  ? AppColors.primaryBlue
                  : AppColors.textTertiary,
        ),
        title: Text(status.info.name),
        subtitle: Text(
          status.info.modelName ?? status.info.type.name,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              status.isAvailable ? Icons.check_circle : Icons.cancel,
              color: status.isAvailable ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Test',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testGeneration,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Generation'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testStreaming,
                icon: const Icon(Icons.stream),
                label: const Text('Test Streaming'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(LlmAvailabilityStatus status) {
    switch (status) {
      case LlmAvailabilityStatus.checking:
        return Icons.hourglass_empty;
      case LlmAvailabilityStatus.onDeviceAvailable:
        return Icons.phone_android;
      case LlmAvailabilityStatus.fallbackAvailable:
        return Icons.cloud_outlined;
      case LlmAvailabilityStatus.unavailable:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor(LlmAvailabilityStatus status) {
    switch (status) {
      case LlmAvailabilityStatus.checking:
        return AppColors.warning;
      case LlmAvailabilityStatus.onDeviceAvailable:
        return AppColors.privacyOnDevice;
      case LlmAvailabilityStatus.fallbackAvailable:
        return AppColors.primaryBlue;
      case LlmAvailabilityStatus.unavailable:
        return AppColors.error;
    }
  }

  String _getStatusText(LlmAvailabilityStatus status) {
    switch (status) {
      case LlmAvailabilityStatus.checking:
        return 'Checking...';
      case LlmAvailabilityStatus.onDeviceAvailable:
        return 'On-Device Available';
      case LlmAvailabilityStatus.fallbackAvailable:
        return 'Fallback Active';
      case LlmAvailabilityStatus.unavailable:
        return 'Unavailable';
    }
  }

  IconData _getProviderIcon(LlmProviderType type) {
    switch (type) {
      case LlmProviderType.onDevice:
        return Icons.phone_android;
      case LlmProviderType.cloud:
        return Icons.cloud;
      case LlmProviderType.hybrid:
        return Icons.sync_alt;
      case LlmProviderType.mock:
        return Icons.science;
    }
  }

  Future<void> _testGeneration() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Testing generation...')),
      );

      final request = const LlmRequest(prompt: 'What model are you?');
      final response = await _llmManager.generateResponse(request);

      messenger.hideCurrentSnackBar();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Generation Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Provider: ${response.providerInfo.name}'),
                Text('Model: ${response.providerInfo.modelName ?? "N/A"}'),
                Text('Tokens: ${response.tokensUsed ?? "N/A"}'),
                Text('Latency: ${response.latency?.inMilliseconds ?? "N/A"}ms'),
                const Divider(),
                Text('Response:\n${response.content}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _testStreaming() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final buffer = StringBuffer();
      int tokenCount = 0;

      messenger.showSnackBar(
        const SnackBar(content: Text('Testing streaming...')),
      );

      final request = const LlmRequest(prompt: 'Tell me a short banking tip.');

      await for (final token in _llmManager.streamResponse(request)) {
        buffer.write(token);
        tokenCount++;
      }

      messenger.hideCurrentSnackBar();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Streaming Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Provider: ${_llmManager.providerInfo.name}'),
                Text('Tokens streamed: $tokenCount'),
                const Divider(),
                Text('Response:\n${buffer.toString()}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
