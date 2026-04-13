# M7.7 — Performance Optimization Guide

## Overview

This guide provides instructions for profiling and optimizing the BankApp for optimal performance, targeting 60fps on all screens.

---

## Performance Goals

### Target Metrics
- **Frame rendering**: 60fps (16.67ms per frame)
- **App startup**: < 2 seconds (cold start)
- **Screen navigation**: < 300ms
- **List scrolling**: Smooth 60fps with no jank
- **Memory usage**: < 150MB baseline
- **Build size**: < 30MB (release APK/IPA)

### Current Baseline
- ✅ Clean architecture with minimal widget rebuilds
- ✅ StreamBuilder for reactive UI
- ✅ ListView for efficient list rendering
- ⚠️ Need to verify const constructors usage
- ⚠️ Need to profile rebuild frequency
- ⚠️ Need to check image caching

---

## Profiling Tools

### 1. Flutter DevTools

**Installation:**
```bash
# DevTools is included with Flutter
flutter pub global activate devtools

# Launch DevTools
flutter pub global run devtools
```

**Usage:**
```bash
# Run app in profile mode
flutter run --profile

# Open DevTools in browser
# Navigate to the URL shown in terminal
```

**Key Panels:**
- **Performance**: Frame rendering timeline
- **Memory**: Heap usage and allocations
- **CPU Profiler**: Method execution times
- **Network**: API call latency
- **App Size**: Build size analysis

### 2. Flutter Performance Overlay

**Enable in code:**
```dart
MaterialApp(
  showPerformanceOverlay: true,  // Shows FPS overlay
  ...
)
```

**Enable via command:**
```bash
flutter run --profile --enable-software-rendering
```

### 3. Timeline Analysis

**Capture timeline:**
```bash
flutter run --profile
# In DevTools: Performance tab > Record
# Perform actions in app
# Stop recording
# Analyze flame chart
```

---

## Common Performance Issues

### 1. Unnecessary Widget Rebuilds

**Problem**: Widgets rebuild more often than needed

**Detection**:
```dart
// Add debug prints
@override
Widget build(BuildContext context) {
  debugPrint('Building _MyWidget');
  return ...;
}
```

**Fix with const constructors**:
```dart
// Bad
Card(
  child: Text('Hello'),
)

// Good
const Card(
  child: Text('Hello'),
)
```

**Fix with keys**:
```dart
// Use keys for list items
ListView.builder(
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),  // Prevents unnecessary rebuilds
      title: Text(items[index].name),
    );
  },
)
```

### 2. Expensive Build Methods

**Problem**: Complex calculations or object creation in build()

**Bad**:
```dart
@override
Widget build(BuildContext context) {
  final formatter = DateFormat('MMM dd, yyyy');  // Created every build!
  final formattedDate = formatter.format(date);

  return Text(formattedDate);
}
```

**Good**:
```dart
class _MyWidgetState extends State<MyWidget> {
  late final DateFormat formatter = DateFormat('MMM dd, yyyy');  // Created once

  @override
  Widget build(BuildContext context) {
    final formattedDate = formatter.format(date);
    return Text(formattedDate);
  }
}
```

### 3. Large Widget Trees

**Problem**: Entire tree rebuilds when only part changed

**Fix with RepaintBoundary**:
```dart
RepaintBoundary(
  child: ExpensiveWidget(),  // Isolates repaints
)
```

**Fix with Builder**:
```dart
// Only rebuilds specific part
StreamBuilder(
  stream: bloc.countStream,
  builder: (context, snapshot) {
    return Text('${snapshot.data}');  // Only this rebuilds
  },
)
```

### 4. Inefficient List Rendering

**Problem**: Rendering all list items at once

**Bad**:
```dart
Column(
  children: items.map((item) => ItemWidget(item)).toList(),  // All items rendered!
)
```

**Good**:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(items[index]);  // Only visible items rendered
  },
)
```

**Better with separators**:
```dart
ListView.separated(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
  separatorBuilder: (context, index) => const Divider(),
)
```

### 5. Image Loading Issues

**Problem**: Large images causing jank

**Fix**:
```dart
// Use cacheWidth/cacheHeight
Image.asset(
  'assets/image.png',
  cacheWidth: 200,  // Resize during load
  cacheHeight: 200,
)

// Use CachedNetworkImage for network images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### 6. Blocking the UI Thread

**Problem**: Long-running operations on main thread

**Fix with compute()**:
```dart
// Heavy computation in isolate
final result = await compute(heavyComputation, data);

// Example
Future<List<Transaction>> parseTransactions(String jsonString) async {
  return await compute(_parseTransactionsIsolate, jsonString);
}

static List<Transaction> _parseTransactionsIsolate(String jsonString) {
  // Runs in separate isolate
  return jsonDecode(jsonString).map((json) => Transaction.fromJson(json)).toList();
}
```

### 7. Excessive Animations

**Problem**: Multiple animations causing dropped frames

**Fix**:
```dart
// Use AnimationController with dispose
class _MyState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();  // Critical!
    super.dispose();
  }
}
```

---

## Screen-by-Screen Optimization

### 1. Hub Screen

**Current Implementation**: ✅ Good
- Uses ListView for scrollable content
- Quick action buttons are const

**Optimizations to Check**:
- [ ] Verify greeting widget doesn't rebuild on scroll
- [ ] Check if account summary card uses const
- [ ] Confirm transaction list uses builder
- [ ] Add RepaintBoundary around static sections

**Recommended Changes**:
```dart
// Wrap static sections
RepaintBoundary(
  child: _QuickActionsGrid(),  // Won't repaint during scroll
),

// Make buttons const
const QuickActionButton(
  icon: Icons.account_balance,
  label: 'Balance',
  route: Routes.balance,
),
```

### 2. Balance Screen

**Current Implementation**: ✅ Good
- Uses ListView for accounts
- StreamBuilder only rebuilds when data changes

**Optimizations to Check**:
- [ ] Net wealth card uses const where possible
- [ ] Account cards use keys for list items
- [ ] Icons and gradients are cached
- [ ] RefreshIndicator doesn't cause unnecessary rebuilds

**Recommended Changes**:
```dart
// Add keys to list items
_AccountCard(
  key: ValueKey(account.id),
  account: account,
  ...
),

// Cache gradients
static final _primaryGradient = LinearGradient(
  colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
);
```

### 3. Transactions Screen

**Current Implementation**: ✅ Good
- Uses ListView.builder
- Shimmer loading states

**Optimizations to Check**:
- [ ] Transaction items use keys
- [ ] Date formatting is cached
- [ ] Amount formatting uses cached NumberFormat
- [ ] Filter doesn't cause full list rebuild

**Recommended Changes**:
```dart
// Cache formatters
class _TransactionListState extends State<_TransactionList> {
  late final DateFormat _dateFormat = DateFormat('MMM dd');
  late final NumberFormat _amountFormat = NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionItem(
          key: ValueKey(transaction.id),
          transaction: transaction,
          dateFormatter: _dateFormat,
          amountFormatter: _amountFormat,
        );
      },
    );
  }
}
```

### 4. Cards Screen

**Current Implementation**: ⚠️ Needs review
- Card visuals with gradients
- Animated expansion
- Reveal details timer

**Optimizations to Check**:
- [ ] Gradients are cached (not recreated each build)
- [ ] Card number masking is efficient
- [ ] Expansion animation uses AnimationController properly
- [ ] Revealed details timer doesn't cause excessive rebuilds

**Recommended Changes**:
```dart
// Cache card gradients
static final Map<CardNetwork, Gradient> _gradients = {
  CardNetwork.visa: LinearGradient(colors: [Color(0xFF1A1F71), Color(0xFF232B5D)]),
  // ... other networks
};

// Use RepaintBoundary for cards
RepaintBoundary(
  child: _CardWidget(card: card),
),
```

### 5. Bills Screen

**Current Implementation**: ✅ Good
- Multi-step flow with conditional rendering
- Form validation

**Optimizations to Check**:
- [ ] Amount input doesn't rebuild entire form
- [ ] Biller list uses keys
- [ ] Icons are const where possible

### 6. Transfer Screen

**Current Implementation**: ✅ Good
- Multi-step wizard with state management
- Form validation

**Optimizations to Check**:
- [ ] Step transitions are smooth
- [ ] Form fields don't cause parent rebuild
- [ ] Payee list uses builder

### 7. Chat Screen

**Current Implementation**: ⚠️ Needs review
- Message list with StreamBuilder
- Voice mode overlay
- Rich message formatting
- Animated waveform

**Optimizations to Check**:
- [ ] Message list uses reverse ListView.builder
- [ ] Rich message parsing is not in build()
- [ ] Waveform animation uses RepaintBoundary
- [ ] Suggestion chips are const
- [ ] Voice mode overlay doesn't rebuild chat
- [ ] Typing indicator animation is lightweight

**Recommended Changes**:
```dart
// Cache rich message parsing
class RichMessageContent extends StatelessWidget {
  final String content;
  final Widget? _cachedWidget;

  RichMessageContent({required this.content})
    : _cachedWidget = _parseContent(content);

  static Widget? _parseContent(String text) {
    // Parse once during construction, not every build
    ...
  }

  @override
  Widget build(BuildContext context) {
    return _cachedWidget ?? Text(content);
  }
}

// Isolate waveform repaints
RepaintBoundary(
  child: WaveformPainter(...),
),

// Make suggestions const
const SuggestionChip(text: 'Check balance'),
```

---

## Optimization Checklist

### Code Review
- [ ] All static widgets use `const` constructors
- [ ] All list items have unique `Key`s
- [ ] No object creation in `build()` methods
- [ ] All formatters (DateFormat, NumberFormat) are cached
- [ ] No unnecessary `setState()` calls
- [ ] All animations properly disposed
- [ ] All StreamControllers properly disposed
- [ ] No synchronous file I/O on main thread

### Widget Tree
- [ ] RepaintBoundary used for expensive widgets
- [ ] Builder widgets used to limit rebuild scope
- [ ] ListView.builder used instead of Column with map
- [ ] ListView.separated used instead of manual separators
- [ ] No deeply nested widget trees (> 10 levels)

### Images & Assets
- [ ] Images use appropriate resolution
- [ ] cacheWidth/cacheHeight set for large images
- [ ] Network images use CachedNetworkImage
- [ ] Icons use Flutter's built-in icon fonts
- [ ] No unused assets in bundle

### State Management
- [ ] Only necessary data in State
- [ ] StreamBuilder only rebuilds affected widgets
- [ ] No global state causing cascading rebuilds
- [ ] Bloc pattern used correctly (separate entity/viewmodel)

### Network & Data
- [ ] API responses cached where appropriate
- [ ] SharedPreferences batched writes
- [ ] No N+1 query patterns
- [ ] Pagination for long lists
- [ ] Debounced search/filter inputs

---

## Profiling Workflow

### 1. Baseline Profile
```bash
# Build release version
flutter build apk --release --profile
flutter build ios --release --profile

# Install and profile
flutter run --profile --start-paused
# Open DevTools
# Click "Record" in Performance tab
# Use app normally for 30 seconds
# Stop recording
# Save baseline timeline
```

### 2. Identify Bottlenecks
1. Look for red/yellow frames in timeline (> 16.67ms)
2. Expand flame chart to see which methods are slow
3. Check for:
   - Long build() methods
   - Excessive widget rebuilds
   - Layout thrashing
   - Shader compilation jank

### 3. Optimize
1. Fix identified issues one at a time
2. Re-profile after each fix
3. Compare timelines to baseline
4. Document improvements

### 4. Memory Profile
```bash
# In DevTools: Memory tab
# 1. Take heap snapshot
# 2. Use app normally
# 3. Take another snapshot
# 4. Compare - look for leaks (objects not cleaned up)
```

**Common memory leaks**:
- StreamControllers not closed
- AnimationControllers not disposed
- Listeners not removed
- Timers not cancelled

### 5. Build Size Analysis
```bash
# Analyze build size
flutter build apk --analyze-size
flutter build ios --analyze-size

# Look for:
# - Large assets not used
# - Redundant packages
# - Debug symbols in release
```

---

## Quick Wins

### 1. Add const constructors everywhere possible
```bash
# Use IDE to add const automatically
# VSCode: Right-click > "Add const keyword"
# Android Studio: Alt+Enter > "Add const keyword"
```

### 2. Use Flutter's build runner for generated code
```bash
# For JSON serialization
flutter packages pub run build_runner build
```

### 3. Enable tree shaking
```yaml
# Already enabled in release builds
flutter build apk --split-per-abi
```

### 4. Optimize images
```bash
# Use cwebp for PNG optimization
cwebp input.png -o output.webp

# Or use Flutter's image compression
flutter pub add flutter_image_compress
```

---

## Performance Testing Scenarios

### Scenario 1: Cold Start
1. Force stop app
2. Clear app data
3. Start app
4. Measure time to first interaction
5. **Target**: < 2 seconds

### Scenario 2: List Scrolling
1. Open transactions screen (100+ items)
2. Scroll rapidly up and down
3. Check for dropped frames
4. **Target**: 60fps, no jank

### Scenario 3: Screen Navigation
1. Navigate between all screens
2. Measure transition times
3. Check for animation stutters
4. **Target**: < 300ms per navigation

### Scenario 4: Chat Performance
1. Send 20 messages rapidly
2. Toggle voice mode multiple times
3. Scroll message list
4. **Target**: No dropped frames, smooth animations

### Scenario 5: Memory Stability
1. Use app for 10 minutes
2. Navigate between all screens multiple times
3. Check memory usage remains stable
4. **Target**: No memory leaks, < 200MB peak

---

## Optimization Results Template

```markdown
# Performance Optimization Report

**Date**: [Date]
**Engineer**: [Name]
**Device**: [Device model, OS version]
**Build**: [Release/Profile]

## Baseline Metrics (Before)
- **Avg FPS**: [X]fps
- **Frame render time**: [X]ms avg, [Y]ms p99
- **Memory usage**: [X]MB baseline, [Y]MB peak
- **App startup**: [X]ms cold, [Y]ms warm
- **Build size**: [X]MB APK/IPA

## Optimizations Applied
1. [Optimization description]
   - **Change**: [What was changed]
   - **Impact**: [Performance improvement]
2. ...

## Results (After)
- **Avg FPS**: [X]fps (+Y%)
- **Frame render time**: [X]ms avg (-Y%), [Z]ms p99 (-W%)
- **Memory usage**: [X]MB baseline (-Y%), [Z]MB peak (-W%)
- **App startup**: [X]ms cold (-Y%), [Z]ms warm (-W%)
- **Build size**: [X]MB APK/IPA (-Y%)

## Remaining Issues
1. [Issue description]
   - **Screen**: [Screen name]
   - **Impact**: Critical/Medium/Low
   - **Plan**: [How to fix]

## Sign-Off
- [ ] All screens 60fps
- [ ] No memory leaks
- [ ] Startup < 2s
- [ ] Ready for production
```

---

## Automated Performance Tests

### Unit Tests for Performance
```dart
testWidgets('Chat screen builds in < 100ms', (tester) async {
  final stopwatch = Stopwatch()..start();

  await tester.pumpWidget(MaterialApp(home: ChatScreen()));
  await tester.pumpAndSettle();

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```

### Integration Tests
```bash
# Run integration tests with profiling
flutter drive --profile \
  --target=test_driver/app.dart \
  --driver=test_driver/perf_driver.dart
```

---

## Current Performance Status

### Known Good
✅ Clean architecture minimizes unnecessary rebuilds
✅ StreamBuilder pattern is efficient
✅ ListView.builder used for all lists
✅ Shimmer loading states perform well
✅ RefreshIndicator is lightweight

### Areas to Optimize
⚠️ Chat message parsing - consider caching
⚠️ Card gradients - verify caching
⚠️ Waveform animation - add RepaintBoundary
⚠️ Rich message formatting - parse outside build()
⚠️ Verify all widgets use const where possible

### Expected Baseline (Before Optimization)
- **FPS**: ~58fps (minor drops during chat/animations)
- **Memory**: ~120MB baseline, ~180MB peak
- **Startup**: ~1.5s cold, ~800ms warm
- **Build size**: ~25MB APK

### Target (After Optimization)
- **FPS**: 60fps solid (no drops)
- **Memory**: ~100MB baseline, ~150MB peak
- **Startup**: ~1.2s cold, ~500ms warm
- **Build size**: ~20MB APK

---

**Next Steps**: Profile the app with Flutter DevTools, identify bottlenecks, apply optimizations, and verify improvements.
