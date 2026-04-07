# BankApp — Flutter Proof of Concept
## Product Requirements Document

| | |
|---|---|
| **Version** | 1.0 — Initial PoC Scope |
| **Status** | Draft — For Review |
| **Platform** | Flutter (iOS & Android) |
| **Classification** | Confidential — Internal Use Only |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Overview](#2-product-overview)
3. [Architecture](#3-architecture)
4. [MCP Server — LLM Abstraction Layer](#4-mcp-server--llm-abstraction-layer)
5. [Speech Services — STT/TTS Abstraction Layer](#5-speech-services--stttts-abstraction-layer)
6. [Feature Requirements](#6-feature-requirements)
7. [UI Design System](#7-ui-design-system)
8. [Package Dependencies](#8-package-dependencies)
9. [Security Requirements](#9-security-requirements)
10. [Accessibility Requirements](#10-accessibility-requirements)
11. [Non-Functional Requirements](#11-non-functional-requirements)
12. [Out of Scope](#12-out-of-scope-poc)
13. [Suggested Milestones](#13-suggested-poc-milestones)
14. [Open Questions](#14-open-questions)

---

## 1. Executive Summary

BankApp is a Flutter-based proof of concept for an enterprise mobile banking application that demonstrates five key differentiators: native voice assistant integration (Siri on iOS, Google Assistant on Android), a fully adaptive hub screen that reconfigures itself based on user accessibility needs, an AI chat assistant with intelligent LLM routing, an **MCP Server abstraction layer** that unifies access to local and cloud-based LLMs, and a **Speech Services abstraction** for swappable STT/TTS providers.

The PoC validates that these capabilities can be delivered within a clean, maintainable architecture using **clean_framework 0.4.2**, while meeting enterprise-grade security and accessibility standards. The MCP Server ensures the banking app remains **LLM source-agnostic**, and the Speech Services layer ensures **STT/TTS provider-agnostic** design — enabling future migration to enterprise solutions (Azure, Google, AWS) without code changes.

### PoC Goals

- Validate voice-to-deep-link flow for key banking actions via Siri and Google Assistant
- Demonstrate a dynamic hub screen that adapts to VoiceOver, color blindness, large text, and more
- Prove LLM-powered chat is viable for basic banking Q&A with privacy-first routing (prefer on-device, fallback to cloud)
- **Deliver an MCP Server that abstracts LLM source selection from the banking app**
- **Deliver Speech Services abstraction (STT/TTS) enabling future enterprise provider swap**
- Establish a clean_framework architecture pattern reusable across all banking features
- Deliver a demo-ready build on both iOS (iPhone 15+) and Android (Pixel 8+)

---

## 2. Product Overview

### 2.1 Problem Statement

Existing banking apps treat voice assistants as an afterthought — at best, they redirect users to the app's home screen. Accessibility is similarly bolt-on, with minimal adaptation for users with disabilities. Meanwhile, in-app chat assistants rely entirely on cloud APIs, creating latency, privacy, and offline reliability concerns.

BankApp PoC directly addresses each of these gaps within a single, architecturally sound application.

### 2.2 Target Users

| User Segment | Primary Characteristics |
|---|---|
| General users | Standard banking tasks via hub and navigation |
| VoiceOver / TalkBack users | Blind or low-vision users relying on screen readers |
| Color-blind users | Deuteranopia, protanopia, or tritanopia profiles |
| Elderly users | Prefer large text, high contrast, simplified layouts |
| Power users | Use voice shortcuts to jump directly into banking flows |
| Privacy-conscious users | Benefit from on-device LLM with no cloud data exposure |

### 2.3 Platform Scope

| Platform | Minimum | On-Device LLM | Notes |
|---|---|---|---|
| **iOS** | 16.0+ | 26.0+ | App Intents (Siri) from iOS 16; `flutter_local_ai` requires iOS 26+ |
| **Android** | API 26 (8.0) | API 26+ | `flutter_local_ai` works on API 26+; requires Google AICore installed |
| **Test Hardware** | — | — | iPhone 15 Pro (iOS), Google Pixel 9 Pro (Android) |

**Framework Requirements:**
- Flutter 3.19+, Dart 3.8+
- Xcode 16+ (for iOS 26 SDK)

**On-Device LLM Fallback:**
- Devices not meeting on-device LLM requirements automatically fallback to Ollama (local server) or cloud APIs via MCP Server routing.

---

## 3. Architecture

### 3.1 Framework: clean_framework 0.4.2

The entire application is built on clean_framework 0.4.2, which enforces a strict four-layer architecture inspired by Uncle Bob's Clean Architecture principles. Every feature follows an identical folder and class structure, ensuring consistency and testability across the codebase.

| Layer | Responsibility | Key Classes | Allowed Dependencies |
|---|---|---|---|
| UI | Render screens, handle user events | `Screen`, `Presenter`, `Widget` | model, framework |
| Bloc | Orchestrate data flow, business logic | `Bloc`, `UseCase`, `ServiceAdapter` | model, api |
| Model | Define data shapes | `Entity`, `ViewModel` | equatable |
| API | External data access (HTTP, platform) | `Service`, `ServiceRequest`, `ServiceResponse` | http |

### 3.2 Key Architectural Decisions

| Decision | Rationale |
|---|---|
| clean_framework 0.4.2 | Enforces strict layer separation. Provider-based DI fits the `locator.dart` pattern. |
| go_router | Declarative routing, auth redirect guards, URI deep-link parsing all in one. |
| Mock-first services | All Service classes implement an interface. Demo mode uses local JSON; real API is a swap. |
| **MCP Server for LLM** | Abstracts LLM source (on-device, local, cloud). App is provider-agnostic. Enables privacy-first routing. |
| **Speech Services abstraction** | `SttService` and `TtsService` interfaces enable swap between on-device and enterprise (Azure, Google, AWS) without code changes. |
| **flutter_local_ai for on-device LLM** | Unified package for Apple Foundation Models (iOS 26+) and Gemini Nano/ML Kit GenAI (Android). Single API, no custom MethodChannel needed. |
| **flutter_app_intents for voice assistants** | Unified package for Siri/Shortcuts/Spotlight (iOS) and Google Assistant App Actions (Android). Single API for both platforms. |
| flutter_secure_storage | Keychain (iOS) / Keystore (Android) for all tokens and sensitive flags. No SharedPreferences. |
| MediaQuery for accessibility | OS-level flags (`accessibleNavigation`, `highContrast`, `reduceMotion`, `textScaleFactor`) read directly, no extra dependency. |

### 3.3 Folder Structure

Each feature maps 1:1 to a top-level folder under `lib/`, containing the four sub-folders mandated by clean_framework. Cross-cutting concerns live in `lib/core/`.

```
lib/
├── core/
│   ├── routing/
│   │   ├── app_router.dart           # go_router setup + deep link parsing
│   │   ├── route_guards.dart         # auth redirect logic
│   │   └── deep_link_handler.dart    # app_links integration
│   ├── intents/
│   │   ├── banking_intents.dart      # flutter_app_intents registration
│   │   ├── intent_handlers.dart      # Intent callback handlers
│   │   └── shortcuts_provider.dart   # iOS Shortcuts donations
│   ├── platform/
│   │   └── accessibility_reader.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── color_blind_theme.dart
│   │   └── accessibility_theme.dart
│   └── locator.dart                  # Provider DI registration
│
├── auth/
│   ├── api/    auth_service.dart · auth_request.dart · auth_response.dart
│   ├── bloc/   auth_bloc.dart · auth_usecase.dart · auth_service_adapter.dart
│   ├── model/  user_entity.dart · auth_view_model.dart
│   └── ui/     login_widget.dart · login_presenter.dart · login_screen.dart
│
├── hub/
│   ├── bloc/   hub_bloc.dart · hub_profile_resolver.dart · hub_usecase.dart
│   ├── model/  hub_profile_entity.dart · hub_view_model.dart
│   └── ui/
│       ├── hub_widget.dart · hub_presenter.dart · hub_screen.dart
│       ├── factories/
│       │   ├── hub_widget_factory.dart
│       │   ├── standard_hub.dart
│       │   ├── assistive_hub.dart
│       │   ├── large_text_hub.dart
│       │   └── color_blind_hub.dart
│       └── widgets/
│
├── chat/
│   ├── api/    on_device_llm_service.dart
│   ├── bloc/   chat_bloc.dart · chat_usecase.dart · chat_service_adapter.dart
│   ├── model/  chat_message_entity.dart · chat_view_model.dart
│   └── ui/     chat_widget.dart · chat_presenter.dart · chat_screen.dart
│
├── balance/
├── transfer/
├── transactions/
├── pay_bills/
└── card_management/          # each follows the same api/bloc/model/ui structure

android/
└── app/src/main/
    ├── kotlin/…/MainActivity.kt      # Deep link handling, flutter_app_intents setup
    └── res/xml/shortcuts.xml         # Generated by flutter_app_intents (Android support coming soon)

ios/
└── Runner/
    ├── AppDelegate.swift             # Deep link handling, flutter_app_intents setup
    └── Intents/                      # Generated by flutter_app_intents
        └── GeneratedIntents.swift    # Auto-generated from Dart intent definitions

# Notes:
# - On-device LLM: handled by flutter_local_ai — no custom native code required
# - Voice Assistants: handled by flutter_app_intents — intents defined in Dart, native code generated
```

---

## 4. MCP Server — LLM Abstraction Layer

The MCP (Model Context Protocol) Server is a standalone component that provides a unified interface for LLM access. The banking app communicates exclusively with the MCP Server — it has no knowledge of whether responses originate from on-device models, local inference servers, or cloud APIs.

### 4.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Banking App (Flutter)                     │
│                                                                  │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│   │  Chat Screen  │    │  Hub Actions  │    │  Voice Input  │     │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘     │
│          │                   │                   │              │
│          └───────────────────┼───────────────────┘              │
│                              ▼                                   │
│                    ┌─────────────────┐                          │
│                    │   MCP Client     │                          │
│                    │  (Dart Package)  │                          │
│                    └────────┬────────┘                          │
└─────────────────────────────┼───────────────────────────────────┘
                              │ MCP Protocol (JSON-RPC / stdio)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         MCP Server                               │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                    Router / Orchestrator                 │   │
│   │  • Capability detection (device, OS version, model avail)│   │
│   │  • Privacy policy enforcement                            │   │
│   │  • Fallback chain management                             │   │
│   │  • Response normalization                                │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         ▼                    ▼                    ▼             │
│   ┌───────────┐        ┌───────────┐        ┌───────────┐      │
│   │  On-Device │        │   Local    │        │   Cloud    │      │
│   │  Provider  │        │  Provider  │        │  Provider  │      │
│   └─────┬─────┘        └─────┬─────┘        └─────┬─────┘      │
│         │                    │                    │             │
└─────────┼────────────────────┼────────────────────┼─────────────┘
          ▼                    ▼                    ▼
    ┌───────────┐        ┌───────────┐        ┌───────────┐
    │ Apple FM  │        │  Ollama   │        │  OpenAI   │
    │ Gemini    │        │ llama.cpp │        │ Anthropic │
    │ Nano      │        │  LM Studio│        │  Gemini   │
    └───────────┘        └───────────┘        └───────────┘
```

### 4.2 Provider Types

| Provider Type | Examples | Network Required | Privacy Level | Latency |
|---|---|---|---|---|
| **On-Device** | `flutter_local_ai` — Apple Foundation Models (iOS 26+), ML Kit GenAI/Gemini Nano (Android API 26+) | No | Maximum | Low |
| **Local Server** | Ollama, llama.cpp, LM Studio, LocalAI | Local network only | High | Medium |
| **Cloud API** | OpenAI, Anthropic Claude, Google Gemini API, Azure OpenAI | Yes | Standard | Variable |

> **Note:** The `flutter_local_ai` package provides a **unified API** across iOS and Android, eliminating the need for separate MethodChannel implementations. Both platforms use native OS-level models with zero model downloads required.

### 4.3 Routing Logic

The MCP Server implements a **privacy-first fallback chain**. The app can request a preferred privacy level, and the server routes accordingly.

| Privacy Level | Routing Order | Use Case |
|---|---|---|
| `maximum` | On-Device only. Fail if unavailable. | Sensitive financial queries, PII involved |
| `high` | On-Device → Local Server → Fail | Default for banking Q&A |
| `standard` | On-Device → Local Server → Cloud API | General queries, non-sensitive |
| `any` | Fastest available provider | Development / testing only |

#### 4.3.1 Capability Detection

On app startup, the MCP Server probes available providers:

| Check | Method | Result |
|---|---|---|
| On-Device (iOS) | `FlutterLocalAi.instance.isAvailable()` | Available on iOS 26+ with Apple Intelligence enabled |
| On-Device (Android) | `FlutterLocalAi.instance.isAvailable()` | Available on Android API 26+ with Google AICore installed |
| Local Server (Ollama, etc.) | HTTP health check to configured endpoint | Available if server responds |
| Cloud API | API key presence + optional ping | Available if configured |

> **flutter_local_ai Availability Notes:**
> - **iOS:** Requires iOS 26.0+, device must have Apple Intelligence enabled in system settings
> - **Android:** Requires Google AICore system app (error code -101 indicates missing/outdated AICore)
> - **Initialization:** Call `FlutterLocalAi.instance.initialize()` on iOS (required) and Android (recommended)

### 4.4 MCP Server Modes

The MCP Server can run in different modes depending on deployment needs:

| Mode | Description | Use Case |
|---|---|---|
| **Embedded** | MCP Server logic runs within the Flutter app process via platform channels | Simplest deployment, on-device providers only |
| **Local Daemon** | MCP Server runs as a separate process on the same device | Supports local inference servers (Ollama) |
| **Remote** | MCP Server runs on a user's local network or cloud | Enterprise deployment, shared model access |

For the PoC, **Embedded mode** is the primary target, with **Local Daemon mode** as a stretch goal to demonstrate Ollama integration.

### 4.5 MCP Server Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| MCP-01 | Unified LLM interface | Single protocol for all LLM interactions regardless of provider | Must Have |
| MCP-02 | Provider abstraction | App never knows which provider is serving the request | Must Have |
| MCP-03 | Capability detection | Probe and cache available providers on startup | Must Have |
| MCP-04 | Privacy-level routing | Route requests based on requested privacy level | Must Have |
| MCP-05 | Streaming responses | Support token-by-token streaming from all providers | Must Have |
| MCP-06 | Fallback chain | Automatic fallback when preferred provider unavailable | Must Have |
| MCP-07 | Response normalization | Consistent response format regardless of provider | Must Have |
| MCP-08 | Provider health monitoring | Detect provider failures and update routing | Should Have |
| MCP-09 | Request timeout handling | Configurable timeouts per provider type | Should Have |
| MCP-10 | Ollama integration | Support local Ollama server as provider | Should Have |
| MCP-11 | Cloud API support | Support OpenAI/Anthropic/Gemini as fallback providers | Should Have |
| MCP-12 | Configuration API | Runtime configuration of providers and routing rules | Could Have |

### 4.6 MCP Protocol Messages

The MCP Server uses JSON-RPC 2.0 over stdio (embedded) or HTTP (daemon/remote).

#### Request: `llm/generate`

```json
{
  "jsonrpc": "2.0",
  "method": "llm/generate",
  "params": {
    "prompt": "What is my account balance?",
    "context": [...],
    "privacy_level": "high",
    "stream": true,
    "max_tokens": 256
  },
  "id": 1
}
```

#### Response (streaming):

```json
{"jsonrpc": "2.0", "result": {"type": "token", "content": "Your"}, "id": 1}
{"jsonrpc": "2.0", "result": {"type": "token", "content": " current"}, "id": 1}
{"jsonrpc": "2.0", "result": {"type": "token", "content": " balance"}, "id": 1}
...
{"jsonrpc": "2.0", "result": {"type": "done", "provider": "apple_foundation_models"}, "id": 1}
```

#### Request: `llm/capabilities`

```json
{
  "jsonrpc": "2.0",
  "method": "llm/capabilities",
  "params": {},
  "id": 2
}
```

#### Response:

```json
{
  "jsonrpc": "2.0",
  "result": {
    "providers": [
      {"id": "apple_fm", "type": "on_device", "available": true, "model": "apple-foundation-4b"},
      {"id": "ollama", "type": "local", "available": true, "model": "llama3.2:3b"},
      {"id": "openai", "type": "cloud", "available": true, "model": "gpt-4o-mini"}
    ],
    "default_privacy_level": "high"
  },
  "id": 2
}
```

### 4.7 Folder Structure Addition

```
lib/
├── core/
│   ├── mcp/
│   │   ├── mcp_client.dart           # Dart client for MCP protocol
│   │   ├── mcp_embedded_server.dart  # Embedded mode server logic
│   │   ├── providers/
│   │   │   ├── llm_provider.dart     # Abstract provider interface
│   │   │   ├── local_ai_provider.dart    # flutter_local_ai wrapper (iOS + Android)
│   │   │   ├── ollama_provider.dart      # Local Ollama server
│   │   │   └── cloud_api_provider.dart   # OpenAI/Anthropic/Gemini API
│   │   ├── router/
│   │   │   ├── capability_detector.dart
│   │   │   └── privacy_router.dart
│   │   └── models/
│   │       ├── mcp_request.dart
│   │       └── mcp_response.dart
```

> **Note:** `local_ai_provider.dart` wraps `flutter_local_ai` and handles both iOS (Apple Foundation Models) and Android (ML Kit GenAI) through a single implementation. No platform-specific provider code needed.

### 4.8 flutter_local_ai Integration

The `flutter_local_ai` package provides unified on-device LLM access. Here's how it integrates with the MCP Server:

#### 4.8.1 LocalAiProvider Implementation

```dart
// lib/core/mcp/providers/local_ai_provider.dart

import 'package:flutter_local_ai/flutter_local_ai.dart';

class LocalAiProvider implements LlmProvider {
  final FlutterLocalAi _localAi = FlutterLocalAi.instance;
  bool _initialized = false;

  @override
  String get providerId => 'local_ai';

  @override
  ProviderType get type => ProviderType.onDevice;

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) {
      await _localAi.initialize();
      _initialized = true;
    }
    return await _localAi.isAvailable();
  }

  @override
  Future<LlmResponse> generate(LlmRequest request) async {
    final response = await _localAi.generateText(
      prompt: request.prompt,
      // Note: streaming not yet supported in flutter_local_ai
    );

    return LlmResponse(
      text: response.text,
      provider: providerId,
      isOnDevice: true,
    );
  }

  // Pseudo-streaming until native streaming is available
  @override
  Stream<LlmChunk> generateStream(LlmRequest request) async* {
    final response = await generate(request);

    // Simulate streaming by chunking the response
    final words = response.text.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield LlmChunk(
        text: words[i] + (i < words.length - 1 ? ' ' : ''),
        isDone: i == words.length - 1,
        provider: providerId,
      );
      await Future.delayed(Duration(milliseconds: 30)); // Simulate typing
    }
  }
}
```

#### 4.8.2 Platform Requirements

| Platform | Requirement | Error Handling |
|---|---|---|
| **iOS** | iOS 26.0+, Apple Intelligence enabled | `isAvailable()` returns false; MCP routes to fallback |
| **Android** | API 26+, Google AICore installed | Error -101 indicates missing AICore; prompt user or fallback |
| **Windows** | Copilot+ PC with 40+ TOPS NPU | `isAvailable()` returns false; fallback to cloud |

#### 4.8.3 Initialization Flow

```dart
// In app startup (main.dart or locator.dart)

Future<void> initializeMcpProviders() async {
  final localAiProvider = LocalAiProvider();

  // Check availability and register
  if (await localAiProvider.isAvailable()) {
    mcpServer.registerProvider(localAiProvider, priority: 1); // Highest priority
    print('On-device LLM available');
  } else {
    print('On-device LLM not available, will use fallback');
  }

  // Register fallback providers
  mcpServer.registerProvider(OllamaProvider(), priority: 2);
  mcpServer.registerProvider(CloudApiProvider(), priority: 3);
}
```

#### 4.8.4 Known Limitations & Workarounds

| Limitation | Workaround | Status |
|---|---|---|
| No streaming support | Pseudo-streaming via word chunking | Implemented in provider |
| Tool calls iOS-only | Disable tool calls on Android, use cloud for tool-heavy queries | Configuration flag |
| AICore not pre-installed | Show user prompt to install Google AI Core from Play Store | UI flow needed |
| iOS requires initialization | Call `initialize()` on app startup before any LLM calls | Handled in provider |

---

## 5. Speech Services — STT/TTS Abstraction Layer

Similar to the MCP Server for LLM abstraction, the Speech Services layer provides a unified interface for Speech-to-Text (STT) and Text-to-Speech (TTS) functionality. The app interacts with abstract interfaces, enabling seamless swapping between on-device engines and enterprise cloud solutions (Azure, Google, AWS) without code changes.

### 5.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Banking App (Flutter)                     │
│                                                                  │
│   ┌──────────────┐                      ┌──────────────┐        │
│   │  Voice Input  │                      │ Voice Output  │        │
│   └──────┬───────┘                      └──────┬───────┘        │
│          │                                     │                 │
│          ▼                                     ▼                 │
│   ┌─────────────┐                       ┌─────────────┐         │
│   │ SttService  │                       │ TtsService  │         │
│   │ (Abstract)  │                       │ (Abstract)  │         │
│   └──────┬──────┘                       └──────┬──────┘         │
└──────────┼─────────────────────────────────────┼────────────────┘
           │                                     │
     ┌─────┴─────┐                         ┌─────┴─────┐
     ▼           ▼                         ▼           ▼
┌─────────┐ ┌─────────┐               ┌─────────┐ ┌─────────┐
│On-Device│ │ Cloud   │               │On-Device│ │ Cloud   │
│   STT   │ │   STT   │               │   TTS   │ │   TTS   │
└────┬────┘ └────┬────┘               └────┬────┘ └────┬────┘
     │           │                         │           │
     ▼           ▼                         ▼           ▼
 speech_to   Azure Speech              flutter_tts  Azure Speech
   _text     Google Cloud                           Google Cloud
             AWS Transcribe                         AWS Polly
```

### 5.2 Service Interfaces

#### SttService (Speech-to-Text)

```dart
abstract class SttService {
  Future<bool> initialize();
  Future<bool> isAvailable();
  Stream<SttResult> startListening({String? locale, bool partialResults = true});
  Future<void> stopListening();
  Future<void> dispose();
}

class SttResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final String? provider; // 'on_device', 'azure', 'google', etc.
}
```

#### TtsService (Text-to-Speech)

```dart
abstract class TtsService {
  Future<bool> initialize();
  Future<bool> isAvailable();
  Future<List<TtsVoice>> getVoices({String? locale});
  Future<void> speak(String text, {String? voiceId, double? rate, double? pitch});
  Future<void> stop();
  Stream<TtsState> get stateStream; // speaking, paused, stopped
  Future<void> dispose();
}

class TtsVoice {
  final String id;
  final String name;
  final String locale;
  final String provider;
}
```

### 5.3 Provider Implementations

| Provider | Type | STT Support | TTS Support | Offline | Notes |
|---|---|---|---|---|---|
| **On-Device (Default)** | Local | `speech_to_text` | `flutter_tts` | Yes | PoC default, zero latency, free |
| **Azure Cognitive Services** | Cloud | Azure Speech SDK | Azure Speech SDK | No | Enterprise-grade, 100+ languages, neural voices |
| **Google Cloud Speech** | Cloud | Cloud Speech-to-Text | Cloud Text-to-Speech | No | High accuracy, WaveNet voices |
| **AWS** | Cloud | Amazon Transcribe | Amazon Polly | No | Real-time transcription, NTTS voices |

### 5.4 Configuration

Speech service providers are configured at app initialization. The app reads configuration and instantiates the appropriate implementation via dependency injection.

```dart
// Example configuration in locator.dart
void setupSpeechServices(SpeechConfig config) {
  switch (config.provider) {
    case SpeechProvider.onDevice:
      locator.registerSingleton<SttService>(OnDeviceSttService());
      locator.registerSingleton<TtsService>(OnDeviceTtsService());
      break;
    case SpeechProvider.azure:
      locator.registerSingleton<SttService>(AzureSttService(config.azureKey, config.azureRegion));
      locator.registerSingleton<TtsService>(AzureTtsService(config.azureKey, config.azureRegion));
      break;
    // ... other providers
  }
}
```

### 5.5 Speech Services Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| SPEECH-01 | Abstract STT interface | `SttService` interface hides provider implementation | Must Have |
| SPEECH-02 | Abstract TTS interface | `TtsService` interface hides provider implementation | Must Have |
| SPEECH-03 | On-device STT | Default implementation using `speech_to_text` package | Must Have |
| SPEECH-04 | On-device TTS | Default implementation using `flutter_tts` package | Must Have |
| SPEECH-05 | Provider swap via config | Switch providers without code changes, only configuration | Must Have |
| SPEECH-06 | Partial results (STT) | Stream partial transcription results for real-time feedback | Must Have |
| SPEECH-07 | Voice selection (TTS) | Allow user to select from available voices | Should Have |
| SPEECH-08 | Locale support | Both STT and TTS respect device/user locale settings | Must Have |
| SPEECH-09 | Azure STT provider | Implementation ready for Azure Speech Services (STT) | Could Have |
| SPEECH-10 | Azure TTS provider | Implementation ready for Azure Speech Services (TTS) | Could Have |
| SPEECH-11 | Fallback chain | If cloud provider fails, fall back to on-device | Should Have |
| SPEECH-12 | Provider indicator | UI shows which provider is active (for transparency) | Could Have |

### 5.6 Folder Structure Addition

```
lib/
├── core/
│   ├── speech/
│   │   ├── stt_service.dart              # Abstract STT interface
│   │   ├── tts_service.dart              # Abstract TTS interface
│   │   ├── speech_config.dart            # Configuration model
│   │   ├── providers/
│   │   │   ├── on_device_stt_service.dart
│   │   │   ├── on_device_tts_service.dart
│   │   │   ├── azure_stt_service.dart    # Future: Azure implementation
│   │   │   ├── azure_tts_service.dart    # Future: Azure implementation
│   │   │   └── ...                       # Other cloud providers
│   │   └── models/
│   │       ├── stt_result.dart
│   │       └── tts_voice.dart
```

---

## 6. Feature Requirements

### 5.1 Authentication

The login screen is the application entry point for all non-deep-linked launches. For deep-linked launches (via Siri or App Actions), the auth gate intercepts the route, authenticates the user, and redirects to the original target.

| ID | Requirement | Details | Priority |
|---|---|---|---|
| AUTH-01 | Biometric login | Face ID (iOS), Fingerprint / Face (Android) via `local_auth` | Must Have |
| AUTH-02 | PIN fallback | 6-digit PIN when biometric unavailable or fails. SHA-256 hashed before storage. | Must Have |
| AUTH-03 | Secure token storage | Session token in Keychain / Keystore via `flutter_secure_storage` | Must Have |
| AUTH-04 | Deep link auth gate | go_router redirect checks auth state before any protected route | Must Have |
| AUTH-05 | Session timeout | Auto-lock after 5 minutes of inactivity. Biometric re-auth to resume. | Should Have |
| AUTH-06 | Failed attempt lockout | Lock for 30 seconds after 5 consecutive PIN failures | Should Have |

---

### 5.2 Adaptive Hub Screen

The hub is the application's main screen after login. It is not a static layout — it is a dynamically composed widget tree produced by `HubWidgetFactory`, which resolves the user's `HubProfileEntity` from OS accessibility signals and stored user preferences.

#### 5.2.1 Profile Resolution Signals

| Signal | Source & Trigger |
|---|---|
| Screen reader active | `MediaQuery.accessibleNavigation` — VoiceOver (iOS) or TalkBack (Android) is on |
| High contrast | `MediaQuery.highContrast` — OS-level high contrast setting enabled |
| Color blindness | `UserProfile` flag — set by user in app settings (deuteranopia, protanopia, tritanopia) |
| Large text / elderly | `MediaQuery.textScaleFactor >= 1.4` — OS text size accessibility setting |
| Reduce motion | `MediaQuery.disableAnimations` — Reduce Motion enabled in OS settings |
| Manual override | `UserProfile.preferredLayout` — user-selected in app: 'Standard', 'Compact', 'Accessibility' |

#### 5.2.2 Hub Layouts

| Layout | Trigger | Characteristics | Priority |
|---|---|---|---|
| Standard | No accessibility flags | 3-col grid, animated tiles, balance summary, chat FAB | Must Have |
| Assistive | Screen reader active | 1-col list, full-width semantic buttons, no icon-only labels | Must Have |
| Large text | textScaleFactor >= 1.4 | 2-col grid, 80dp+ tiles, 18sp+ text, tab bar with labels always visible | Must Have |
| Color-blind | Color blindness flag set | Deuteranopia-safe palette via ThemeExtension, pattern differentiation | Must Have |
| High contrast | highContrast = true | Maximum contrast tokens, 2px borders, no subtle backgrounds | Should Have |
| No motion | reduceMotion = true | All animations disabled (0 duration), no entrance transitions | Should Have |

#### 5.2.3 Hub Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| HUB-01 | Dynamic layout composition | `HubWidgetFactory` produces the correct layout from `HubProfileEntity` | Must Have |
| HUB-02 | Live re-resolution | Hub rebuilds if OS accessibility settings change mid-session | Must Have |
| HUB-03 | Chat FAB always present | Floating action button to open chat assistant on all hub layouts | Must Have |
| HUB-04 | Quick actions | Balance, Transfer, Pay Bills, Cards accessible from hub without nav | Must Have |
| HUB-05 | Manual profile override | User can pin a layout preference that overrides auto-detection | Should Have |
| HUB-06 | Semantic labels | All hub tiles have `Semantics` wrappers with meaningful labels | Must Have |

---

### 5.3 Voice Assistant Integration

Voice assistant integration is handled by the **`flutter_app_intents`** package, providing a unified Dart API for both iOS and Android. The package abstracts platform-specific implementations (App Intents for iOS, App Actions for Android) behind a single interface.

> **Note:** `flutter_app_intents` currently supports iOS (Siri, Shortcuts, Spotlight). Android (Google Assistant App Actions) support is in development and will be available in a future release.

#### 5.3.1 flutter_app_intents Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Banking App (Flutter)                       │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              flutter_app_intents                         │   │
│   │         (Unified Voice Assistant API)                    │   │
│   └─────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
     ┌─────────────────┐             ┌─────────────────┐
     │      iOS        │             │    Android      │
     │  App Intents    │             │  App Actions    │
     │  (Siri, etc.)   │             │ (Google Asst.)  │
     └────────┬────────┘             └────────┬────────┘
              │                               │
              │     ✅ Available              │     🚧 Coming Soon
              │                               │
              └───────────────┬───────────────┘
                              ▼
                    ┌─────────────────┐
                    │    app_links    │
                    │  (Deep Links)   │
                    └────────┬────────┘
                             ▼
                    ┌─────────────────┐
                    │    go_router    │
                    │  (Navigation)   │
                    └─────────────────┘
```

#### 5.3.2 Supported Voice Commands

| Command (example) | Platform | Intent Type | Deep Link | Priority |
|---|---|---|---|---|
| "Hey Siri, show my balance in BankApp" | iOS | Query | `bankingapp://balance` | Must Have |
| "Hey Siri, transfer money in BankApp" | iOS | Action | `bankingapp://transfer` | Must Have |
| "Hey Siri, pay my bills in BankApp" | iOS | Action | `bankingapp://pay-bills` | Must Have |
| "Hey Google, show my balance in BankApp" | Android | Query | `bankingapp://balance` | Must Have |
| "Hey Google, transfer $50 to John in BankApp" | Android | Action | `bankingapp://transfer?to=John&amount=50` | Should Have |
| "Hey Siri, show my cards in BankApp" | iOS | Navigation | `bankingapp://cards` | Should Have |

#### 5.3.3 Intent Registration (Dart API)

```dart
// lib/core/intents/banking_intents.dart

import 'package:flutter_app_intents/flutter_app_intents.dart';

class BankingIntents {
  static void register() {
    FlutterAppIntents.instance.registerIntents([
      AppIntent(
        id: 'show_balance',
        title: 'Show Balance',
        description: 'Display account balance',
        type: IntentType.query,
        phrases: ['show my balance', 'check balance', 'how much money'],
        deepLink: 'bankingapp://balance',
      ),
      AppIntent(
        id: 'transfer_money',
        title: 'Transfer Money',
        description: 'Send money to a contact',
        type: IntentType.action,
        phrases: ['transfer money', 'send money', 'pay someone'],
        deepLink: 'bankingapp://transfer',
        parameters: [
          IntentParameter(name: 'to', type: ParameterType.string),
          IntentParameter(name: 'amount', type: ParameterType.double),
        ],
      ),
      AppIntent(
        id: 'pay_bills',
        title: 'Pay Bills',
        description: 'Pay your bills',
        type: IntentType.action,
        phrases: ['pay bills', 'pay my bills'],
        deepLink: 'bankingapp://pay-bills',
      ),
      AppIntent(
        id: 'show_cards',
        title: 'Show Cards',
        description: 'View and manage cards',
        type: IntentType.navigation,
        phrases: ['show my cards', 'view cards', 'card management'],
        deepLink: 'bankingapp://cards',
      ),
    ]);
  }
}
```

#### 5.3.4 Deep Link Flow

1. User speaks to Siri or Google Assistant.
2. `flutter_app_intents` handles the platform-specific intent resolution.
3. Intent triggers `bankingapp://` deep link with any parameters.
4. `app_links` delivers the URI to Flutter (cold start or resume).
5. `go_router` checks auth state via redirect guard.
6. If unauthenticated: navigate to `/login`, then redirect to original URI after success.
7. Target screen loads, pre-populated with any parameters from the URI.

#### 5.3.5 Voice Assistant Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| VOICE-01 | Siri integration | Register App Intents via `flutter_app_intents` for iOS 16+ | Must Have |
| VOICE-02 | Google Assistant integration | Register App Actions via `flutter_app_intents` (when available) | Must Have |
| VOICE-03 | Deep link handling | Use `app_links` for unified deep link reception | Must Have |
| VOICE-04 | Auth gate | Intercept deep links, require auth before protected screens | Must Have |
| VOICE-05 | Parameter parsing | Extract and validate parameters from deep link URIs | Must Have |
| VOICE-06 | Shortcuts support | Expose intents to iOS Shortcuts app | Should Have |
| VOICE-07 | Spotlight indexing | Index banking actions for Spotlight search (iOS) | Should Have |
| VOICE-08 | Intent donation | Donate user actions to improve Siri suggestions | Should Have |

---

### 5.4 Chat Assistant (MCP-Powered)

The chat assistant is accessible via the hub FAB. It accepts both text and voice input. **All LLM interactions go through the MCP Server**, which routes requests to the appropriate provider based on privacy level and availability. The app is completely unaware of which provider is serving the response.

| ID | Requirement | Details | Priority |
|---|---|---|---|
| CHAT-01 | Text input | Standard text field with send button. Supports emoji and copy/paste. | Must Have |
| CHAT-02 | Voice input | Microphone button triggers `SttService`. Transcribed text auto-fills input. Provider-agnostic. | Must Have |
| CHAT-03 | Voice output | `TtsService` reads assistant replies aloud when voice mode is active. Provider-agnostic. | Should Have |
| CHAT-04 | Streaming responses | Tokens stream in real time via MCP protocol. Typing indicator while generating. | Must Have |
| CHAT-05 | MCP integration | All LLM requests routed through MCP Client to MCP Server. | Must Have |
| CHAT-06 | Privacy level selection | User can set preferred privacy level (maximum, high, standard) in settings. | Must Have |
| CHAT-07 | Conversation history | Last 10 messages kept in `ChatMessageEntity` as context for the LLM. | Should Have |
| CHAT-08 | Error handling | Graceful message if no LLM provider available at requested privacy level. | Must Have |
| CHAT-09 | Provider indicator | Dynamic label showing privacy status: "On-device", "Local server", or "Cloud". | Must Have |
| CHAT-10 | Fallback consent | If cloud fallback needed, prompt user for one-time or session consent. | Should Have |

---

### 5.5 Banking Features

| Feature | Key Screens / Flows | Deep Link | Priority |
|---|---|---|---|
| Account balance & summary | Balance tile on hub, dedicated balance screen with account breakdown | `bankingapp://balance` | Must Have |
| Transfer money | Payee selector, amount entry, confirmation, success. Pre-fillable via deep link. | `bankingapp://transfer` | Must Have |
| Transaction history | Paginated list, date and type filters, transaction detail sheet | `bankingapp://transactions` | Must Have |
| Pay bills | Biller list, scheduled vs immediate, amount and date selection, confirmation | `bankingapp://pay-bills` | Must Have |
| Card management | Card list, freeze/unfreeze toggle, spend limits, virtual card number reveal | `bankingapp://cards` | Must Have |

---

## 7. UI Design System

This section defines the visual language, component library, and screen layouts for BankApp. The design system is built to support adaptive layouts and accessibility-first principles.

### 7.1 Design Principles

| Principle | Description |
|---|---|
| **Inclusive by default** | Every component designed for accessibility first, not as an afterthought |
| **Adaptive, not responsive** | Layouts transform based on user needs, not just screen size |
| **Clarity over decoration** | Clean, scannable interfaces; no gratuitous animations or visual noise |
| **Consistent and predictable** | Same patterns across all features; users learn once, use everywhere |
| **Privacy-visible** | Always communicate data handling (on-device vs cloud indicators) |

---

### 7.2 Design Tokens

#### 7.2.1 Color Palette

**Primary Palette (Light Mode)**

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#1A56DB` | Primary actions, links, focus states |
| `primary-dark` | `#1E429F` | Pressed states, dark accents |
| `primary-light` | `#E1EFFE` | Backgrounds, highlights |
| `secondary` | `#0E9F6E` | Success states, positive values, income |
| `secondary-dark` | `#046C4E` | Pressed success states |
| `error` | `#F05252` | Error states, negative values, expenses |
| `error-dark` | `#C81E1E` | Pressed error states |
| `warning` | `#C27803` | Warnings, pending states |
| `neutral-900` | `#111928` | Primary text |
| `neutral-700` | `#374151` | Secondary text |
| `neutral-500` | `#6B7280` | Placeholder text, icons |
| `neutral-300` | `#D1D5DB` | Borders, dividers |
| `neutral-100` | `#F3F4F6` | Card backgrounds |
| `neutral-50` | `#F9FAFB` | Page backgrounds |
| `white` | `#FFFFFF` | Surface backgrounds |

**Dark Mode Palette**

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#3F83F8` | Primary actions (lighter for dark bg) |
| `primary-light` | `#1E3A5F` | Backgrounds, highlights |
| `secondary` | `#31C48D` | Success states |
| `error` | `#F98080` | Error states |
| `neutral-900` | `#F9FAFB` | Primary text (inverted) |
| `neutral-700` | `#E5E7EB` | Secondary text |
| `neutral-500` | `#9CA3AF` | Placeholder text |
| `neutral-300` | `#4B5563` | Borders, dividers |
| `neutral-100` | `#1F2A37` | Card backgrounds |
| `neutral-50` | `#111928` | Page backgrounds |
| `surface` | `#1F2A37` | Surface backgrounds |

**Color-Blind Safe Palette (Deuteranopia)**

| Standard Color | Adjusted Color | Hex | Pattern Backup |
|---|---|---|---|
| Green (success) | Blue | `#3B82F6` | Checkmark icon + "Success" label |
| Red (error) | Orange | `#F97316` | X icon + "Error" label |
| Yellow (warning) | Purple | `#8B5CF6` | Warning triangle + "Warning" label |

**High Contrast Palette**

| Token | Hex | Notes |
|---|---|---|
| `text` | `#000000` | Pure black text |
| `background` | `#FFFFFF` | Pure white background |
| `primary` | `#0000EE` | Standard link blue |
| `border` | `#000000` | 2px solid borders on all interactive elements |

#### 7.2.2 Typography

| Token | Font | Size | Weight | Line Height | Usage |
|---|---|---|---|---|---|
| `display-lg` | System Default | 32sp | 700 | 1.2 | Balance amounts, hero numbers |
| `display-md` | System Default | 24sp | 700 | 1.25 | Screen titles |
| `heading-lg` | System Default | 20sp | 600 | 1.3 | Section headers |
| `heading-md` | System Default | 18sp | 600 | 1.35 | Card titles |
| `body-lg` | System Default | 16sp | 400 | 1.5 | Primary body text |
| `body-md` | System Default | 14sp | 400 | 1.5 | Secondary body text |
| `body-sm` | System Default | 12sp | 400 | 1.4 | Captions, timestamps |
| `label` | System Default | 14sp | 500 | 1.2 | Button labels, form labels |
| `mono` | System Monospace | 16sp | 400 | 1.4 | Account numbers, amounts |

> **Note:** Using system fonts ensures optimal rendering and accessibility on each platform. iOS uses SF Pro, Android uses Roboto.

#### 7.2.3 Spacing Scale

| Token | Value | Usage |
|---|---|---|
| `space-0` | 0dp | No spacing |
| `space-1` | 4dp | Tight spacing (icon padding) |
| `space-2` | 8dp | Compact spacing (inline elements) |
| `space-3` | 12dp | Default component padding |
| `space-4` | 16dp | Card padding, list item spacing |
| `space-5` | 20dp | Section spacing |
| `space-6` | 24dp | Large section spacing |
| `space-8` | 32dp | Screen edge margins |
| `space-10` | 40dp | Major section breaks |
| `space-12` | 48dp | Minimum touch target |

#### 7.2.4 Elevation & Shadows

| Token | Elevation | Shadow | Usage |
|---|---|---|---|
| `elevation-0` | 0dp | None | Flat surfaces |
| `elevation-1` | 1dp | `0 1px 2px rgba(0,0,0,0.05)` | Cards, list items |
| `elevation-2` | 2dp | `0 2px 4px rgba(0,0,0,0.1)` | Raised buttons, dropdowns |
| `elevation-3` | 4dp | `0 4px 8px rgba(0,0,0,0.12)` | Modals, bottom sheets |
| `elevation-4` | 8dp | `0 8px 16px rgba(0,0,0,0.15)` | FAB, dialogs |

#### 7.2.5 Border Radius

| Token | Value | Usage |
|---|---|---|
| `radius-none` | 0dp | Sharp corners |
| `radius-sm` | 4dp | Buttons, inputs |
| `radius-md` | 8dp | Cards, tiles |
| `radius-lg` | 12dp | Bottom sheets, modals |
| `radius-xl` | 16dp | Large cards |
| `radius-full` | 9999dp | Pills, avatars, FAB |

---

### 7.3 Component Library

#### 7.3.1 Buttons

```
┌���────────────────────────────────────────────────────────────────┐
│  PRIMARY BUTTON                                                 │
│  ┌─────────────────────┐  ┌─────────────────────┐              │
│  │    Transfer Now     │  │    Transfer Now     │  (Pressed)   │
│  └─────────────────────┘  └─────────────────────┘              │
│  bg: primary              bg: primary-dark                      │
│  text: white              text: white                           │
│  height: 48dp             radius: radius-sm                     │
│  padding: 16dp horizontal                                       │
├─────────────────────────────────────────────────────────────────┤
│  SECONDARY BUTTON (Outlined)                                    │
│  ┌─────────────────────┐  ┌─────────────────────┐              │
│  │      Cancel         │  │      Cancel         │  (Pressed)   │
│  └─────────────────────┘  └─────────────────────┘              │
│  bg: transparent          bg: neutral-100                       │
│  border: 1px primary      text: primary-dark                    │
│  text: primary                                                  │
├─────────────────────────────────────────────────────────────────┤
│  TEXT BUTTON                                                    │
│  ┌─────────────────────┐                                       │
│  │    Learn More →     │                                       │
│  └─────────────────────┘                                       │
│  bg: transparent                                                │
│  text: primary                                                  │
│  padding: 8dp                                                   │
├─────────────────────────────────────────────────────────────────┤
│  ICON BUTTON                                                    │
│  ┌────┐  ┌────┐  ┌────┐                                        │
│  │ ☰  │  │ ← │  │ ⋮  │                                        │
│  └────┘  └────┘  └────┘                                        │
│  size: 48x48dp (touch target)                                   │
│  icon: 24x24dp                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Button States:**
| State | Visual Change |
|---|---|
| Default | Base colors |
| Hover | 10% darker background (desktop) |
| Pressed | 20% darker background |
| Focused | 2px primary outline, 2dp offset |
| Disabled | 40% opacity, no interaction |
| Loading | Spinner replaces text, disabled |

#### 7.3.2 Cards

```
┌─────────────────────────────────────────────────────────────────┐
│  BALANCE CARD                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Available Balance                               👁      │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  $12,450.00                                     │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │  Checking ••••4582                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│  bg: white                padding: space-4                      │
│  radius: radius-md        elevation: elevation-1                │
│  Eye icon toggles balance visibility                            │
├─────────────────────────────────────────────────────────────────┤
│  ACTION TILE (Hub)                                              │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐                   │
│  │     💳    │  │     📤    │  │     📄    │                   │
│  │           │  │           │  │           │                   │
│  │  Cards    │  │ Transfer  │  │   Bills   │                   │
│  └───────────┘  └───────────┘  └───────────┘                   │
│  size: 100x100dp (standard)     size: 80x80dp (compact)        │
│  icon: 32dp                     radius: radius-md               │
│  label: body-md                 bg: neutral-100                 │
├─────────────────────────────────────────────────────────────────┤
│  TRANSACTION ITEM                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🛒  Whole Foods Market                        -$82.50  │   │
│  │      Groceries · Today, 2:34 PM                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│  height: 72dp               padding: space-4                    │
│  icon/avatar: 40dp          negative: error color               │
│  Swipe actions: hide, dispute (optional)                        │
└─────────────────────────────────────────────────────────────────┘
```

#### 7.3.3 Inputs

```
┌─────────────────────────────────────────────────────────────────┐
│  TEXT INPUT                                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Amount                                                  │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │ $ │ 150.00                                      │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │  Enter amount between $1 and $10,000                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│  Label: body-md, neutral-700    Helper: body-sm, neutral-500   │
│  Input height: 48dp             Border: 1px neutral-300        │
│  Focus border: 2px primary      Error border: 2px error        │
├─────────────────────────────────────────────────────────────────┤
│  TEXT INPUT (Error State)                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Amount                                                  │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │ $ │ 50000.00                              ⚠️   │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │  ⚠️ Amount exceeds daily limit of $10,000              │   │
│  └─────────────────────────────────────────────────────────┘   │
│  Error message: body-sm, error                                  │
│  Icon + text for accessibility (not color alone)                │
├─────────────────────────────────────────────────────────────────┤
│  DROPDOWN / SELECT                                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  From Account                                            │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  Checking ••••4582                          ▼   │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│  Chevron indicates expandable                                   │
│  Opens bottom sheet on mobile                                   │
├─────────────────────────────────────────────────────────────────┤
│  PIN INPUT                                                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            Enter your 6-digit PIN                        │   │
│  │        ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐            │   │
│  │        │ ● │ │ ● │ │ ● │ │   │ │   │ │   │            │   │
│  │        └───┘ └───┘ └───┘ └───┘ └───┘ └───┘            │   │
│  └─────────────────────────────────────────────────────────┘   │
│  Cell size: 48x48dp         Filled: neutral-900 dot            │
│  Cell spacing: space-2      Empty: neutral-300 border          │
└─────────────────────────────────────────────────────────────────┘
```

#### 7.3.4 Navigation

```
┌─────────────────────────────────────────────────────────────────┐
│  TOP APP BAR                                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ←    Transfer Money                              ⋮     │   │
│  └─────────────────────────────────────────────────────────┘   │
│  height: 56dp               bg: white                           │
│  title: heading-md          elevation: elevation-1              │
│  back icon: 24dp            action icons: 24dp                  │
├─────────────────────────────────────────────────────────────────┤
│  BOTTOM NAVIGATION BAR                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │   🏠        💳        📤        📊        ⚙️          │   │
│  │  Home     Cards   Transfer   Activity  Settings        │   │
│  └─────────────────────────────────────────────────────────┘   │
│  height: 64dp               bg: white                           │
│  icon: 24dp                 label: body-sm                      │
│  active: primary            inactive: neutral-500               │
│  Labels always visible (accessibility)                          │
├─────────────────────────────────────────────────────────────────┤
│  FLOATING ACTION BUTTON (Chat)                                  │
│                                                    ┌────────┐  │
│                                                    │   💬   │  │
│                                                    └────────┘  │
│  size: 56x56dp              bg: primary                         │
│  icon: 24dp white           elevation: elevation-4              │
│  position: bottom-right     margin: space-4 from edges          │
│  Always visible on hub                                          │
└─────────────────────────────────────────────────────────────────┘
```

#### 7.3.5 Chat Components

```
┌─────────────────────────────────────────────────────────────────┐
│  CHAT SCREEN                                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ←    Banking Assistant                    🔒 On-device  │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │                                                          │   │
│  │  ┌─────────────────────────────────────┐                │   │
│  │  │ What's my current balance?          │  ← User        │   │
│  │  └─────────────────────────────────────┘                │   │
│  │                                                          │   │
│  │       ┌─────────────────────────────────────┐           │   │
│  │       │ Your checking account ending in     │ ← Bot     │   │
│  │       │ 4582 has a balance of $12,450.00.  │           │   │
│  │       └─────────────────────────────────────┘           │   │
│  │                                                          │   │
│  │  ┌─────────────────────────────────────┐                │   │
│  │  │ Transfer $50 to Mom                 │  ← User        │   │
│  │  └─────────────────────────────────────┘                │   │
│  │                                                          │   │
│  │       ┌─────────────────────────────────────┐           │   │
│  │       │ ●●● typing...                       │ ← Loading │   │
│  │       └─────────────────────────────────────┘           │   │
│  │                                                          │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  ┌─────────────────────────────────┐  ┌────┐  ┌────┐   │   │
│  │  │ Type a message...               │  │ 🎤 │  │ ➤  │   │   │
│  │  └─────────────────────────────────┘  └────┘  └────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  User bubble: bg primary-light, text neutral-900, right-align  │
│  Bot bubble: bg neutral-100, text neutral-900, left-align      │
│  Privacy indicator: top-right, shows "On-device" or "Cloud"    │
│  Mic button: triggers SttService                                │
│  Send button: disabled when empty                               │
└─────────────────────────────────────────────────────────────────┘
```

---

### 7.4 Screen Layouts

#### 7.4.1 Login Screen

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│              ┌───────────┐              │
│              │   LOGO    │              │
│              │  BankApp  │              │
│              └───────────┘              │
│                                         │
│            Welcome back                 │
│                                         │
│         ┌───────────────────┐           │
│         │      [Face ID]    │           │
│         │                   │           │
│         │   Use Face ID to  │           │
│         │      sign in      │           │
│         └───────────────────┘           │
│                                         │
│         ┌───────────────────┐           │
│         │   Use PIN Instead │           │
│         └───────────────────┘           │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘

States:
- Biometric prompt (primary)
- PIN entry (fallback)
- Loading (authenticating)
- Error (failed attempt)
```

#### 7.4.2 Hub Screen — Standard Layout

```
┌─────────────────────────────────────────┐
│  Good morning, Alex                  ⚙️ │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │  Available Balance              👁  ││
│  │  $12,450.00                         ││
│  │  Checking ••••4582                  ││
│  └─────────────────────────────────────┘│
│                                         │
│  Quick Actions                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │   💳    │ │   📤    │ │   📄    │   │
│  │  Cards  │ │Transfer │ │  Bills  │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
│  Recent Activity                        │
│  ┌─────────────────────────────────────┐│
│  │ 🛒 Whole Foods          -$82.50    ││
│  │    Today, 2:34 PM                   ││
│  ├─────────────────────────────────────┤│
│  │ 💰 Payroll Deposit    +$3,200.00   ││
│  │    Yesterday                        ││
│  ├─────────────────────────────────────┤│
│  │ ☕ Starbucks              -$6.45    ││
│  │    Yesterday                        ││
│  └─────────────────────────────────────┘│
│                                    ┌───┐│
│  ┌────┬────┬────┬────┬────┐       │💬││
│  │ 🏠 │ 💳 │ 📤 │ 📊 │ ⚙️ │       └───┘│
│  │Home│Card│Send│Act.│Set.│             │
│  └────┴────┴────┴────┴────┘             │
└─────────────────────────────────────────┘
```

#### 7.4.3 Hub Screen — Assistive Layout (VoiceOver/TalkBack)

```
┌─────────────────────────────────────────┐
│  Good morning, Alex                  ⚙️ │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💰  View Balance                   ││
│  │      Available: $12,450.00          ││
│  │      Checking account ending 4582 → ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📤  Transfer Money               → ││
│  │      Send money to contacts         ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📄  Pay Bills                    → ││
│  │      Pay upcoming bills             ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💳  Manage Cards                 → ││
│  │      View and control your cards    ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💬  Chat Assistant               → ││
│  │      Ask questions about banking    ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌────┬────┬────┬────┬────┐             │
│  │ 🏠 │ 💳 │ 📤 │ 📊 │ ⚙️ │             │
│  │Home│Card│Send│Act.│Set.│             │
│  └────┴────┴────┴────┴────┘             │
└─────────────────────────────────────────┘

Key differences:
- Single column, full-width buttons
- No icon-only elements
- Descriptive labels on all actions
- Logical focus order (top to bottom)
- Chat FAB replaced with inline button
- Minimum 72dp touch targets
```

#### 7.4.4 Hub Screen — Large Text Layout

```
┌─────────────────────────────────────────┐
│  Good morning,                       ⚙️ │
│  Alex                                   │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │  Available Balance             👁   ││
│  │                                     ││
│  │  $12,450.00                        ││
│  │                                     ││
│  │  Checking ••••4582                  ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────┐   ┌─────────────┐     │
│  │             │   │             │     │
│  │     💳      │   │     📤      │     │
│  │             │   │             │     │
│  │   Cards     │   │  Transfer   │     │
│  │             │   │             │     │
│  └─────────────┘   └─────────────┘     │
│                                         │
│  ┌─────────────┐   ┌─────────────┐     │
│  │             │   │             │     │
│  │     📄      │   │     📊      │     │
│  │             │   │             │     │
│  │   Bills     │   │  Activity   │     │
│  │             │   │             │     │
│  └─────────────┘   └─────────────┘     │
│                                    ┌───┐│
│  ┌────┬────┬────┬────┬────┐       │💬││
│  │ 🏠 │ 💳 │ 📤 │ 📊 │ ⚙️ │       └───┘│
│  │Home│Card│Send│Act.│Set.│             │
│  └────┴────┴────┴────┴────┘             │
└─────────────────────────────────────────┘

Key differences:
- 2-column grid instead of 3
- Larger tiles (80dp+ height)
- 18sp+ text minimum
- More vertical spacing
- Labels always visible on nav bar
- No transaction list (separate screen)
```

#### 7.4.5 Transfer Screen

```
┌─────────────────────────────────────────┐
│  ←    Transfer Money                    │
├─────────────────────────────────────────┤
│                                         │
│  From                                   │
│  ┌─────────────────────────────────────┐│
│  │  Checking ••••4582              ▼   ││
│  │  Available: $12,450.00              ││
│  └─────────────────────────────────────┘│
│                                         │
│  To                                     │
│  ┌─────────────────────────────────────┐│
│  │  Select recipient               ▼   ││
│  └─────────────────────────────────────┘│
│                                         │
│  Amount                                 │
│  ┌─────────────────────────────────────┐│
│  │  $  │                               ││
│  └─────────────────────────────────────┘│
│                                         │
│  Note (optional)                        │
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │          Review Transfer            ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

#### 7.4.6 Card Management Screen

```
┌─────────────────────────────────────────┐
│  ←    My Cards                          │
├─────────────────────────────────────────┤
│                                         │
│     ┌─────────────────────────────┐     │
│     │  ████████████████████████   │     │
│     │                             │     │
│     │  •••• •••• •••• 4582       │     │
│     │                             │     │
│     │  ALEX JOHNSON     VISA      │     │
│     │  Exp: 12/27                 │     │
│     └─────────────────────────────┘     │
│           ●  ○  ○  (card indicator)     │
│                                         │
│  Card Status                            │
│  ┌─────────────────────────────────────┐│
│  │  Card Active                   🟢   ││
│  │  ┌─────────────────────────────┐   ││
│  │  │░░░░░░░░░░░░░░░░░░░░░░░░░░░░│   ││
│  │  └─────────────────────────────┘   ││
│  │  Tap to freeze card                 ││
│  └─────────────────────────────────────┘│
│                                         │
│  Quick Actions                          │
│  ┌─────────────┐   ┌─────────────┐     │
│  │  Show Card  │   │   Spend     │     │
│  │   Number    │   │   Limits    │     │
│  └─────────────┘   └─────────────┘     │
│                                         │
│  ┌─────────────┐   ┌─────────────┐     │
│  │  Report     │   │   Order     │     │
│  │   Lost      │   │  New Card   │     │
│  └─────────────┘   └─────────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

---

### 7.5 Animation Guidelines

| Animation | Duration | Curve | Reduce Motion Behavior |
|---|---|---|---|
| Screen transitions | 300ms | `easeInOut` | Instant (0ms) |
| Button press | 100ms | `easeOut` | Instant |
| Card expand/collapse | 250ms | `easeInOut` | Instant |
| FAB entrance | 200ms | `easeOut` | No animation, visible immediately |
| Loading spinner | Continuous | Linear | Static progress indicator |
| Pull to refresh | 150ms | `easeOut` | Instant |
| Bottom sheet slide | 250ms | `easeOut` | Instant |
| Chat message appear | 150ms | `easeOut` | Instant |

> **Note:** All animations respect `MediaQuery.disableAnimations`. When true, duration becomes 0ms and animations are skipped entirely.

---

### 7.6 Iconography

| Category | Style | Size | Source |
|---|---|---|---|
| Navigation icons | Outlined | 24dp | Material Symbols |
| Action icons | Filled | 24dp | Material Symbols |
| Feature icons | Filled | 32dp | Material Symbols |
| Status icons | Filled | 16dp | Material Symbols |

**Icon Color Rules:**
- Interactive icons: `primary` or `neutral-700`
- Decorative icons: `neutral-500`
- Status icons: Semantic color (success, error, warning)
- Always pair with text label for accessibility (no icon-only buttons except app bar)

---

### 7.7 Accessibility Checklist (Design)

| Requirement | Implementation |
|---|---|
| Touch targets | Minimum 48x48dp for all interactive elements |
| Color contrast | 4.5:1 for normal text, 3:1 for large text and icons |
| Focus indicators | 2px outline, visible on all focusable elements |
| Text scaling | UI functional at 200% text scale |
| No color-only info | Icons, patterns, or labels accompany color indicators |
| Motion respect | All animations disabled when reduce motion enabled |
| Screen reader labels | Every interactive element has semantic label |
| Error identification | Errors announced, not just color-coded |
| Consistent navigation | Same navigation pattern on all screens |
| Skip links | "Skip to content" for keyboard users (future/web) |

---

## 8. Package Dependencies

| Package | Version | Purpose |
|---|---|---|
| `clean_framework` | ^0.4.2 | Core architecture: Bloc, UseCase, ServiceAdapter, Entity, ViewModel |
| `provider` | ^5.0.0 | DI via locator.dart (bundled with clean_framework) |
| `equatable` | ^2.0.0 | Entity and ViewModel equality (bundled with clean_framework) |
| `http` | ^0.13.3 | REST client used by EitherService (bundled with clean_framework) |
| `go_router` | ^13.x | Declarative routing, deep link handling, auth redirect guards |
| `app_links` | ^6.x | Unified deep link handling (iOS, Android, desktop) — replaces uni_links |
| `flutter_app_intents` | ^0.7.0+ | Unified voice assistant API: Siri/Shortcuts/Spotlight (iOS), App Actions (Android — coming soon) |
| `local_auth` | ^2.2.0 | Biometric authentication — Face ID, Touch ID, Fingerprint |
| `flutter_secure_storage` | ^9.x | Keychain / Keystore for tokens and sensitive data |
| `crypto` | ^3.0.3 | SHA-256 PIN hashing before secure storage |
| `flutter_local_ai` | ^0.0.6+ | Unified on-device LLM: Apple Foundation Models (iOS 26+), ML Kit GenAI/Gemini Nano (Android) |
| `json_rpc_2` | ^3.x | JSON-RPC 2.0 protocol for MCP communication |
| `stream_channel` | ^2.x | Stream-based communication for MCP protocol |
| `dio` | ^5.x | HTTP client for Ollama and cloud API providers |
| `speech_to_text` | ^6.x | On-device speech recognition for chat voice input |
| `flutter_tts` | ^3.x | Text-to-speech for chat voice output |
| `flutter_svg` | ^2.x | SVG assets for icons and card artwork |
| `shimmer` | ^3.x | Loading skeleton placeholders |
| `intl` | ^0.19.x | Currency and date formatting |
| `cached_network_image` | ^3.x | Payee avatars and bank logos with caching |
| `flutter_accessibility_service` | ^0.3.x | Enhanced TalkBack detection on Android |
| `mocktail` | ^1.0.x | Mock services for PoC demo mode and unit tests |
| `very_good_analysis` *(dev)* | ^5.x | Strict linting, enforces layer boundaries |

> **Note:** The `flutter_local_ai` package provides unified access to on-device LLMs across platforms:
> - **iOS 26+:** Apple Foundation Models (FoundationModels framework)
> - **Android API 26+:** ML Kit GenAI (Gemini Nano via Google AICore)
> - **Windows 11:** Windows AI APIs (Copilot+ PCs with NPU)
>
> No model downloads required — uses native OS-level models. Streaming support planned for future versions.

---

## 9. Security Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| SEC-01 | Biometric authentication | Local biometric via `local_auth`. No biometric data stored by the app. | Must Have |
| SEC-02 | Secure token storage | All tokens in Keychain (iOS) or Keystore (Android). Never in SharedPreferences. | Must Have |
| SEC-03 | PIN hashing | SHA-256 hash of PIN before storage. Raw PIN never persisted. | Must Have |
| SEC-04 | Privacy-first LLM routing | MCP Server prefers on-device/local providers. Cloud only with user consent. | Must Have |
| SEC-04a | No PII to cloud | MCP Server strips or redacts PII before cloud API calls (if permitted). | Should Have |
| SEC-04b | Local provider encryption | Communication with local Ollama server uses localhost only, no network exposure. | Must Have |
| SEC-05 | Deep link validation | All incoming URIs validated against allow-list of known routes before routing. | Must Have |
| SEC-06 | Certificate pinning | HTTP service layer pins server certificates (ready for when mock → real API). | Should Have |
| SEC-07 | Dart obfuscation | Release builds use `--obfuscate --split-debug-info` flags. | Should Have |
| SEC-08 | Session timeout | Automatic lock after 5 minutes inactivity. Re-auth required. | Should Have |
| SEC-09 | Screenshot prevention | `FLAG_SECURE` (Android), screenshot notification on sensitive screens (iOS). | Should Have |

---

## 10. Accessibility Requirements

| ID | Requirement | Standard | Priority |
|---|---|---|---|
| A11Y-01 | WCAG 2.1 AA color contrast | 4.5:1 minimum for all text. 3:1 for UI components. | Must Have |
| A11Y-02 | Screen reader compatibility | All interactive elements have `Semantics` labels. Logical focus order. | Must Have |
| A11Y-03 | Minimum touch target | 48×48dp minimum for all interactive elements. | Must Have |
| A11Y-04 | Text scaling | UI remains functional and readable at `textScaleFactor` up to 2.0. | Must Have |
| A11Y-05 | Reduce motion | All animations respect `MediaQuery.disableAnimations`. | Must Have |
| A11Y-06 | Color blindness safe palette | No information conveyed by color alone. Pattern + label fallbacks. | Must Have |
| A11Y-07 | Keyboard navigation | Full navigation without touch (external keyboard / switch access). | Should Have |
| A11Y-08 | Error accessibility | Form errors announced to screen reader, not color-only. | Must Have |

---

## 11. Non-Functional Requirements

| Requirement | Target |
|---|---|
| App launch time (cold start) | < 2.5 seconds to hub screen on target hardware |
| LLM first token latency | < 1.5 seconds on Pixel 8 Pro and iPhone 15 Pro |
| Voice intent to screen | < 1 second from assistant response to target screen visible |
| Frame rate | 60fps sustained on hub screen. No jank during widget composition. |
| Offline mode | Auth, balance (cached), and chat LLM must function without network |
| Mock data coverage | 100% of features demo-able without a real backend |
| Test coverage | 80% unit test coverage on UseCase and ServiceAdapter classes |
| Binary size | < 50MB download size on both platforms |

---

## 12. Out of Scope (PoC)

The following are explicitly excluded from this proof of concept to prevent scope creep during development:

- Real backend integration (all data is mocked via local JSON)
- Multi-account support (single account per user in PoC)
- Internationalisation / localisation (English only)
- Push notifications
- Cheque deposit or ATM location features
- Apple Pay / Google Pay integration
- Biometric enrolment flows (device OS handles this)
- Customer onboarding / KYC
- Fraud detection or transaction dispute flows
- Tablet / iPad layout optimisation
- Web or desktop Flutter targets

---

## 13. Suggested PoC Milestones

| Milestone | Deliverable | Key Features | Est. Duration |
|---|---|---|---|
| M1 — Foundation | Buildable shell app | clean_framework setup, go_router, locator.dart, auth flow with biometric | 1 week |
| M2 — Hub | Adaptive hub running | HubProfileResolver, all 4 hub layouts, accessibility switching, chat FAB | 1.5 weeks |
| M3 — Banking | All 5 banking screens | Balance, Transfer, Transactions, Pay Bills, Cards — all mock data | 2 weeks |
| M4 — Voice Assistants | Siri + App Actions | `flutter_app_intents` setup, `app_links` deep linking, intent registration, auth gate | 1 week |
| M5 — Speech Services | STT/TTS abstraction | `SttService` and `TtsService` interfaces, on-device implementations, DI setup | 0.5 weeks |
| M6 — MCP Server | LLM abstraction layer | MCP protocol, embedded server, `flutter_local_ai` integration (LocalAiProvider), capability detection | 1 week |
| M7 — MCP Providers | Extended provider support | Ollama integration, cloud API fallback (OpenAI/Anthropic), privacy routing, pseudo-streaming | 1 week |
| M8 — Chat Integration | MCP-powered chat | Chat UI with Speech Services (STT/TTS), MCP responses, privacy indicators, fallback consent | 1 week |
| M9 — Polish | Demo-ready build | Error states, loading states, accessibility audit, performance pass | 1 week |

**Total estimated duration: ~10 weeks for a single Flutter developer.**

> **Notes:**
> - Using `flutter_local_ai` reduces M6 duration — no custom native code for on-device LLM
> - Using `flutter_app_intents` reduces M4 duration — unified API for voice assistants, intents defined in Dart

---

## 14. Open Questions

| Question | Impact if Unresolved |
|---|---|
| Minimum iOS version: 16 or 26? | `flutter_local_ai` requires iOS 26+ for on-device LLM. iOS 16-25 users will fallback to Ollama or cloud. |
| Android AICore availability? | `flutter_local_ai` requires Google AICore. Devices without AICore will fallback to Ollama or cloud. |
| `flutter_local_ai` streaming timeline? | Package currently lacks streaming. Monitor for updates or implement polling-based pseudo-streaming. |
| Custom Siri wake phrase approved? | "Hey Siri, [action] in BankApp" requires App Intent donation. Marketing approval may be needed. |
| `flutter_app_intents` Android release? | Android App Actions support is in development. Track package releases for availability. |
| Color blindness: user-set or auto-detect? | iOS/Android have no API for color blindness type. User-set is the only reliable path — confirms UX decision. |
| Backend API contract available? | Knowing the real API shape lets mock responses be designed without re-work later. |
| Is Assistive Access (iOS) in scope? | Assistive Access replaces the entire UI — a separate Flutter entry point may be required. |
| MCP Server deployment mode for production? | Embedded mode works for PoC. Production may need daemon mode for Ollama or remote mode for enterprise. |
| Cloud API provider preference? | OpenAI, Anthropic, or Google Gemini API for cloud fallback? Affects SDK integration and cost model. |
| Default privacy level? | Should default be `high` (on-device/local only) or `standard` (allow cloud)? Affects first-run UX. |
| Ollama model recommendation? | Which local model balances quality vs. speed for banking Q&A? (e.g., llama3.2:3b, mistral:7b, phi3:mini) |
| Enterprise speech provider preference? | Azure Cognitive Services, Google Cloud Speech, or AWS (Transcribe/Polly) for future enterprise deployment? |
| Speech provider for production? | Stay with on-device for privacy, or move to cloud for accuracy/language support? May vary by market. |
| Multi-language STT/TTS support? | Which languages beyond English needed? Affects provider choice (Azure supports 100+ languages). |
| Custom brand colors? | Should the color palette be customizable per white-label deployment, or fixed for PoC? |
| Dark mode priority? | Is dark mode required for PoC demo, or can it be deferred to post-PoC? |
| Design handoff tool? | Will there be Figma/Sketch files, or is PRD the source of truth for design? |

---

*This document describes the PoC scope only. All architecture and package decisions are optimised for demonstrability and internal review. A production build would require a formal security audit, accessibility certification (WCAG 2.1 AA), backend API integration, and performance testing on a broader device matrix.*