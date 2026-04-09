import 'dart:io';

import 'package:flutter_local_ai/flutter_local_ai.dart';

import 'local_ai_client.dart';

/// Implementation of LocalAiClient using flutter_local_ai package
///
/// Wraps the flutter_local_ai package to provide a consistent interface.
/// To swap to a different package, create a new implementation of LocalAiClient
/// and register it in the OnDeviceLlmProvider.
///
/// Supported platforms:
/// - iOS 26+: Apple Foundation Models
/// - Android: Gemini Nano via Google AICore
/// - macOS: Apple Foundation Models
/// - Windows: Windows AI APIs
class FlutterLocalAiClient implements LocalAiClient {
  final FlutterLocalAi _localAi;
  bool _isInitialized = false;

  FlutterLocalAiClient({FlutterLocalAi? localAi})
      : _localAi = localAi ?? FlutterLocalAi();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _localAi.isAvailable();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> initialize({String? instructions}) async {
    if (_isInitialized) return true;

    try {
      final success = await _localAi.initialize(instructions: instructions);
      _isInitialized = success;
      return success;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Future<LocalAiResponse> generateText({
    required String prompt,
    int maxTokens = 1024,
    double? temperature,
  }) async {
    final response = await _localAi.generateText(
      prompt: prompt,
      config: GenerationConfig(
        maxTokens: maxTokens,
        temperature: temperature,
      ),
    );

    return LocalAiResponse(
      text: response.text,
      tokenCount: response.tokenCount,
      generationTimeMs: response.generationTimeMs,
    );
  }

  @override
  Future<bool> openPlatformSetup() async {
    // Only Android supports opening AICore in Play Store
    if (!Platform.isAndroid) return false;

    try {
      return await _localAi.openAICorePlayStore();
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    // flutter_local_ai doesn't have a dispose method currently
  }
}
