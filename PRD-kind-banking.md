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

## 4. LLM Architecture — Enterprise Hybrid Model

The LLM architecture follows an **enterprise hybrid model** that separates on-device processing from backend services. This design ensures maximum privacy for sensitive data while maintaining centralized control over cloud API access, logging, and cost management.

### 4.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER'S DEVICE                                   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                          Flutter App                                    │ │
│  │                                                                         │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐ │ │
│  │  │                      Local LLM Router                              │ │ │
│  │  │                                                                    │ │ │
│  │  │   • Check on-device LLM availability                               │ │ │
│  │  │   • Detect PII/sensitive data in query                            │ │ │
│  │  │   • Enforce user privacy preferences                              │ │ │
│  │  │   • Route to on-device OR backend                                 │ │ │
│  │  │                                                                    │ │ │
│  │  └───────────────┬───────────────────────────────┬───────────────────┘ │ │
│  │                  │                               │                      │ │
│  │                  ▼                               ▼                      │ │
│  │  ┌───────────────────────────┐   ┌───────────────────────────────────┐ │ │
│  │  │     On-Device Provider    │   │        Backend MCP Client         │ │ │
│  │  │     (flutter_local_ai)    │   │                                   │ │ │
│  │  │                           │   │   • Authenticated API calls       │ │ │
│  │  │   • Apple Foundation      │   │   • No API keys stored locally    │ │ │
│  │  │     Models (iOS 26+)      │   │   • Request/response logging      │ │ │
│  │  │   • ML Kit GenAI          │   │                                   │ │ │
│  │  │     (Android API 26+)     │   │                                   │ │ │
│  │  │                           │   │                                   │ │ │
│  │  │   ✅ Data never leaves    │   │                                   │──────────┐
│  │  │      the device           │   │                                   │ │ │      │
│  │  └───────────────────────────┘   └───────────────────────────────────┘ │ │      │
│  │                                                                         │ │      │
│  └─────────────────────────────────────────────────────────────────────────┘ │      │
│                                                                              │      │
└──────────────────────────────────────────────────────────────────────────────┘      │
                                                                                       │
                                         HTTPS (TLS 1.3)                               │
                                                                                       │
┌──────────────────────────────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           BACKEND INFRASTRUCTURE                             │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                          API Gateway                                    │ │
│  │                                                                         │ │
│  │   • JWT/OAuth authentication                                           │ │
│  │   • Rate limiting (per user, per tier)                                 │ │
│  │   • Request validation & sanitization                                  │ │
│  │   • DDoS protection                                                    │ │
│  │                                                                         │ │
│  └────────────────────────────────────┬───────────────────────────────────┘ │
│                                       │                                      │
│                                       ▼                                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                       MCP Server (Backend)                              │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │                    Router / Orchestrator                         │  │ │
│  │  │                                                                  │  │ │
│  │  │   • Provider selection (cost, capability, load balancing)       │  │ │
│  │  │   • PII scrubbing before external API calls                     │  │ │
│  │  │   • Response caching (reduce costs)                             │  │ │
│  │  │   • Model selection (GPT-4 vs GPT-3.5 based on complexity)     │  │ │
│  │  │   • Prompt injection protection                                 │  │ │
│  │  │                                                                  │  │ │
│  │  └──────────────────────────┬──────────────────────────────────────┘  │ │
│  │                             │                                          │ │
│  │         ┌───────────────────┼───────────────────┐                     │ │
│  │         ▼                   ▼                   ▼                     │ │
│  │  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐             │ │
│  │  │   Ollama    │     │   OpenAI    │     │  Anthropic  │             │ │
│  │  │ (Self-host) │     │  Provider   │     │  Provider   │             │ │
│  │  └─────────────┘     └─────────────┘     └─────────────┘             │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                       │                                      │
│                                       ▼                                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      Enterprise Services                                │ │
│  │                                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │ │
│  │  │  Logging &  │  │   Usage &   │  │  Analytics  │  │   A/B Test  │  │ │
│  │  │   Audit     │  │   Billing   │  │  Dashboard  │  │  Framework  │  │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │ │
│  │                                                                         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Component Responsibilities

#### 4.2.1 Client-Side: Local LLM Router

The Local LLM Router runs **within the Flutter app** and is responsible for deciding whether to process locally or send to backend.

| Responsibility | Description |
|---|---|
| **Availability Detection** | Check if `flutter_local_ai` is available on device |
| **PII Detection** | Scan queries for sensitive data (account numbers, SSN, etc.) |
| **Privacy Enforcement** | Respect user's privacy level setting |
| **Routing Decision** | Route to on-device or backend based on rules |
| **On-Device Execution** | Execute LLM queries locally via `flutter_local_ai` |
| **Backend Communication** | Send non-sensitive queries to Backend MCP Server |

#### 4.2.2 Server-Side: Backend MCP Server

The Backend MCP Server runs on **enterprise infrastructure** and handles all cloud LLM interactions.

| Responsibility | Description |
|---|---|
| **API Key Management** | Store and rotate cloud API keys securely |
| **Provider Routing** | Select optimal provider (cost, latency, capability) |
| **PII Scrubbing** | Remove any residual PII before external API calls |
| **Cost Optimization** | Cache responses, use cheaper models when appropriate |
| **Audit Logging** | Log all requests/responses for compliance |
| **Rate Limiting** | Enforce per-user and per-tier limits |
| **A/B Testing** | Route percentage of traffic to test new models/prompts |

### 4.3 Provider Types

| Provider | Location | Network | Privacy | API Keys | Use Case |
|---|---|---|---|---|---|
| **On-Device** | Client | None | Maximum | None | PII queries, offline, privacy-conscious users |
| **Ollama** | Backend (self-hosted) | Internal | High | None | Cost-sensitive, data residency requirements |
| **OpenAI** | Backend → Cloud | External | Standard | Backend only | High capability queries |
| **Anthropic** | Backend → Cloud | External | Standard | Backend only | Complex reasoning, long context |
| **Azure OpenAI** | Backend → Cloud | External | Standard | Backend only | Enterprise compliance, regional deployment |

### 4.4 Routing Logic

#### 4.4.1 Client-Side Routing Decision

```dart
// lib/core/llm/local_llm_router.dart

class LocalLlmRouter {
  final FlutterLocalAi _localAi = FlutterLocalAi.instance;
  final BackendMcpClient _backendClient;
  final PiiDetector _piiDetector;
  final UserSettings _userSettings;

  Future<LlmResponse> route(LlmRequest request) async {
    // 1. Get user's privacy preference
    final privacyLevel = _userSettings.privacyLevel;

    // 2. Check if query contains PII
    final piiResult = _piiDetector.analyze(request.prompt);

    // 3. Check on-device availability
    final onDeviceAvailable = await _localAi.isAvailable();

    // 4. Routing decision matrix
    if (privacyLevel == PrivacyLevel.maximum) {
      // User demands maximum privacy
      if (onDeviceAvailable) {
        return _executeOnDevice(request);
      } else {
        throw LlmException(
          code: 'ON_DEVICE_REQUIRED',
          message: 'Maximum privacy requires on-device LLM, but it is not available',
        );
      }
    }

    if (piiResult.containsPii && onDeviceAvailable) {
      // Sensitive data detected - keep on device
      _logLocalDecision('PII detected, routing to on-device');
      return _executeOnDevice(request);
    }

    if (privacyLevel == PrivacyLevel.high && onDeviceAvailable) {
      // User prefers privacy, on-device available
      return _executeOnDevice(request);
    }

    // Standard privacy or on-device unavailable - use backend
    return _executeViaBackend(request);
  }

  Future<LlmResponse> _executeOnDevice(LlmRequest request) async {
    final response = await _localAi.generateText(prompt: request.prompt);
    return LlmResponse(
      text: response.text,
      provider: 'on_device',
      isOnDevice: true,
      privacyLevel: PrivacyLevel.maximum,
    );
  }

  Future<LlmResponse> _executeViaBackend(LlmRequest request) async {
    // Backend handles provider selection
    return await _backendClient.generate(request);
  }
}
```

#### 4.4.2 Privacy Levels

| Level | Routing Behavior | Data Handling |
|---|---|---|
| `maximum` | On-device only. Fail if unavailable. | Zero data transmission |
| `high` | Prefer on-device. Backend only if on-device unavailable AND no PII. | PII never sent to backend |
| `standard` | On-device for PII. Backend for general queries. | PII stays local, general queries to backend |
| `performance` | Backend preferred for speed. On-device for PII only. | Optimized for response time |

#### 4.4.3 PII Detection

The client-side PII detector scans queries before routing:

```dart
// lib/core/llm/pii_detector.dart

class PiiDetector {
  static final _patterns = {
    'account_number': RegExp(r'\b\d{10,16}\b'),
    'ssn': RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),
    'credit_card': RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
    'email': RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b'),
    'phone': RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b'),
    'date_of_birth': RegExp(r'\b\d{1,2}/\d{1,2}/\d{2,4}\b'),
  };

  PiiResult analyze(String text) {
    final detectedTypes = <String>[];

    for (final entry in _patterns.entries) {
      if (entry.value.hasMatch(text)) {
        detectedTypes.add(entry.key);
      }
    }

    return PiiResult(
      containsPii: detectedTypes.isNotEmpty,
      detectedTypes: detectedTypes,
    );
  }
}
```

### 4.5 Backend MCP Server Specification

#### 4.5.1 API Gateway Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| GW-01 | Authentication | JWT tokens with refresh, OAuth 2.0 support | Must Have |
| GW-02 | Rate Limiting | Configurable per user, per tier, per endpoint | Must Have |
| GW-03 | Request Validation | Schema validation, size limits, injection protection | Must Have |
| GW-04 | TLS 1.3 | Encrypted transport, certificate pinning support | Must Have |
| GW-05 | DDoS Protection | Rate-based blocking, geographic restrictions | Should Have |
| GW-06 | Request Logging | Log all requests with correlation IDs | Must Have |

#### 4.5.2 MCP Server Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| MCP-01 | Provider Abstraction | Unified interface for all cloud LLM providers | Must Have |
| MCP-02 | Provider Routing | Select provider based on cost, capability, availability | Must Have |
| MCP-03 | PII Scrubbing | Final PII scan before external API calls | Must Have |
| MCP-04 | Response Caching | Cache common responses to reduce costs | Should Have |
| MCP-05 | Streaming Support | Stream tokens from providers to client | Must Have |
| MCP-06 | Model Selection | Choose model tier based on query complexity | Should Have |
| MCP-07 | Fallback Chain | Automatic failover between providers | Must Have |
| MCP-08 | Prompt Templates | Managed prompt templates for banking use cases | Should Have |
| MCP-09 | Context Management | Handle conversation history server-side | Should Have |
| MCP-10 | Health Monitoring | Monitor provider health, auto-disable unhealthy | Must Have |

#### 4.5.3 Enterprise Services Requirements

| ID | Requirement | Details | Priority |
|---|---|---|---|
| ENT-01 | Audit Logging | Immutable logs of all LLM interactions | Must Have |
| ENT-02 | Usage Tracking | Track tokens, costs per user/department | Must Have |
| ENT-03 | Analytics Dashboard | Real-time usage, error rates, latency metrics | Should Have |
| ENT-04 | A/B Testing | Route traffic percentage to test variants | Should Have |
| ENT-05 | Cost Alerts | Alert when usage exceeds thresholds | Should Have |
| ENT-06 | SIEM Integration | Export logs to enterprise SIEM (Splunk, etc.) | Should Have |
| ENT-07 | Compliance Reports | Generate GDPR, SOC2 compliance reports | Could Have |

### 4.6 API Specification

#### 4.6.1 Backend MCP API Endpoints

```
POST /api/v1/llm/generate
POST /api/v1/llm/generate/stream
GET  /api/v1/llm/capabilities
GET  /api/v1/llm/usage
POST /api/v1/llm/feedback
```

#### 4.6.2 Generate Request

```json
POST /api/v1/llm/generate
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "prompt": "What are my recent transactions?",
  "context": [
    {"role": "user", "content": "Show my balance"},
    {"role": "assistant", "content": "Your balance is $12,450.00"}
  ],
  "options": {
    "max_tokens": 256,
    "temperature": 0.7,
    "preferred_provider": null,
    "session_id": "uuid-session-123"
  }
}
```

#### 4.6.3 Generate Response

```json
{
  "id": "resp_abc123",
  "text": "Here are your recent transactions...",
  "provider": "openai",
  "model": "gpt-4o-mini",
  "usage": {
    "prompt_tokens": 45,
    "completion_tokens": 128,
    "total_tokens": 173
  },
  "metadata": {
    "latency_ms": 1250,
    "cached": false,
    "cost_usd": 0.00035
  }
}
```

#### 4.6.4 Streaming Response

```
POST /api/v1/llm/generate/stream
Authorization: Bearer <jwt_token>

Response: Server-Sent Events (SSE)

data: {"type": "token", "content": "Here"}
data: {"type": "token", "content": " are"}
data: {"type": "token", "content": " your"}
...
data: {"type": "done", "id": "resp_abc123", "provider": "openai", "usage": {...}}
```

### 4.7 Security Considerations

| Concern | Mitigation |
|---|---|
| **API Keys in App** | Never stored on client. All cloud calls via backend. |
| **PII Leakage** | Client-side PII detection + server-side scrubbing |
| **Prompt Injection** | Input sanitization, output validation, prompt templates |
| **Man-in-the-Middle** | TLS 1.3, certificate pinning |
| **Token Theft** | Short-lived JWTs, secure storage, refresh rotation |
| **Audit Trail** | Immutable logs, correlation IDs, tamper detection |
| **Cost Attacks** | Rate limiting, usage caps, anomaly detection |

### 4.8 Client-Side Implementation

#### 4.8.1 Folder Structure

```
lib/
├── core/
│   ├── llm/
│   │   ├── local_llm_router.dart         # Routing decision logic
│   │   ├── pii_detector.dart             # Client-side PII detection
│   │   ├── on_device/
│   │   │   ├── local_ai_provider.dart    # flutter_local_ai wrapper
│   │   │   └── on_device_config.dart     # On-device settings
│   │   ├── backend/
│   │   │   ├── mcp_client.dart           # Backend API client
│   │   │   ├── mcp_auth.dart             # JWT handling
│   │   │   └── mcp_models.dart           # Request/response models
│   │   └── models/
│   │       ├── llm_request.dart
│   │       ├── llm_response.dart
│   │       └── privacy_level.dart
```

#### 4.8.2 On-Device Provider (flutter_local_ai)

```dart
// lib/core/llm/on_device/local_ai_provider.dart

import 'package:flutter_local_ai/flutter_local_ai.dart';

class LocalAiProvider {
  final FlutterLocalAi _localAi = FlutterLocalAi.instance;
  bool _initialized = false;
  bool _available = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _localAi.initialize();
      _available = await _localAi.isAvailable();
      _initialized = true;
    } catch (e) {
      _available = false;
      _initialized = true;
    }
  }

  bool get isAvailable => _available;

  Future<LlmResponse> generate(LlmRequest request) async {
    if (!_available) {
      throw LlmException(code: 'NOT_AVAILABLE', message: 'On-device LLM not available');
    }

    final response = await _localAi.generateText(prompt: request.prompt);

    return LlmResponse(
      text: response.text,
      provider: 'on_device',
      model: Platform.isIOS ? 'apple_foundation_models' : 'ml_kit_genai',
      isOnDevice: true,
      usage: LlmUsage(promptTokens: 0, completionTokens: 0), // On-device doesn't track
    );
  }
}
```

#### 4.8.3 Backend MCP Client

```dart
// lib/core/llm/backend/mcp_client.dart

class BackendMcpClient {
  final Dio _dio;
  final McpAuth _auth;
  final String _baseUrl;

  BackendMcpClient({
    required String baseUrl,
    required McpAuth auth,
  })  : _baseUrl = baseUrl,
        _auth = auth,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 60),
        ));

  Future<LlmResponse> generate(LlmRequest request) async {
    final token = await _auth.getAccessToken();

    final response = await _dio.post(
      '/api/v1/llm/generate',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return LlmResponse.fromJson(response.data);
  }

  Stream<LlmChunk> generateStream(LlmRequest request) async* {
    final token = await _auth.getAccessToken();

    final response = await _dio.post(
      '/api/v1/llm/generate/stream',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.stream,
      ),
    );

    await for (final chunk in response.data.stream) {
      final lines = utf8.decode(chunk).split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final json = jsonDecode(line.substring(6));
          yield LlmChunk.fromJson(json);
        }
      }
    }
  }
}
```

### 4.9 Backend Implementation Notes

The Backend MCP Server is a separate deployable service. Recommended stack:

| Component | Technology Options |
|---|---|
| **Language** | Python (FastAPI), Node.js (Express), Go |
| **API Gateway** | Kong, AWS API Gateway, Azure API Management |
| **Authentication** | Auth0, Keycloak, AWS Cognito |
| **Caching** | Redis, Memcached |
| **Logging** | ELK Stack, Datadog, CloudWatch |
| **Database** | PostgreSQL (usage tracking), Redis (sessions) |
| **Deployment** | Kubernetes, AWS ECS, Azure Container Apps |

> **Note:** Backend MCP Server implementation details are outside the scope of this Flutter PoC PRD. A separate Backend PRD should be created for the server-side components.

### 4.10 Integration Summary

| Query Type | Route | Provider | Data Handling |
|---|---|---|---|
| Contains PII | On-Device | `flutter_local_ai` | Never leaves device |
| User privacy = maximum | On-Device | `flutter_local_ai` | Never leaves device |
| User privacy = high, on-device available | On-Device | `flutter_local_ai` | Never leaves device |
| User privacy = high, on-device unavailable | Reject | — | User notified |
| General query, no PII | Backend | OpenAI/Anthropic/Ollama | Encrypted to backend |
| Offline mode | On-Device | `flutter_local_ai` | Never leaves device |

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

## 13. Implementation Plan

The implementation is structured in **3 phases** to enable early demos with on-device LLM, while deferring the complex Backend MCP Server to the final phase.

### Implementation Philosophy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        IMPLEMENTATION PHASES                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 1: Core App + On-Device LLM (Demo Ready)                            │
│  ════════════════════════════════════════════════                           │
│  • Foundation, Hub, Banking screens                                         │
│  • On-device LLM working (flutter_local_ai)                                │
│  • Basic chat with on-device responses                                      │
│  • ✅ DEMO: "Look, AI chat works completely offline!"                       │
│                                                                              │
│  PHASE 2: Voice & Polish (Enhanced Demo)                                    │
│  ════════════════════════════════════════                                   │
│  • Voice assistants (Siri, Google Assistant)                               │
│  • Speech services (STT/TTS)                                               │
│  • Full chat experience with voice                                          │
│  • ✅ DEMO: "Hey Siri, show my balance" + voice chat                        │
│                                                                              │
│  PHASE 3: Enterprise Backend (Production Ready)                             │
│  ══════════════════════════════════════════════                             │
│  • Backend MCP Server                                                       │
│  • Cloud LLM fallback                                                       │
│  • Enterprise logging, analytics                                            │
│  • ✅ PRODUCTION: Full hybrid architecture                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Phase 1: Core App + On-Device LLM

**Goal:** Demo-ready app with working on-device AI chat

**Duration:** ~5.5 weeks

#### M1 — Foundation (1 week)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M1.1 | Project setup | Create Flutter project, configure `pubspec.yaml`, set up folder structure | Must Have |
| M1.2 | clean_framework setup | Install and configure clean_framework 0.4.2, create base classes | Must Have |
| M1.3 | Routing setup | Configure go_router with route definitions, deep link support | Must Have |
| M1.4 | DI setup | Create `locator.dart` with Provider registrations | Must Have |
| M1.5 | Theme setup | Create `app_theme.dart`, color tokens, typography | Must Have |
| M1.6 | Biometric auth | Implement `local_auth` for Face ID / Fingerprint | Must Have |
| M1.7 | PIN fallback | Implement 6-digit PIN entry with secure storage | Must Have |
| M1.8 | Auth gate | Create route guard for protected screens | Must Have |
| M1.9 | Session management | Implement token storage, session timeout | Should Have |

**M1 Deliverable:** App launches, user can authenticate with biometric/PIN

---

#### M2 — Adaptive Hub (1.5 weeks)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M2.1 | Hub profile entity | Create `HubProfileEntity` with accessibility flags | Must Have |
| M2.2 | Profile resolver | Implement `HubProfileResolver` reading MediaQuery flags | Must Have |
| M2.3 | Hub widget factory | Create factory pattern for layout selection | Must Have |
| M2.4 | Standard hub layout | 3-column grid with balance card, quick actions, transactions | Must Have |
| M2.5 | Assistive hub layout | Single column, full-width buttons, semantic labels | Must Have |
| M2.6 | Large text hub layout | 2-column grid, larger tiles, 18sp+ text | Must Have |
| M2.7 | Color-blind hub layout | Adjusted palette, pattern indicators | Must Have |
| M2.8 | Live re-resolution | Hub rebuilds when accessibility settings change | Must Have |
| M2.9 | Chat FAB | Floating action button on all hub layouts | Must Have |
| M2.10 | Hub animations | Entry animations (respecting reduce motion) | Should Have |

**M2 Deliverable:** Hub screen adapts to accessibility settings in real-time

---

#### M3 — Banking Screens (2 weeks)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M3.1 | Mock data service | Create JSON mock data for all banking features | Must Have |
| M3.2 | Balance screen | Account summary, balance display, hide/show toggle | Must Have |
| M3.3 | Balance bloc | UseCase and ServiceAdapter for balance data | Must Have |
| M3.4 | Transfer screen | Payee selector, amount input, confirmation flow | Must Have |
| M3.5 | Transfer bloc | UseCase for transfer validation and execution | Must Have |
| M3.6 | Transactions screen | Paginated list, filters, transaction detail sheet | Must Have |
| M3.7 | Transactions bloc | UseCase with filtering and pagination | Must Have |
| M3.8 | Pay bills screen | Biller list, amount, date selection, confirmation | Must Have |
| M3.9 | Pay bills bloc | UseCase for bill payment flow | Must Have |
| M3.10 | Cards screen | Card list, freeze/unfreeze, card number reveal | Must Have |
| M3.11 | Cards bloc | UseCase for card management | Must Have |
| M3.12 | Deep link handling | Pre-fill screens from deep link parameters | Should Have |

**M3 Deliverable:** All 5 banking screens functional with mock data

---

#### M4 — On-Device LLM (1 week) ⭐ KEY DEMO MILESTONE

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M4.1 | flutter_local_ai setup | Add package, configure iOS/Android requirements | Must Have |
| M4.2 | LLM service interface | Create abstract `LlmService` interface | Must Have |
| M4.3 | On-device provider | Implement `OnDeviceLlmProvider` wrapping flutter_local_ai | Must Have |
| M4.4 | Availability detection | Check and cache on-device LLM availability at startup | Must Have |
| M4.5 | Simple chat UI | Basic chat screen with text input and message list | Must Have |
| M4.6 | Chat bloc | UseCase for chat message handling | Must Have |
| M4.7 | Message bubbles | User and assistant message bubble widgets | Must Have |
| M4.8 | Typing indicator | Show indicator while LLM is generating | Must Have |
| M4.9 | Error handling | Graceful error display if LLM unavailable | Must Have |
| M4.10 | Privacy indicator | "On-device" badge showing data stays local | Must Have |
| M4.11 | Conversation context | Maintain last 10 messages as context | Should Have |

**M4 Deliverable:** ✅ **DEMO READY** — Chat works with on-device LLM, completely offline

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 1 DEMO CHECKPOINT                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ App launches with biometric authentication                   │
│  ✅ Adaptive hub adjusts to accessibility settings               │
│  ✅ All banking screens work with mock data                      │
│  ✅ Chat works with ON-DEVICE LLM (no internet required!)        │
│  ✅ Privacy indicator shows "Responses generated on device"      │
│                                                                  │
│  Demo talking points:                                            │
│  • "Put your phone in airplane mode — chat still works"         │
│  • "Your financial questions never leave your device"           │
│  • "Turn on VoiceOver — watch the hub transform"                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

### Phase 2: Voice & Enhanced Experience

**Goal:** Voice assistant integration and polished chat experience

**Duration:** ~3 weeks

#### M5 — Voice Assistants (1 week)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M5.1 | flutter_app_intents setup | Add package, configure iOS entitlements | Must Have |
| M5.2 | Banking intents | Register ShowBalance, Transfer, PayBills, Cards intents | Must Have |
| M5.3 | Intent handlers | Handle intent callbacks, extract parameters | Must Have |
| M5.4 | app_links setup | Configure deep link handling for both platforms | Must Have |
| M5.5 | Deep link router | Parse incoming URIs, route to correct screen | Must Have |
| M5.6 | Auth gate for intents | Require auth before deep link navigation | Must Have |
| M5.7 | Siri testing | Test all voice commands on iOS device | Must Have |
| M5.8 | Shortcuts donation | Donate user actions for Siri suggestions | Should Have |
| M5.9 | Spotlight indexing | Index banking actions for Spotlight search | Should Have |
| M5.10 | Android App Actions | Configure shortcuts.xml (when flutter_app_intents supports) | Should Have |

**M5 Deliverable:** "Hey Siri, show my balance in BankApp" works

---

#### M6 — Speech Services (0.5 weeks)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M6.1 | SttService interface | Create abstract STT interface | Must Have |
| M6.2 | TtsService interface | Create abstract TTS interface | Must Have |
| M6.3 | On-device STT | Implement using `speech_to_text` package | Must Have |
| M6.4 | On-device TTS | Implement using `flutter_tts` package | Must Have |
| M6.5 | Service registration | Register services in locator.dart | Must Have |
| M6.6 | Voice input button | Add mic button to chat input | Must Have |
| M6.7 | Voice output toggle | Add option to read responses aloud | Should Have |

**M6 Deliverable:** Chat supports voice input and output

---

#### M7 — Enhanced Chat (1 week)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M7.1 | Voice mode UI | Full voice conversation mode with waveform | Should Have |
| M7.2 | Quick suggestions | Suggested questions based on context | Should Have |
| M7.3 | Rich responses | Format responses with cards, lists, actions | Should Have |
| M7.4 | Chat history | Persist chat history locally | Should Have |
| M7.5 | Clear conversation | Option to clear chat history | Must Have |
| M7.6 | Accessibility labels | Full VoiceOver/TalkBack support for chat | Must Have |
| M7.7 | Keyboard handling | Proper keyboard avoidance, dismiss on scroll | Must Have |

**M7 Deliverable:** Polished chat experience with voice support

---

#### M8 — Polish (0.5 weeks)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M8.1 | Loading states | Shimmer placeholders for all screens | Must Have |
| M8.2 | Error states | Error screens with retry actions | Must Have |
| M8.3 | Empty states | Friendly empty state illustrations | Should Have |
| M8.4 | Pull to refresh | Refresh gesture on list screens | Should Have |
| M8.5 | Haptic feedback | Tactile feedback for actions | Should Have |
| M8.6 | Accessibility audit | Test with VoiceOver/TalkBack, fix issues | Must Have |
| M8.7 | Performance pass | Profile and optimize slow screens | Must Have |

**M8 Deliverable:** ✅ **ENHANCED DEMO READY** — Full experience without backend

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 2 DEMO CHECKPOINT                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Everything from Phase 1, PLUS:                                  │
│                                                                  │
│  ✅ "Hey Siri, show my balance" → app opens to balance           │
│  ✅ Voice input for chat (tap mic, speak, see transcription)    │
│  ✅ Voice output (assistant reads responses aloud)               │
│  ✅ Polished UI with loading states, error handling              │
│  ✅ Full accessibility support verified                          │
│                                                                  │
│  Demo talking points:                                            │
│  • "Hey Siri, transfer money in BankApp" (hands-free banking)   │
│  • Tap mic → "What's my balance?" → hear response               │
│  • Still works offline with on-device LLM                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

### Phase 3: Enterprise Backend (Production)

**Goal:** Full hybrid architecture with backend MCP server

**Duration:** ~3.5 weeks (Flutter) + ~5 weeks (Backend, parallel)

#### M9 — Local LLM Router (1 week)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M9.1 | Router interface | Create `LlmRouter` interface for routing decisions | Must Have |
| M9.2 | PII detector | Implement regex-based PII detection | Must Have |
| M9.3 | Privacy settings | Add privacy level setting to user preferences | Must Have |
| M9.4 | Routing logic | Implement decision matrix (PII → on-device, etc.) | Must Have |
| M9.5 | Router integration | Replace direct LLM calls with router | Must Have |
| M9.6 | Fallback handling | Handle case when on-device unavailable | Must Have |
| M9.7 | Routing telemetry | Log routing decisions locally (for debugging) | Should Have |

**M9 Deliverable:** Smart routing based on PII and privacy settings

---

#### M10 — Backend MCP Client (1.5 weeks)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M10.1 | API client setup | Create Dio-based HTTP client with interceptors | Must Have |
| M10.2 | Auth integration | JWT token handling, refresh flow | Must Have |
| M10.3 | Generate endpoint | Implement `/api/v1/llm/generate` call | Must Have |
| M10.4 | Streaming support | Implement SSE streaming for `/generate/stream` | Must Have |
| M10.5 | Error handling | Map API errors to user-friendly messages | Must Have |
| M10.6 | Retry logic | Exponential backoff for transient failures | Must Have |
| M10.7 | Offline detection | Detect offline, route to on-device only | Must Have |
| M10.8 | Provider display | Show which provider responded (on-device/cloud) | Must Have |
| M10.9 | Timeout handling | Configurable timeouts, cancel long requests | Should Have |

**M10 Deliverable:** App can call backend MCP server for cloud LLM

---

#### M11 — Hybrid Integration (1 week)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| M11.1 | Full router integration | Connect PII detector + backend client + on-device | Must Have |
| M11.2 | Fallback consent | Prompt user before first cloud fallback | Must Have |
| M11.3 | Provider indicator | Dynamic UI showing "On-device" vs "Cloud" | Must Have |
| M11.4 | Offline graceful | Seamless switch to on-device when offline | Must Have |
| M11.5 | Settings UI | Privacy level picker in settings screen | Must Have |
| M11.6 | Usage display | Show LLM usage stats in settings (optional) | Could Have |
| M11.7 | End-to-end testing | Test all routing scenarios | Must Have |

**M11 Deliverable:** ✅ **PRODUCTION READY** — Full hybrid LLM architecture

---

### Backend MCP Server Tasks (Parallel Track)

**Note:** These tasks are for the backend team, running in parallel with Flutter development.

#### B1 — Infrastructure (1.5 weeks)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| B1.1 | Project setup | Initialize backend project (FastAPI/Node/Go) | Must Have |
| B1.2 | API Gateway | Configure Kong/AWS API Gateway | Must Have |
| B1.3 | Auth service | JWT validation, user context extraction | Must Have |
| B1.4 | Health endpoints | `/health`, `/ready` endpoints | Must Have |
| B1.5 | Docker setup | Containerize for deployment | Must Have |
| B1.6 | CI/CD pipeline | Automated build, test, deploy | Must Have |
| B1.7 | Staging environment | Deploy to staging for testing | Must Have |

---

#### B2 — Provider Integration (1.5 weeks)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| B2.1 | Provider interface | Abstract provider interface | Must Have |
| B2.2 | OpenAI provider | Integrate OpenAI API (GPT-4, GPT-3.5) | Must Have |
| B2.3 | Anthropic provider | Integrate Anthropic API (Claude) | Should Have |
| B2.4 | Ollama provider | Integrate self-hosted Ollama | Should Have |
| B2.5 | Streaming implementation | SSE streaming for all providers | Must Have |
| B2.6 | Provider routing | Select provider based on request | Must Have |
| B2.7 | Fallback chain | Auto-failover between providers | Must Have |

---

#### B3 — Enterprise Services (1 week)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| B3.1 | Audit logging | Log all requests/responses with correlation IDs | Must Have |
| B3.2 | Usage tracking | Track tokens, costs per user | Must Have |
| B3.3 | Rate limiting | Per-user, per-tier rate limits | Must Have |
| B3.4 | Analytics endpoints | Expose usage stats via API | Should Have |
| B3.5 | Dashboard | Basic admin dashboard for monitoring | Could Have |

---

#### B4 — Security Hardening (1 week)

| Task ID | Task | Description | Priority |
|---|---|---|---|
| B4.1 | PII scrubbing | Final PII scan before external API calls | Must Have |
| B4.2 | Input validation | Validate and sanitize all inputs | Must Have |
| B4.3 | Prompt injection protection | Detect and block injection attempts | Must Have |
| B4.4 | Secrets management | Secure API key storage (Vault, etc.) | Must Have |
| B4.5 | Penetration testing | Security audit of API | Should Have |

---

### Implementation Timeline

```
Week  1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
      ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
      │                                                         │
      │  PHASE 1: Core App + On-Device LLM                     │
      │  ══════════════════════════════════                     │
      │  M1 ████                                                │
      │  M2     ██████                                          │
      │  M3           ████████                                  │
      │  M4                   ████  ← DEMO 1 (On-device AI)    │
      │                                                         │
      │  PHASE 2: Voice & Polish                                │
      │  ═══════════════════════                                │
      │  M5                       ████                          │
      │  M6                           ██                        │
      │  M7                             ████                    │
      │  M8                                 ██ ← DEMO 2 (Voice) │
      │                                                         │
      │  PHASE 3: Enterprise Backend                            │
      │  ═══════════════════════════                            │
      │  M9                                     ████            │
      │  M10                                        ██████      │
      │  M11                                              ████  │
      │                                                    ↑    │
      │                                            PRODUCTION   │
      │                                                         │
      │  BACKEND (Parallel)                                     │
      │  ══════════════════                                     │
      │  B1         ██████                                      │
      │  B2               ██████                                │
      │  B3                     ████                            │
      │  B4                         ████                        │
      │                                                         │
      └─────────────────────────────────────────────────────────┘

LEGEND:
████ = Development period
← = Demo checkpoint
```

### Demo Checkpoints Summary

| Demo | When | What Works | Key Talking Points |
|---|---|---|---|
| **Demo 1** | Week 5.5 | On-device LLM chat | "AI chat works in airplane mode, data never leaves device" |
| **Demo 2** | Week 8.5 | Voice + Polish | "Hey Siri, show my balance" + voice chat |
| **Production** | Week 12 | Full hybrid | Enterprise-ready with cloud fallback, audit logging |

### Resource Requirements

| Role | Phase 1 | Phase 2 | Phase 3 | Total |
|---|---|---|---|---|
| Flutter Developer | 5.5 weeks | 3 weeks | 3.5 weeks | 12 weeks |
| Backend Developer | — | — | 5 weeks | 5 weeks |
| QA Engineer | 0.5 weeks | 0.5 weeks | 1 week | 2 weeks |
| Designer (support) | As needed | As needed | — | — |

> **Note:** Backend development (B1-B4) can run **in parallel** with Flutter Phase 2 and Phase 3, reducing total calendar time.

---

## 14. Open Questions

### Client-Side Questions

| Question | Impact if Unresolved |
|---|---|
| Minimum iOS version: 16 or 26? | `flutter_local_ai` requires iOS 26+ for on-device LLM. iOS 16-25 users will fallback to backend. |
| Android AICore availability? | `flutter_local_ai` requires Google AICore. Devices without AICore will fallback to backend. |
| `flutter_local_ai` streaming timeline? | Package currently lacks streaming. Monitor for updates or implement polling-based pseudo-streaming. |
| Custom Siri wake phrase approved? | "Hey Siri, [action] in BankApp" requires App Intent donation. Marketing approval may be needed. |
| `flutter_app_intents` Android release? | Android App Actions support is in development. Track package releases for availability. |
| Color blindness: user-set or auto-detect? | iOS/Android have no API for color blindness type. User-set is the only reliable path — confirms UX decision. |
| Default privacy level? | Should default be `high` (prefer on-device) or `standard` (allow backend)? Affects first-run UX. |

### Backend MCP Server Questions

| Question | Impact if Unresolved |
|---|---|
| Backend technology stack? | Python (FastAPI), Node.js, or Go? Affects team skills and hiring. |
| Cloud provider for hosting? | AWS, Azure, or GCP? Affects architecture, compliance, and costs. |
| Primary cloud LLM provider? | OpenAI, Anthropic, or Azure OpenAI? Affects API integration and costs. |
| Self-hosted Ollama? | Should Ollama run on backend infrastructure for high-privacy fallback? |
| Authentication provider? | Auth0, Keycloak, or cloud-native (Cognito, Azure AD)? Affects integration. |
| Data residency requirements? | Which regions must data stay in? Affects deployment architecture. |
| Logging/SIEM integration? | Which enterprise logging platform? (Splunk, Datadog, ELK) |
| Usage billing model? | Per-token, per-request, or subscription? Affects usage tracking design. |
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