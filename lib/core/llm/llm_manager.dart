import 'dart:async';

import 'llm_service.dart';
import 'llm_provider.dart';
import 'on_device_llm_provider.dart';
import 'mock_llm_provider.dart';

/// Manages LLM providers with fallback chain
/// Priority: On-Device > Cloud > Mock
class LlmManager implements LlmService {
  final List<LlmProvider> _providers = [];
  LlmProvider? _activeProvider;
  bool _isInitialized = false;

  /// Current availability status
  LlmAvailabilityStatus _status = LlmAvailabilityStatus.checking;

  /// Get current availability status
  LlmAvailabilityStatus get status => _status;

  /// Get the active provider info
  LlmProviderInfo? get activeProviderInfo => _activeProvider?.providerInfo;

  /// Check if using on-device provider
  bool get isOnDevice => _activeProvider?.providerInfo.isOnDevice ?? false;

  @override
  LlmProviderInfo get providerInfo =>
      _activeProvider?.providerInfo ??
      const LlmProviderInfo(
        name: 'Unavailable',
        type: LlmProviderType.mock,
        isPrivate: true,
      );

  @override
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _activeProvider != null;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    _status = LlmAvailabilityStatus.checking;

    // Register providers in priority order
    _providers.clear();
    _providers.addAll([
      OnDeviceLlmProvider(),
      MockLlmProvider(), // Fallback for demo
    ]);

    // Try to find an available provider
    for (final provider in _providers) {
      try {
        await provider.initialize();
        if (await provider.isAvailable()) {
          _activeProvider = provider;
          _status = provider.providerInfo.type == LlmProviderType.onDevice
              ? LlmAvailabilityStatus.onDeviceAvailable
              : LlmAvailabilityStatus.fallbackAvailable;
          break;
        }
      } catch (e) {
        // Provider failed to initialize, try next
        continue;
      }
    }

    if (_activeProvider == null) {
      _status = LlmAvailabilityStatus.unavailable;
    }

    _isInitialized = true;
  }

  @override
  Future<LlmResponse> generateResponse(LlmRequest request) async {
    await _ensureInitialized();

    if (_activeProvider == null) {
      throw const LlmError(
        message: 'No LLM provider available',
        type: LlmErrorType.unavailable,
      );
    }

    return _activeProvider!.generateResponse(request);
  }

  @override
  Stream<String> streamResponse(LlmRequest request) async* {
    await _ensureInitialized();

    if (_activeProvider == null) {
      throw const LlmError(
        message: 'No LLM provider available',
        type: LlmErrorType.unavailable,
      );
    }

    yield* _activeProvider!.streamResponse(request);
  }

  @override
  void dispose() {
    for (final provider in _providers) {
      provider.dispose();
    }
    _providers.clear();
    _activeProvider = null;
    _isInitialized = false;
  }

  /// Refresh provider availability (e.g., after network change)
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get all registered providers and their status
  Future<List<LlmProviderStatus>> getProviderStatuses() async {
    final statuses = <LlmProviderStatus>[];

    for (final provider in _providers) {
      final available = await provider.isAvailable();
      statuses.add(LlmProviderStatus(
        info: provider.providerInfo,
        isAvailable: available,
        isActive: provider == _activeProvider,
      ));
    }

    return statuses;
  }
}

/// LLM availability status
enum LlmAvailabilityStatus {
  checking,
  onDeviceAvailable,
  fallbackAvailable,
  unavailable,
}

/// Status of a specific provider
class LlmProviderStatus {
  final LlmProviderInfo info;
  final bool isAvailable;
  final bool isActive;

  const LlmProviderStatus({
    required this.info,
    required this.isAvailable,
    required this.isActive,
  });
}
