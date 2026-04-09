// LLM Service Module
//
// Provider-agnostic LLM abstraction layer supporting:
// - On-device LLM (iOS 26+ Apple Foundation Models, Android Gemini Nano)
// - Mock provider for testing and demo
// - Extensible for cloud providers
//
// Usage:
//   final llmManager = LlmManager();
//   await llmManager.initialize();
//
//   // Non-streaming
//   final response = await llmManager.generateResponse(
//     LlmRequest(prompt: 'What is my balance?'),
//   );
//
//   // Streaming
//   await for (final token in llmManager.streamResponse(request)) {
//     print(token);
//   }

/// Barrel file for LLM module exports.
library;

export 'llm_service.dart';
export 'llm_provider.dart';
export 'llm_manager.dart';
export 'on_device_llm_provider.dart';
export 'mock_llm_provider.dart';
export 'local_ai_client.dart';
export 'flutter_local_ai_client.dart';
