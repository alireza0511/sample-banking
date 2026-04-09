# Voice Features - Quick Reference Guide

## Complete Voice Stack

The Kind Banking app now has a **complete voice interface** with 3 complementary services:

| Feature | What it Does | Package Used | Swappable? |
|---------|-------------|--------------|------------|
| **M4: Voice Assistants** | Siri → Deep Links → Navigate | flutter_app_intents | ✅ |
| **M5 STT: Speech-to-Text** | Listen to user voice → Text | speech_to_text | ✅ |
| **M5 TTS: Text-to-Speech** | App speaks → User hears | flutter_tts | ✅ |

## Quick Usage

### 1. Voice Assistants (M4) - Siri Integration

```dart
// Nothing to code! Just test:
// "Hey Siri, show my balance in Sample Banking"
// "Hey Siri, transfer money in Sample Banking"
```

### 2. Speech-to-Text (M5 STT) - Listen to User

```dart
final speech = Provider.of<SpeechManager>(context);

// Start listening
await speech.startListening(
  onResult: (result) {
    print('User said: ${result.recognizedWords}');
    if (result.isFinal) {
      handleCommand(result.recognizedWords);
    }
  },
);

// Stop listening
await speech.stopListening();
```

### 3. Text-to-Speech (M5 TTS) - Speak to User

```dart
final tts = Provider.of<TtsManager>(context);

// Speak text
await tts.speak(
  'Your balance is one thousand dollars',
  onComplete: () => print('Done'),
);

// Control voice
await tts.setSpeechRate(0.5);  // Speed: 0.0-1.0
await tts.setVolume(0.8);      // Volume: 0.0-1.0
await tts.setPitch(1.0);       // Pitch: 0.0-2.0
await tts.setLanguage('es-ES'); // Language

// Stop speaking
await tts.stop();
```

## Complete Voice Loop Example

```dart
class VoiceAssistantScreen extends StatelessWidget {
  Future<void> _startVoiceLoop(BuildContext context) async {
    final speech = Provider.of<SpeechManager>(context, listen: false);
    final tts = Provider.of<TtsManager>(context, listen: false);
    final llm = Provider.of<LlmManager>(context, listen: false);

    // Greet user
    await tts.speak('Hello! How can I help you today?');

    // Listen for command
    await speech.startListening(
      onResult: (result) async {
        if (result.isFinal) {
          final userText = result.recognizedWords;
          print('User: $userText');

          // Get AI response
          final response = await llm.sendMessage(userText);
          print('Bot: $response');

          // Speak response
          await tts.speak(response);

          // Continue listening...
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startVoiceLoop(context),
        child: Icon(Icons.mic),
      ),
    );
  }
}
```

## Real-World Examples

### Read Balance Aloud

```dart
await tts.speak('Your current balance is \$${balance}');
```

### Voice Transfer

```dart
// 1. Listen for command
await speech.startListening(
  onResult: (result) {
    if (result.recognizedWords.contains('transfer')) {
      // Parse: "Transfer 50 dollars to John"
      final amount = extractAmount(result.recognizedWords);
      final recipient = extractRecipient(result.recognizedWords);

      // Confirm
      tts.speak('Transferring \$$amount to $recipient. Confirm?');
    }
  },
);
```

### Accessibility - Read Screen

```dart
@override
void initState() {
  super.initState();

  // Auto-read screen content for visually impaired users
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final tts = Provider.of<TtsManager>(context, listen: false);
    await tts.speak('Balance screen. Your balance is \$1,234.56');
  });
}
```

## Switching Providers (Testing)

### Use Mock Services (No Hardware)

```dart
// In test environment
final speechManager = SpeechManager(
  services: [MockSpeechService()],
);

final ttsManager = TtsManager(
  services: [MockTtsService()],
);

// All calls work identically, but no actual audio/mic
```

### Switch at Runtime

```dart
// Switch STT to mock
await speechManager.switchToService('MockSpeech');

// Switch TTS to mock
await ttsManager.switchToService('MockTts');
```

## Adding New Providers

### Google Cloud Speech-to-Text

```dart
class GoogleCloudSpeechService implements SpeechService {
  @override
  Future<void> startListening({...}) async {
    // Use Google Cloud Speech API
  }
  // ... implement other methods
}

// Add to manager
SpeechManager(services: [
  GoogleCloudSpeechService(),
  SpeechToTextService(),
  MockSpeechService(),
]);
```

### AWS Polly Text-to-Speech

```dart
class AwsPollyService implements TtsService {
  @override
  Future<void> speak(String text, {...}) async {
    // Use AWS Polly API
  }
  // ... implement other methods
}

// Add to manager
TtsManager(services: [
  AwsPollyService(),
  FlutterTtsService(),
  MockTtsService(),
]);
```

**No changes needed anywhere else in the app!**

## Available in AppLocator

All services are registered as singletons:

```dart
AppLocator.speechManager  // M5 STT
AppLocator.ttsManager     // M5 TTS
AppLocator.intentService  // M4
AppLocator.llmManager     // Existing
AppLocator.deepLinkService // Existing
```

Access via Provider anywhere:

```dart
final speech = Provider.of<SpeechManager>(context);
final tts = Provider.of<TtsManager>(context);
```

## Platform Support

### iOS
- ✅ All features fully supported
- ✅ High-quality voices
- ✅ Requires physical device for Siri testing

### Android
- ✅ All features supported
- ✅ Voice quality depends on installed TTS engine
- ✅ Google Assistant integration via shortcuts

### Web
- ⚠️ Limited support (experimental)

## Permissions Required

### iOS (Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>For voice commands and speech input</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>For speech recognition features</string>

<key>NSSiriUsageDescription</key>
<string>For Siri shortcuts</string>
```

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Debug Logging

Enable to see what's happening:

```
SpeechManager: Initializing with 2 services...
SpeechToText: Initialized successfully
SpeechToText: Starting to listen...
SpeechToText: Result - "show my balance" (confidence: 0.95, final: true)

TtsManager: Initializing with 2 services...
FlutterTts: Initialized successfully
FlutterTts: Speaking: "Your balance is one thousand dollars"
FlutterTts: Speech completed
```

## Documentation

- **M4 (Voice Assistants):** `VOICE_ASSISTANTS_IMPLEMENTATION.md`
- **M5 STT (Speech-to-Text):** `SPEECH_SERVICES_IMPLEMENTATION.md`
- **M5 TTS (Text-to-Speech):** `TTS_SERVICES_IMPLEMENTATION.md`
- **Overall Summary:** `IMPLEMENTATION_SUMMARY.md`
- **This Guide:** `VOICE_FEATURES_QUICK_REFERENCE.md`

## Testing

### Without Hardware

```dart
// Use mock services - no mic or speakers needed
testWidgets('Voice command works', (tester) async {
  final speech = SpeechManager(services: [MockSpeechService()]);
  final tts = TtsManager(services: [MockTtsService()]);

  // Test voice loop
  await speech.startListening(...);
  await tts.speak(...);

  // Verify using mock service tracking
});
```

### With Real Hardware

```bash
# iOS
flutter run -d <your-iphone>

# Test Siri
"Hey Siri, show my balance in Sample Banking"

# Test in-app
Tap mic button → speak → see transcription → hear response
```

## Common Use Cases

| Use Case | Services Used | Example |
|----------|---------------|---------|
| Voice chat | STT + LLM + TTS | Full conversation loop |
| Balance inquiry | TTS only | Read balance aloud |
| Voice transfer | STT + TTS | Listen → confirm → speak |
| Accessibility | TTS only | Screen reader for blind users |
| Hands-free banking | STT + TTS | While driving, cooking |
| Siri shortcuts | Voice Assistants | Quick navigation |
| Multi-language | STT + TTS | Spanish, French, etc. |

## Best Practices

1. **Always check permissions** before using STT
2. **Provide visual feedback** when listening/speaking
3. **Handle errors gracefully** with user-friendly messages
4. **Use mock services** in tests
5. **Adjust speech rate** for accessibility (slower for elderly)
6. **Support multiple languages** for international users
7. **Stop TTS on navigation** to avoid speaking in wrong screen
8. **Clear speech history** on logout for privacy

## Performance Tips

- ✅ Initialize services at app startup (already done in AppLocator)
- ✅ Reuse manager instances (singleton pattern)
- ✅ Stop TTS/STT when not needed (saves battery)
- ✅ Use partial results for real-time feedback
- ✅ Cache TTS voices to avoid repeated loading

## Accessibility Benefits

- 🦽 Screen reader for visually impaired
- 👴 Voice commands for elderly users
- 🚗 Hands-free banking while driving
- 🌍 Multi-language support
- 📱 Easy navigation without typing
- 🔊 Audio confirmations for transactions

## Ready for Production! 🎉

All three voice features are:
- ✅ Fully implemented
- ✅ Easy to swap providers
- ✅ Testable with mocks
- ✅ Documented
- ✅ Zero compilation errors
- ✅ Following clean architecture

**Start integrating voice features into your screens now!**
