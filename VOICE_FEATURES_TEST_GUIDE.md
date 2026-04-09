# Voice Features Testing Guide

## Quick Test Script for M5.6 & M5.7

Use this guide to quickly verify both voice features are working correctly.

## Prerequisites

1. **Build the app:**
   ```bash
   flutter run -d <device-id>
   ```

2. **Navigate to Chat:**
   - Open the app
   - Navigate to Chat screen
   - You should see the chat interface

## Test 1: Voice Input (M5.6)

### Visual Check
- [ ] Microphone icon visible in input area (left side)
- [ ] Icon is blue when idle

### Functionality Test

**Step 1: First Use (Permission Request)**
```
1. Tap the microphone icon
2. Permission dialog appears: "Allow microphone access?"
3. Tap "Allow" or "OK"
```

**Step 2: Start Listening**
```
1. Blue banner appears above input with "Listening..."
2. Microphone icon changes to red mic-off
3. Text input field is disabled (grayed out)
```

**Step 3: Speak a Message**
```
1. Say: "What is my account balance?"
2. Watch for partial text in banner: "What is my..."
3. Continue speaking: "...account balance?"
4. Final text shows: "What is my account balance?"
```

**Step 4: Auto-Send**
```
1. After ~1 second of silence, speech recognition finalizes
2. Message automatically sent to AI
3. Blue banner disappears
4. Message appears in chat as user message
5. AI responds with answer
```

**Step 5: Manual Stop**
```
1. Tap mic again while listening
2. Should stop listening
3. Tap mic again to cancel
```

### Expected Results
- ✅ Permission requested only once
- ✅ Blue banner visible when listening
- ✅ Partial transcription shows in real-time
- ✅ Message auto-sends when final
- ✅ Text input disabled during listening
- ✅ Can manually stop by tapping mic again

### Troubleshooting
- **No permission dialog:** Already granted, skip to step 2
- **Permission denied:** Check device settings, grant microphone access
- **No transcription:** Speak louder or check microphone
- **Doesn't auto-send:** Wait 1-2 seconds for finalization

## Test 2: Voice Output (M5.7)

### Visual Check
- [ ] Volume icon visible in AppBar (top right)
- [ ] Icon is gray (volume_off) by default

### Functionality Test

**Step 1: Enable Voice Output**
```
1. Tap the volume icon in AppBar
2. Icon turns blue
3. Icon changes to volume_up
```

**Step 2: Send a Message (Text)**
```
1. Type in input field: "What's my balance?"
2. Tap send button
3. AI responds in text
4. 🔊 TTS speaks response aloud
5. Listen to the spoken response
```

**Step 3: Send via Voice Input**
```
1. Tap mic icon
2. Say: "What are my recent transactions?"
3. Message auto-sends
4. AI responds in text
5. 🔊 TTS speaks response aloud again
```

**Step 4: Disable Voice Output**
```
1. Tap volume icon again (while TTS is speaking)
2. Icon turns gray (volume_off)
3. TTS stops immediately
4. Send another message
5. AI responds in text only (no audio)
```

**Step 5: Re-enable**
```
1. Tap volume icon
2. Icon turns blue again
3. Send message
4. TTS speaks response
```

### Expected Results
- ✅ Icon toggles between blue/gray
- ✅ Icon changes between volume_up/volume_off
- ✅ TTS speaks ALL responses when enabled
- ✅ TTS stops when toggled off mid-speech
- ✅ Setting persists across multiple messages
- ✅ Works with both text and voice input

### Troubleshooting
- **No audio:** Check device volume, unmute
- **TTS doesn't speak:** Verify icon is blue (enabled)
- **Can't hear:** Check device audio output
- **Wrong language:** TTS uses device default language

## Test 3: Full Voice Loop (Hands-Free)

### Complete Conversation Test

**Step 1: Setup**
```
1. Enable voice output (tap volume → blue)
2. Clear chat (optional: menu → "Clear chat")
```

**Step 2: First Question**
```
1. Tap mic icon
2. Say: "What is my account balance?"
3. Message auto-sends
4. AI responds in text
5. 🔊 Listen to TTS speaking response
```

**Step 3: Follow-Up Question**
```
1. Tap mic icon again (after TTS finishes or during)
2. Say: "What are my recent transactions?"
3. Message auto-sends
4. AI responds
5. 🔊 Listen to TTS speaking
```

**Step 4: Continue Conversation**
```
1. Tap mic
2. Say: "Transfer fifty dollars to John"
3. Listen to response
4. Repeat for more questions
```

### Expected Results
- ✅ Complete hands-free conversation
- ✅ No need to touch keyboard
- ✅ Natural back-and-forth dialogue
- ✅ TTS speaks every response
- ✅ Can interrupt TTS to ask next question

## Test 4: Error Handling

### Permission Denial
```
1. Deny microphone permission
2. Tap mic icon
3. Error message should appear
4. No crash
```

### No Internet (Cloud LLM)
```
1. Disable internet
2. Send message
3. Should show error or use on-device LLM
4. No crash
```

### Long Speech
```
1. Speak for 30+ seconds
2. Should handle gracefully
3. May timeout after ~30 seconds (normal)
```

## Visual Indicators Reference

| State | Mic Icon | Volume Icon | Banner | Input Field |
|-------|----------|-------------|--------|-------------|
| **Idle** | Blue mic | Gray volume_off | None | Enabled |
| **Listening** | Red mic_off | Gray volume_off | Blue "Listening..." | Disabled |
| **Voice Out On** | Blue mic | Blue volume_up | None | Enabled |
| **Both Active** | Red mic_off | Blue volume_up | Blue "Listening..." | Disabled |
| **AI Typing** | Gray mic | Blue volume_up | None | Disabled |

## Performance Checks

### Battery Usage
- [ ] Voice input stops when not in use
- [ ] TTS stops when disabled
- [ ] No excessive battery drain

### Memory Usage
- [ ] App doesn't slow down after multiple voice messages
- [ ] No memory leaks during conversation

### Responsiveness
- [ ] UI remains responsive during STT
- [ ] UI remains responsive during TTS
- [ ] No freezing or stuttering

## Accessibility Tests

### Screen Reader Compatibility
```
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate to mic button
3. Should announce: "Voice input button"
4. Navigate to volume icon
5. Should announce: "Voice output toggle"
```

### Large Text Support
```
1. Enable large text in device settings
2. Check that all text is readable
3. Icons should remain visible
```

### Color Blind Mode
```
1. Icons should be distinguishable by shape, not just color
2. Blue/gray difference should be clear
```

## Integration Tests

### With LLM
- [ ] Voice input works with on-device LLM
- [ ] Voice input works with cloud LLM
- [ ] Voice output speaks responses from both

### With Chat Features
- [ ] Clear chat works with voice
- [ ] Retry works after voice input
- [ ] Privacy indicator shows during voice

### With Deep Links
```
1. Open app via deep link: kindbanking://chat?prompt=Hello
2. Initial prompt pre-filled
3. Voice features still work
```

## Quick Checklist

### M5.6 — Voice Input
- [ ] Mic button visible
- [ ] Permission request works
- [ ] Blue banner shows when listening
- [ ] Partial transcription visible
- [ ] Auto-send works
- [ ] Manual stop works
- [ ] Text input disabled during listening

### M5.7 — Voice Output
- [ ] Volume icon visible
- [ ] Toggle works (blue/gray)
- [ ] TTS speaks responses
- [ ] Can stop mid-speech
- [ ] Setting persists
- [ ] Works with both input methods

### Integration
- [ ] Both features work together
- [ ] Hands-free conversation works
- [ ] No crashes or freezes
- [ ] Good performance
- [ ] Accessible

## Common Issues & Solutions

### "Permission Denied"
- **Solution:** Go to device Settings → Apps → BankApp → Permissions → Microphone → Allow

### "No Speech Detected"
- **Solution:** Speak louder, check microphone, reduce background noise

### "TTS Not Working"
- **Solution:** Check volume icon is blue, increase device volume, check audio output

### "App Crashes on Mic Tap"
- **Solution:** Check logs, verify SpeechManager is initialized in AppLocator

### "Transcription Incorrect"
- **Solution:** Normal for STT, speak clearly, try again, or use text input

## Success Criteria

**All tests pass when:**
- ✅ No crashes during any test
- ✅ Visual indicators work correctly
- ✅ Voice input transcribes speech accurately
- ✅ Voice output speaks responses clearly
- ✅ Full voice loop enables hands-free conversation
- ✅ Error handling is graceful
- ✅ Performance is acceptable
- ✅ Accessibility features work

## Report Results

After testing, document any issues:

```
Issue: [Description]
Steps to Reproduce: [1, 2, 3...]
Expected: [What should happen]
Actual: [What actually happened]
Device: [iOS/Android, version]
```

---

**Testing Complete?** You're ready to use voice features in production! 🎉
