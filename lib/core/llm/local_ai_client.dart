import 'dart:async';

/// Abstract interface for local/on-device AI clients
/// This wrapper allows swapping the underlying package (flutter_local_ai, etc.)
/// without changing the OnDeviceLlmProvider implementation.
abstract class LocalAiClient {
  /// Check if local AI is available on this device
  Future<bool> isAvailable();

  /// Initialize the model with optional system instructions
  /// Returns true if initialization was successful
  Future<bool> initialize({String? instructions});

  /// Generate text from a prompt
  Future<LocalAiResponse> generateText({
    required String prompt,
    int maxTokens = 1024,
    double? temperature,
  });

  /// Open platform-specific AI setup (e.g., Google AICore Play Store)
  /// Returns true if successful, false if not supported or failed
  Future<bool> openPlatformSetup();

  /// Dispose resources
  void dispose();
}

/// Response from local AI generation
class LocalAiResponse {
  /// The generated text
  final String text;

  /// Token count used (if available)
  final int? tokenCount;

  /// Generation time in milliseconds (if available)
  final int? generationTimeMs;

  const LocalAiResponse({
    required this.text,
    this.tokenCount,
    this.generationTimeMs,
  });
}
