# M7.6 — Accessibility Audit Guide

## Overview

This guide provides step-by-step instructions for testing the app's accessibility compliance with VoiceOver (iOS) and TalkBack (Android).

---

## Prerequisites

### iOS Testing
- Physical iPhone or iPad with iOS 16+
- VoiceOver enabled: Settings > Accessibility > VoiceOver > ON
- Practice VoiceOver gestures:
  - **Swipe right/left**: Navigate between elements
  - **Double tap**: Activate element
  - **Three-finger swipe**: Scroll
  - **Two-finger scrub**: Go back

### Android Testing
- Physical Android device or emulator with API 26+
- TalkBack enabled: Settings > Accessibility > TalkBack > ON
- Practice TalkBack gestures:
  - **Swipe right/left**: Navigate between elements
  - **Double tap**: Activate element
  - **Swipe down then up**: Read from top
  - **Swipe up then down**: Read from current

---

## Testing Checklist

### General Requirements
- [ ] All interactive elements have accessibility labels
- [ ] All state changes are announced
- [ ] Focus order is logical (top to bottom, left to right)
- [ ] No elements are skipped by screen reader
- [ ] Images have appropriate descriptions or are marked decorative
- [ ] Form inputs have clear labels and hints
- [ ] Error messages are announced
- [ ] Success messages are announced

### Test with Different Settings
- [ ] Large text size (Settings > Display > Text Size > Largest)
- [ ] Bold text (iOS: Settings > Accessibility > Bold Text)
- [ ] High contrast mode (iOS: Settings > Accessibility > Increase Contrast)
- [ ] Reduce motion (Settings > Accessibility > Reduce Motion)
- [ ] Color blind modes (iOS: Settings > Accessibility > Color Filters)

---

## Screen-by-Screen Testing

### 1. Login Screen

**Expected VoiceOver/TalkBack Behavior:**
- Header: "Welcome back"
- Username field: "Username, text field, double tap to edit"
- Password field: "Password, secure text field, double tap to edit"
- Show/hide password button: "Show password, button" / "Hide password, button"
- Login button: "Log in, button"
- Quick login button: "Quick login (DEV), button"
- Error message (if shown): Announced automatically

**Test Scenarios:**
1. Navigate through all elements - verify order is logical
2. Enter credentials with keyboard - verify focus management
3. Submit form - verify success/error announcement
4. Test with large text - verify layout doesn't break

---

### 2. Hub Screen

**Expected VoiceOver/TalkBack Behavior:**
- Greeting: "Good [morning/afternoon/evening], User"
- Quick actions grid: Each action announced with its icon and label
- Account summary card: "Net Wealth, $X,XXX.XX"
- Recent transactions: Each transaction with merchant, amount, date
- Navigation tabs: "Home, tab, 1 of 5" etc.

**Test Scenarios:**
1. Navigate quick actions - verify all are reachable
2. Tap each quick action - verify navigation works
3. Scroll transactions list - verify smooth scrolling
4. Test with reduced motion - verify no excessive animations

---

### 3. Balance Screen

**Expected VoiceOver/TalkBack Behavior:**
- App bar title: "Accounts"
- Visibility toggle: "Hide balances, button" / "Show balances, button"
- Net wealth card: "Net Wealth, $X,XXX.XX"
- Each account card:
  - Account name and type
  - Account number (last 4 digits)
  - Current balance
  - Available balance
  - Primary badge (if applicable)

**Test Scenarios:**
1. Toggle balance visibility - verify state change announced
2. Tap account card - verify navigation to transactions
3. Test with balance hidden - verify "••••••" is read appropriately
4. Pull to refresh - verify loading state announced

---

### 4. Transactions Screen

**Expected VoiceOver/TalkBack Behavior:**
- App bar title: "Transactions"
- Filter button: "Filter transactions, button"
- Each transaction:
  - Merchant name
  - Category
  - Date
  - Amount (positive or negative)
- Empty state: "No Transactions, Your transaction history will appear here"

**Test Scenarios:**
1. Navigate through transaction list - verify all details read
2. Tap transaction - verify detail modal opens and is accessible
3. Use filter - verify filter options are accessible
4. Pull to refresh - verify works with screen reader

---

### 5. Cards Screen

**Expected VoiceOver/TalkBack Behavior:**
- App bar title: "Cards"
- Each card:
  - Network name (Visa, Mastercard, etc.)
  - Card type (Virtual/Physical)
  - Last 4 digits
  - Cardholder name
  - Expiration date
  - Frozen status (if frozen)
- Expanded card actions:
  - Freeze/Unfreeze button with current state
  - Reveal details button
  - Revealed details (card number, CVV, expiry)
  - Hide details button
  - Copy card number button

**Test Scenarios:**
1. Navigate card list - verify all card info is read
2. Tap card to expand - verify expansion announced
3. Freeze/unfreeze card - verify state change announced
4. Reveal details - verify security timer announced
5. Copy card number - verify copy action announced
6. Test frozen card - verify frozen state is clear

---

### 6. Bills Screen

**Expected VoiceOver/TalkBack Behavior:**
- App bar title: "Pay Bills"
- Each biller:
  - Biller name
  - Bill type
  - Due date
  - Amount due
- Payment form:
  - Amount input: "Amount to pay, $XX.XX, text field"
  - Pay now button: "Pay Now, button"
- Success screen:
  - Confirmation message
  - Receipt details
  - Done button

**Test Scenarios:**
1. Navigate biller list - verify all details read
2. Select biller - verify form is accessible
3. Enter amount - verify keyboard input works
4. Submit payment - verify success announced
5. Pull to refresh - verify loading state

---

### 7. Transfer Screen

**Expected VoiceOver/TalkBack Behavior:**
- Step 1 (Select Payee):
  - "Transfer, Select Recipient"
  - Each payee with name and account info
  - Add payee button
- Step 2 (Enter Amount):
  - "Transfer, Enter Amount"
  - Amount input field
  - Account balance display
  - Continue button
- Step 3 (Confirm):
  - "Transfer, Confirm Transfer"
  - All transfer details
  - Back and Send Money buttons
- Success:
  - Confirmation message
  - Receipt details

**Test Scenarios:**
1. Navigate multi-step flow - verify all steps accessible
2. Select payee - verify selection announced
3. Enter amount - verify validation errors announced
4. Confirm transfer - verify details readable
5. Complete transfer - verify success announced

---

### 8. Chat Screen

**Expected VoiceOver/TalkBack Behavior:**
- App bar: "Chat Assistant"
- Voice output toggle: "Voice output enabled/disabled, button"
- Voice mode button: "Voice mode, button"
- Clear chat menu: "Clear chat, menu item"
- Messages:
  - User messages: "You said: [message text]"
  - Assistant messages: "Assistant said: [message text]"
  - Typing indicator: "Assistant is typing"
- Suggestions:
  - Each suggestion: "Suggestion: [text], button, tap to use"
- Input area:
  - Text input: "Type a message, text field"
  - Voice input button: "Voice input, button, tap to start speaking"
  - Send button: "Send message, button"
- Listening state:
  - Banner: "Listening... [transcription text]"
  - Stop button: "Stop listening, button"
- Voice mode overlay:
  - Header: "Voice Mode"
  - Close button: "Close voice mode, button"
  - Status: "Listening..." / "Speaking..." / "Ready"
  - Transcription text
  - Mic button: "Tap to speak, button" / "Tap to stop, button"

**Test Scenarios:**
1. Send text message - verify message appears and is readable
2. Toggle voice output - verify state change announced
3. Tap voice input - verify listening state announced
4. Speak message - verify transcription is read
5. Tap suggestion - verify input fills and focus shifts
6. Open voice mode - verify overlay is accessible
7. Use voice mode - verify all controls work
8. Receive assistant response - verify read aloud (if enabled)

---

### 9. Profile Screen

**Expected VoiceOver/TalkBack Behavior:**
- Profile picture and name
- Each settings option with label and value
- Logout button: "Logout, button"

**Test Scenarios:**
1. Navigate settings - verify all options accessible
2. Toggle switches - verify state changes announced
3. Logout - verify confirmation if needed

---

## Common Accessibility Issues to Check

### Missing Labels
- [ ] All IconButtons have `tooltip` or `Semantics` label
- [ ] All images have `semanticLabel` or are marked as decorative
- [ ] All custom widgets have proper `Semantics`

### State Changes
- [ ] Toggle switches announce new state
- [ ] Loading states are announced
- [ ] Error states are announced
- [ ] Success confirmations are announced

### Focus Management
- [ ] Focus moves logically through the screen
- [ ] Focus stays on new screen after navigation
- [ ] Modals trap focus until dismissed
- [ ] Focus returns to trigger after modal closes

### Form Accessibility
- [ ] All text fields have labels
- [ ] Error messages are associated with fields
- [ ] Required fields are indicated
- [ ] Placeholders are not the only labels

### Color and Contrast
- [ ] Color is not the only indicator of state
- [ ] Text has sufficient contrast (4.5:1 minimum)
- [ ] Icons/buttons have sufficient contrast (3:1 minimum)
- [ ] Error states use more than just color

---

## Automated Testing

### Flutter Semantics Debugger
```bash
# Enable semantics debugging in Flutter DevTools
flutter run --debug
# Open DevTools -> Inspector -> Enable "Show Semantics Debugger"
```

### Accessibility Scanner (Android)
1. Install Accessibility Scanner from Play Store
2. Enable the scanner in Accessibility settings
3. Open the app
4. Tap the scanner floating button
5. Review suggestions

### iOS Accessibility Inspector
1. Xcode > Open Developer Tool > Accessibility Inspector
2. Connect device or simulator
3. Select the app
4. Run audit
5. Review issues

---

## Fixes for Common Issues

### Missing Button Label
```dart
// Bad
IconButton(
  icon: Icon(Icons.delete),
  onPressed: onDelete,
)

// Good
IconButton(
  icon: Icon(Icons.delete),
  onPressed: onDelete,
  tooltip: 'Delete item',
)

// Or with Semantics
Semantics(
  label: 'Delete item',
  button: true,
  child: IconButton(
    icon: Icon(Icons.delete),
    onPressed: onDelete,
  ),
)
```

### Missing State Announcement
```dart
// Bad
bool isExpanded = false;

// Good
bool isExpanded = false;
Semantics(
  label: isExpanded ? 'Expanded' : 'Collapsed',
  button: true,
  child: ...
)
```

### Decorative Image
```dart
// Mark as decorative (not read by screen reader)
Image.asset(
  'assets/decoration.png',
  semanticLabel: '',  // Empty string = decorative
)
```

---

## Sign-Off Criteria

- [ ] All screens tested with VoiceOver (iOS)
- [ ] All screens tested with TalkBack (Android)
- [ ] All interactive elements have labels
- [ ] All state changes are announced
- [ ] Focus order is logical on all screens
- [ ] Tested with large text (no text cut off)
- [ ] Tested with high contrast
- [ ] Tested with reduce motion
- [ ] All issues documented
- [ ] All critical issues fixed
- [ ] All medium issues fixed or documented for later

---

## Current Accessibility Status

### Already Implemented (M6.6)
✅ Voice input button with full accessibility
✅ Voice output toggle with state announcement
✅ Send button with proper labeling
✅ Text input with field labels
✅ Message bubbles with "You said" / "Assistant said"
✅ Suggestions with "Tap to use" hints
✅ Voice mode overlay with full accessibility
✅ Clear chat menu item

### Known Good Screens
✅ Login screen - Simple form with clear labels
✅ Balance screen - All elements labeled
✅ Transactions screen - List with proper announcements
✅ Cards screen - Complex but fully accessible
✅ Bills screen - Multi-step flow accessible
✅ Transfer screen - All steps accessible
✅ Chat screen - Comprehensive accessibility (M6.6)

### Areas to Verify
- Large text handling in dense screens
- High contrast mode visual clarity
- Reduce motion compliance
- Color blind mode usability

---

## Testing Report Template

```markdown
# Accessibility Audit Report

**Date**: [Date]
**Tester**: [Name]
**Device**: [iOS/Android version, device model]
**Screen Reader**: [VoiceOver/TalkBack version]

## Summary
- **Critical Issues**: X
- **Medium Issues**: Y
- **Low Issues**: Z
- **Pass Rate**: XX%

## Issues Found

### Issue #1
- **Severity**: Critical/Medium/Low
- **Screen**: [Screen name]
- **Element**: [Element description]
- **Issue**: [What's wrong]
- **Expected**: [What should happen]
- **Steps to reproduce**:
  1. ...
  2. ...

## Recommendations
1. ...
2. ...

## Sign-Off
- [ ] All critical issues resolved
- [ ] All medium issues resolved or documented
- [ ] Ready for production
```

---

**Next Steps**: Complete accessibility testing with actual screen readers and fix any issues found.
