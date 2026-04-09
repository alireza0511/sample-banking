# M5 — Speech Services Implementation Summary

## Implementation Status: ✅ COMPLETE

Successfully implemented speech recognition services with a clean abstraction layer that makes the `speech_to_text` package easily swappable with other providers (Google Cloud Speech, AWS Transcribe, etc.).

## What Was Implemented

### 1. Clean Architecture with Abstraction Layer

Created a provider-agnostic speech service architecture following the **Strategy Pattern**, similar to the LlmManager implementation:

```
┌─────────────────────────────────────────┐
│         SpeechManager                    │  ← Facade with fallback chain
│  (Manages multiple implementations)     │
└─────────────────┬───────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼─────────┐  ┌──────▼──────────┐
│ SpeechToText    │  │ MockSpeech      │
│ Service         │  │ Service         │
│ (Real STT)      │  │ (Testing)       │
└─────────────────┘  └─────────────────┘
        │                   │
        └─────────┬─────────┘
                  │
        ┌─────────▼─────────┐
        │  SpeechService     │  ← Abstract interface
        │  (Interface)       │
        └────────────────────┘
```

### 2. New Files Created (5 files)

#### Core Speech Files

1. **`/lib/core/speech/speech_service.dart`** - Abstract Interface
   - Defines the contract all speech implementations must follow
   - Provider-agnostic API
   - Custom types:
     - `SpeechRecognitionResult` - Result with confidence, final flag, timestamp
     - `SpeechLocale` - Language locale information
     - `SpeechServiceException` - Custom exception type

   **Key Methods:**
   ```dart
   Future<bool> initialize();
   Future<void> startListening({
     required void Function(SpeechRecognitionResult) onResult,
     void Function(String error)? onError,
     String? localeId,
     bool partialResults = true,
   });
   Future<void> stopListening();
   Future<List<SpeechLocale>> getAvailableLocales();
   ```

2. **`/lib/core/speech/speech_to_text_service.dart`** - Concrete Implementation
   - Wraps the `speech_to_text` package
   - Implements `SpeechService` interface
   - Converts between package types and our abstract types
   - Comprehensive debug logging
   - Error handling with custom exceptions

3. **`/lib/core/speech/mock_speech_service.dart`** - Mock Implementation
   - Simulates speech recognition without microphone
   - Perfect for testing and development
   - Configurable simulated responses
   - Configurable delays
   - Supports partial results (typing effect)

   **Default Simulated Responses:**
   ```dart
   - "Show my balance"
   - "Transfer money"
   - "Pay bills"
   - "What is my account balance"
   - "Send fifty dollars to John"
   ```

4. **`/lib/core/speech/speech_manager.dart`** - Manager with Fallback
   - Manages multiple speech service implementations
   - Tries services in order until one works
   - Default chain: `SpeechToTextService` → `MockSpeechService`
   - Allows runtime service switching
   - Singleton pattern via AppLocator

   **Key Features:**
   ```dart
   - Automatic fallback on initialization failure
   - Service switching: switchToService('MockSpeech')
   - Delegates all calls to active service
   - Unified interface regardless of implementation
   ```

5. **`/lib/core/speech/speech.dart`** - Barrel Export
   - Clean public API
   - Re-exports all speech components
   - Single import for users: `import 'core/speech/speech.dart'`

### 3. Modified Files

#### Service Registration
**`/lib/core/locator.dart`**
- Added `SpeechManager` field, getter, initialization, and provider
- Follows exact pattern as `LlmManager` and `IntentService`
- Initialized during app startup with fallback chain
- Available via Provider throughout the app

#### iOS Configuration
**`/ios/Runner/Info.plist`**
- ✅ Added `NSMicrophoneUsageDescription` - Explains microphone access need
- ✅ Added `NSSpeechRecognitionUsageDescription` - Explains speech recognition need

#### Android Configuration
**`/android/app/src/main/AndroidManifest.xml`**
- ✅ Added `RECORD_AUDIO` permission - Required for microphone access
- ✅ Added `INTERNET` permission - For cloud speech services (if used)
- ✅ Added `BLUETOOTH*` permissions - For Bluetooth headset support

## Architecture Highlights

### Easy to Swap Implementations

Adding a new speech provider (e.g., Google Cloud Speech) is simple:

```dart
// 1. Create new implementation
class GoogleCloudSpeechService implements SpeechService {
  @override
  Future<bool> initialize() async {
    // Initialize Google Cloud SDK
  }

  @override
  Future<void> startListening({...}) async {
    // Use Google Cloud Speech API
  }

  // ... implement other methods
}

// 2. Add to SpeechManager
SpeechManager(services: [
  GoogleCloudSpeechService(),  // Try this first
  SpeechToTextService(),       // Then this
  MockSpeechService(),         // Finally fallback to mock
]);
```

**No changes needed anywhere else in the app!**

### Dependency Injection via Provider

Access speech services anywhere in the app:

```dart
// Get the manager
final speechManager = Provider.of<SpeechManager>(context);

// Or use Consumer
Consumer<SpeechManager>(
  builder: (context, speech, child) {
    return VoiceButton(onTap: () => speech.startListening(...));
  },
)
```

### Comprehensive Error Handling

All errors are wrapped in `SpeechServiceException`:

```dart
try {
  await speechManager.startListening(onResult: ...);
} on SpeechServiceException catch (e) {
  print('Speech error from ${e.serviceName}: ${e.message}');
  print('Original error: ${e.originalError}');
}
```

## Usage Examples

### Basic Speech Recognition

```dart
final speechManager = Provider.of<SpeechManager>(context, listen: false);

// Check availability
if (!await speechManager.isAvailable()) {
  print('Speech recognition not available');
  return;
}

// Request permission
if (!await speechManager.hasPermission()) {
  final granted = await speechManager.requestPermission();
  if (!granted) {
    print('Microphone permission denied');
    return;
  }
}

// Start listening
await speechManager.startListening(
  onResult: (result) {
    print('Recognized: ${result.recognizedWords}');
    print('Confidence: ${result.confidence}');
    print('Is final: ${result.isFinal}');

    if (result.isFinal) {
      // Process final result
      handleVoiceCommand(result.recognizedWords);
    }
  },
  onError: (error) {
    print('Error: $error');
  },
  partialResults: true,  // Get intermediate results
  localeId: 'en_US',     // Optional: specify language
);

// Stop listening when done
await speechManager.stopListening();
```

### Get Available Languages

```dart
final locales = await speechManager.getAvailableLocales();
for (final locale in locales) {
  print('${locale.localeId}: ${locale.name}');
}
// Output:
// en_US: English (United States)
// es_ES: Spanish (Spain)
// fr_FR: French (France)
// ...
```

### Switch Speech Service (Testing)

```dart
// Switch to mock service for testing
await speechManager.switchToService('MockSpeech');

// Check active service
print('Using: ${speechManager.activeServiceName}');

// Get all available services
final services = speechManager.getAvailableServiceNames();
print('Available: $services');
// Output: [SpeechToText, MockSpeech]
```

### Real-Time Voice Input Widget

```dart
class VoiceInputButton extends StatefulWidget {
  final void Function(String text) onSpeechResult;

  const VoiceInputButton({required this.onSpeechResult});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _isListening = false;
  String _currentText = '';

  @override
  Widget build(BuildContext context) {
    final speech = Provider.of<SpeechManager>(context);

    return FloatingActionButton(
      onPressed: _isListening ? _stopListening : _startListening,
      backgroundColor: _isListening ? Colors.red : Colors.blue,
      child: Icon(_isListening ? Icons.mic_off : Icons.mic),
    );
  }

  Future<void> _startListening() async {
    final speech = Provider.of<SpeechManager>(context, listen: false);

    if (!await speech.hasPermission()) {
      await speech.requestPermission();
    }

    setState(() {
      _isListening = true;
      _currentText = '';
    });

    await speech.startListening(
      onResult: (result) {
        setState(() {
          _currentText = result.recognizedWords;
        });

        if (result.isFinal) {
          widget.onSpeechResult(result.recognizedWords);
          _stopListening();
        }
      },
      onError: (error) {
        print('Speech error: $error');
        _stopListening();
      },
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    final speech = Provider.of<SpeechManager>(context, listen: false);
    await speech.stopListening();

    setState(() {
      _isListening = false;
    });
  }
}
```

## Testing

### Using Mock Service for Testing

```dart
// In test environment or dev mode
final speechManager = SpeechManager(
  services: [
    MockSpeechService(
      simulatedResponses: [
        'Show my balance',
        'Transfer fifty dollars to John',
        'Pay electricity bill',
      ],
      responseDelay: Duration(seconds: 1),
    ),
  ],
);

await speechManager.initialize();

// Now all speech calls will use simulated responses
await speechManager.startListening(
  onResult: (result) {
    print('Mock result: ${result.recognizedWords}');
  },
);
```

### Unit Testing Speech Services

```dart
void main() {
  group('SpeechManager', () {
    late SpeechManager speechManager;

    setUp(() {
      speechManager = SpeechManager(
        services: [MockSpeechService()],
      );
    });

    test('initializes successfully', () async {
      await speechManager.initialize();
      expect(speechManager.isInitialized, true);
      expect(speechManager.activeServiceName, 'MockSpeech');
    });

    test('returns simulated speech results', () async {
      await speechManager.initialize();

      String? recognizedText;
      await speechManager.startListening(
        onResult: (result) {
          if (result.isFinal) {
            recognizedText = result.recognizedWords;
          }
        },
      );

      // Wait for simulated response
      await Future.delayed(Duration(seconds: 3));

      expect(recognizedText, isNotNull);
      expect(recognizedText, contains('balance'));
    });
  });
}
```

## Platform Permissions

### iOS Permission Flow

1. App requests microphone access first time
2. iOS shows system dialog with `NSMicrophoneUsageDescription` text
3. User grants/denies permission
4. Speech recognition automatically uses granted permission

### Android Permission Flow

1. App requests `RECORD_AUDIO` permission
2. Android shows system dialog
3. User grants/denies permission
4. For Android 6.0+, runtime permission is required

### Checking Permissions in App

```dart
final speech = Provider.of<SpeechManager>(context, listen: false);

// Check if permission already granted
final hasPermission = await speech.hasPermission();

if (!hasPermission) {
  // Request permission (shows system dialog)
  final granted = await speech.requestPermission();

  if (!granted) {
    // User denied - show explanation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Microphone Access Required'),
        content: Text('Please enable microphone access in Settings'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## Debug Logging

All speech services include comprehensive debug logging:

```
SpeechManager: Initializing with 2 services...
SpeechManager: Trying SpeechToText...
SpeechToText: Initializing...
SpeechToText: Initialized successfully
SpeechManager: Successfully initialized SpeechToText

SpeechToText: Starting to listen...
SpeechToText: Now listening
SpeechToText: Sound level: 0.3
SpeechToText: Result - "Show my" (confidence: 0.75, final: false)
SpeechToText: Result - "Show my balance" (confidence: 0.95, final: true)
SpeechToText: Stopping listening...
SpeechToText: Stopped listening
```

## Future Enhancements (Easy to Add)

### 1. Google Cloud Speech
```dart
class GoogleCloudSpeechService implements SpeechService {
  final String apiKey;
  // ... implementation
}
```

### 2. AWS Transcribe
```dart
class AwsTranscribeService implements SpeechService {
  final String accessKey;
  // ... implementation
}
```

### 3. Custom On-Device Model
```dart
class OnDeviceSpeechService implements SpeechService {
  final String modelPath;
  // ... implementation using Vosk, TensorFlow Lite, etc.
}
```

### 4. Hybrid Service (Cloud + Local)
```dart
class HybridSpeechService implements SpeechService {
  // Use local for partial results (fast)
  // Use cloud for final result (accurate)
}
```

**All additions require ZERO changes to existing code!**

## Files Changed Summary

**New Files (5):**
- `/lib/core/speech/speech_service.dart` - Abstract interface
- `/lib/core/speech/speech_to_text_service.dart` - speech_to_text wrapper
- `/lib/core/speech/mock_speech_service.dart` - Mock implementation
- `/lib/core/speech/speech_manager.dart` - Manager with fallback
- `/lib/core/speech/speech.dart` - Barrel export

**Modified Files (3):**
- `/lib/core/locator.dart` - Registered SpeechManager
- `/ios/Runner/Info.plist` - Added microphone permissions
- `/android/app/src/main/AndroidManifest.xml` - Added microphone permissions

**Documentation (1):**
- `/SPEECH_SERVICES_IMPLEMENTATION.md` (this file)

## Key Benefits

✅ **Easy to Swap** - Change speech provider with one line
✅ **Testable** - Mock service for testing without hardware
✅ **Fallback Chain** - Automatic failover to working service
✅ **Type Safe** - Consistent API across all implementations
✅ **Error Handling** - Custom exceptions with context
✅ **Debug Friendly** - Comprehensive logging
✅ **Permission Management** - Built-in permission handling
✅ **Locale Support** - Multi-language ready
✅ **Partial Results** - Real-time feedback while speaking
✅ **Provider Integration** - Works seamlessly with Flutter Provider

## Success Criteria - All Met ✅

- ✅ Created clean abstraction layer (SpeechService interface)
- ✅ Wrapped speech_to_text package (SpeechToTextService)
- ✅ Can easily swap implementations (just change SpeechManager services list)
- ✅ Mock implementation for testing (MockSpeechService)
- ✅ Manager with fallback support (SpeechManager)
- ✅ Registered in AppLocator following established patterns
- ✅ Platform permissions configured (iOS & Android)
- ✅ Code compiles without errors
- ✅ Comprehensive documentation
- ✅ Ready for integration with chat and voice features

## Integration with Voice Assistants (M4)

The Speech Services (M5) complement the Voice Assistants (M4) implementation:

- **M4 (Voice Assistants)**: Siri/Google Assistant → Deep Links → Navigation
- **M5 (Speech Services)**: In-App Voice Input → Text → Actions

**Example Combined Flow:**
1. User opens chat screen
2. Taps microphone button
3. SpeechManager captures: "What is my balance?"
4. Chat sends to LLM
5. LLM responds with balance info
6. User can also say "Hey Siri, show my balance" (M4) to navigate directly

Both systems work independently but create a complete voice experience!
