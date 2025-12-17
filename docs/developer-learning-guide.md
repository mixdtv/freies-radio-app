# Developer Learning Guide

This guide identifies key technologies, tools, and concepts that will help developers work efficiently with this codebase. Each section provides background context, why it matters for this project, and resources for learning.

---

## Table of Contents

1. [Core Technologies](#core-technologies)
2. [State Management](#state-management)
3. [Navigation & Routing](#navigation--routing)
4. [Networking & APIs](#networking--apis)
5. [Development Tools](#development-tools)
6. [Testing](#testing)
7. [Performance & Debugging](#performance--debugging)
8. [CI/CD & DevOps](#cicd--devops)
9. [Security](#security)
10. [Emerging Technologies](#emerging-technologies)

---

## Core Technologies

### Dart Programming Language

**What it is:** Dart is Google's client-optimized language for building fast apps on any platform. It's the foundation of Flutter and combines features from JavaScript, Java, and C#.

**Why it matters:**
- All app logic is written in Dart
- Understanding null safety, async/await, and streams is essential
- Dart 3.x introduces records, patterns, and class modifiers

**Key concepts to learn:**
- **Null Safety:** The `?`, `!`, and `late` keywords for handling nullable types
- **Async Programming:** `Future`, `Stream`, `async/await`, `StreamController`
- **Collections:** `List`, `Map`, `Set` operations and spread operators
- **Extensions:** Adding functionality to existing classes
- **Isolates:** For heavy computation without blocking UI

**Current project usage:**
- Dart SDK >=3.2.0
- Heavy use of streams for real-time features (transcripts, visualizations)
- Async/await for all API calls

**Learning resources:**
- [Dart Language Tour](https://dart.dev/language)
- [Effective Dart](https://dart.dev/effective-dart)
- [Dart Async Programming](https://dart.dev/codelabs/async-await)

---

### Flutter Framework

**What it is:** Flutter is Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. It uses a reactive framework with a rich set of pre-designed widgets.

**Why it matters:**
- The entire app is built with Flutter
- Understanding the widget tree and build cycle is crucial
- Flutter's "everything is a widget" philosophy shapes architecture

**Key concepts to learn:**
- **Widget Lifecycle:** `StatelessWidget` vs `StatefulWidget`, `initState`, `dispose`
- **Build Context:** How context works and when to use `Builder`
- **Keys:** When and why to use `Key`, `ValueKey`, `GlobalKey`
- **Composition over Inheritance:** Building UIs by composing widgets
- **Constraints:** How Flutter's layout system works (BoxConstraints)

**Current project patterns:**
- Feature-based folder structure
- Separation of UI widgets from business logic
- `const` constructors for performance
- Custom widgets in `lib/app/widgets/`

**Learning resources:**
- [Flutter Documentation](https://docs.flutter.dev)
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets)
- [Flutter Architectural Overview](https://docs.flutter.dev/resources/architectural-overview)

---

## State Management

### BLoC Pattern (Business Logic Component)

**What it is:** BLoC is a state management pattern that separates business logic from UI using streams. It enforces unidirectional data flow: Events → BLoC → States.

**Why it matters:**
- Primary state management approach (15 Cubits, 99 States)
- Enables testable, predictable state changes
- Separates UI from business logic

**Key concepts to learn:**
- **Cubit:** Simplified BLoC that uses methods instead of events
- **States:** Immutable objects representing UI state
- **BlocBuilder:** Rebuilds UI when state changes
- **BlocListener:** Handles side effects (navigation, dialogs)
- **BlocProvider:** Dependency injection for blocs
- **context.select():** Fine-grained rebuilds

**Current project patterns:**
```dart
// State hierarchy example from the project
class PlayerCubitState {
  final AppRadio? selectedRadio;
  final bool isPlay;
  final RadioEpg? currentProgram;
  // ...
}

// Cubit emits new states
class PlayerCubit extends Cubit<PlayerCubitState> {
  void selectRadio(AppRadio radio) {
    emit(state.copyWith(selectedRadio: radio));
  }
}
```

**Project-specific patterns:**
- `BlocPresentationMixin` for one-time events (dialogs, navigation)
- `GlobalCubitConnection` for cross-cubit communication
- Root, AppScope, and Page-level cubit hierarchy

**Learning resources:**
- [BLoC Library Documentation](https://bloclibrary.dev)
- [BLoC Tutorial](https://bloclibrary.dev/#/gettingstarted)
- [Felix Angelov's BLoC Course](https://www.youtube.com/watch?v=THCkkQ-V1-8)

---

### Riverpod (Worth Investigating)

**What it is:** A reactive caching and data-binding framework that's a complete rewrite of Provider. It offers compile-time safety and better testability.

**Why investigate:**
- Simpler syntax than BLoC for many use cases
- No `BuildContext` dependency
- Better code generation support
- Growing community adoption

**How it compares to BLoC:**
| Aspect | BLoC/Cubit | Riverpod |
|--------|------------|----------|
| Learning curve | Steeper | Gentler |
| Boilerplate | More | Less |
| Testing | Good | Excellent |
| Type safety | Good | Better (compile-time) |
| Use case | Complex apps | Any size |

**When to consider:**
- New features that don't need BLoC's event-driven architecture
- Simpler state that doesn't need full BLoC ceremony

**Learning resources:**
- [Riverpod Documentation](https://riverpod.dev)
- [Code With Andrea Riverpod Guide](https://codewithandrea.com/articles/flutter-state-management-riverpod/)

---

## Navigation & Routing

### GoRouter

**What it is:** A declarative routing package for Flutter that uses the Router API. It supports deep linking, nested navigation, and URL-based routing.

**Why it matters:**
- All navigation uses GoRouter
- Supports nested shells (persistent bottom navigation)
- Enables deep linking to specific radio stations

**Key concepts to learn:**
- **Declarative Routes:** Defining routes as a tree structure
- **ShellRoute:** Persistent UI across child routes
- **Path Parameters:** `/radio/:slug`
- **Query Parameters:** `/search?q=jazz`
- **Redirects:** Authentication guards
- **GoRouterState:** Accessing route information

**Current project patterns:**
```dart
// Nested shell route for detail pages
ShellRoute(
  builder: (context, state, child) => DetailShell(child: child),
  routes: [
    GoRoute(path: 'about', builder: ...),
    GoRoute(path: 'timeline', builder: ...),
    GoRoute(path: 'transcript', builder: ...),
  ],
)
```

**Important note:** Project uses GoRouter 13.0.1; version 17.x has significant API changes.

**Learning resources:**
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Navigation and Routing](https://docs.flutter.dev/ui/navigation)
- [GoRouter Migration Guide](https://pub.dev/packages/go_router/changelog)

---

## Networking & APIs

### Dio HTTP Client

**What it is:** A powerful HTTP client for Dart with support for interceptors, global configuration, FormData, request cancellation, and more.

**Why it matters:**
- All API communication uses Dio
- Interceptors handle logging and error transformation
- CancelToken prevents memory leaks from abandoned requests

**Key concepts to learn:**
- **Interceptors:** Request/response transformation, logging, auth
- **CancelToken:** Canceling requests when leaving screens
- **BaseOptions:** Default headers, timeouts, base URL
- **FormData:** File uploads
- **Transformers:** Background JSON parsing

**Current project patterns:**
```dart
// Custom HttpApi wrapper
HttpApi({required this.baseServer, required String key, required String deviceId}) {
  dio = Dio(BaseOptions(
    baseUrl: baseServer,
    headers: {"X-API-KEY": key, "X-App-User": deviceId},
    connectTimeout: Duration(seconds: 30),
  ))
  ..interceptors.add(LogInterceptor(...));
}
```

**Learning resources:**
- [Dio Package Documentation](https://pub.dev/packages/dio)
- [Flutter Networking Tutorial](https://docs.flutter.dev/cookbook/networking/fetch-data)

---

### REST API Design Principles

**What it is:** REST (Representational State Transfer) is an architectural style for designing networked applications using HTTP methods.

**Why it matters:**
- All backend communication follows REST patterns
- Understanding helps debug API issues
- Useful for proposing API improvements

**Key concepts:**
- **HTTP Methods:** GET (read), POST (create), PUT (update), DELETE
- **Status Codes:** 200 (OK), 201 (Created), 400 (Bad Request), 401 (Unauthorized), 404 (Not Found)
- **Resource Naming:** `/broadcasters`, `/broadcasters/{slug}/epg`
- **Query Parameters:** Filtering, pagination, search
- **Request/Response Headers:** Content-Type, Authorization

**Current API patterns:**
```
GET  /api/v1/broadcasters?lat=52.5&lng=13.4
GET  /api/v1/metadata/{slug}/chunks/{id}
GET  /api/v1/streams/{slug}/fft/{id}
PUT  /api/v1/subscriptions/{deviceId}/spend/30
```

**Learning resources:**
- [REST API Tutorial](https://restfulapi.net)
- [HTTP Status Codes](https://httpstatuses.com)

---

### WebSockets & Real-time Data (Worth Investigating)

**What it is:** WebSocket is a protocol for full-duplex communication over a single TCP connection, enabling real-time data streaming.

**Why investigate:**
- Current transcript feature polls every 200ms
- WebSockets could reduce latency and server load
- Better for live streaming applications

**Potential use cases:**
- Live transcript streaming
- Real-time program updates
- Visualization data streaming

**Flutter packages:**
- `web_socket_channel` - Official Dart WebSocket client
- `socket_io_client` - Socket.IO for Flutter

**Learning resources:**
- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)
- [Flutter WebSocket Tutorial](https://docs.flutter.dev/cookbook/networking/web-sockets)

---

## Development Tools

### VS Code / Android Studio Extensions

**Essential extensions for Flutter development:**

**VS Code:**
- **Flutter** - Official Flutter extension
- **Dart** - Dart language support
- **Flutter BLoC** - BLoC snippets and tools
- **Pubspec Assist** - Package management
- **Error Lens** - Inline error display
- **GitLens** - Git history and blame
- **Thunder Client** - API testing

**Android Studio:**
- **Flutter Plugin** - Official Flutter support
- **Flutter Enhancement Suite** - Productivity tools
- **BLoC** - Code generation for BLoC

**Productivity tips:**
- Use "Flutter: New Widget" command to scaffold widgets
- Enable "Format on Save" for consistent code style
- Use code snippets for BLoC boilerplate

---

### Code Generation with build_runner

**What it is:** A build system for Dart that generates code from annotations. Commonly used for JSON serialization, immutable classes, and more.

**Why investigate:**
- Reduce boilerplate for data models
- Type-safe JSON serialization
- Immutable state classes with `freezed`

**Popular generators:**
- **json_serializable** - JSON serialization
- **freezed** - Immutable classes with unions
- **injectable** - Dependency injection
- **auto_route** - Type-safe routing

**Example with freezed:**
```dart
@freezed
class RadioStation with _$RadioStation {
  const factory RadioStation({
    required String id,
    required String name,
    String? description,
  }) = _RadioStation;

  factory RadioStation.fromJson(Map<String, dynamic> json) =>
      _$RadioStationFromJson(json);
}
```

**Learning resources:**
- [build_runner Documentation](https://pub.dev/packages/build_runner)
- [freezed Package](https://pub.dev/packages/freezed)
- [json_serializable Package](https://pub.dev/packages/json_serializable)

---

### Flutter DevTools

**What it is:** A suite of performance and debugging tools for Flutter, including widget inspector, memory profiler, network inspector, and more.

**Why it matters:**
- Debug widget rebuilds
- Find memory leaks
- Profile CPU usage
- Inspect network requests

**Key features:**
- **Widget Inspector:** Visualize widget tree, debug layouts
- **Performance View:** Frame rendering analysis
- **Memory View:** Heap snapshots, allocation tracking
- **Network View:** HTTP request inspection
- **Logging View:** Structured log viewing

**How to use:**
```bash
flutter pub global activate devtools
devtools
```

Or use the integrated DevTools in VS Code/Android Studio.

**Learning resources:**
- [DevTools Documentation](https://docs.flutter.dev/tools/devtools)
- [Using the Memory View](https://docs.flutter.dev/tools/devtools/memory)

---

## Testing

### Unit Testing with flutter_test

**What it is:** Flutter's built-in testing framework for unit tests, widget tests, and integration tests.

**Why it matters:**
- Currently 0% test coverage (critical gap)
- Essential for safe refactoring
- Required for CI/CD pipelines

**Key concepts:**
- **Unit Tests:** Test individual functions and classes
- **Widget Tests:** Test widget rendering and interaction
- **Integration Tests:** Test complete user flows
- **Mocking:** Isolate units with fake dependencies

**Testing Cubits:**
```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<PlayerCubit, PlayerCubitState>(
  'emits playing state when play is called',
  build: () => PlayerCubit(),
  act: (cubit) => cubit.play(),
  expect: () => [
    isA<PlayerCubitState>().having((s) => s.isPlay, 'isPlay', true),
  ],
);
```

**Recommended packages:**
- `bloc_test` - Testing utilities for BLoC
- `mocktail` - Mocking library (simpler than mockito)
- `golden_toolkit` - Visual regression testing

**Learning resources:**
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [bloc_test Package](https://pub.dev/packages/bloc_test)
- [Effective Testing with BLoC](https://bloclibrary.dev/#/testing)

---

### Integration Testing with patrol

**What it is:** A testing framework that extends Flutter's integration tests with native automation, allowing interaction with system dialogs, permissions, and notifications.

**Why investigate:**
- Test location permission flows
- Test background audio behavior
- Test real device scenarios

**Example:**
```dart
patrolTest('grants location permission', ($) async {
  await $.pumpWidget(MyApp());

  // Handle native permission dialog
  await $.native.grantPermissionWhenInUse();

  // Verify app behavior
  expect(find.text('Location enabled'), findsOneWidget);
});
```

**Learning resources:**
- [Patrol Documentation](https://patrol.leancode.co)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)

---

## Performance & Debugging

### Flutter Performance Best Practices

**Key optimization techniques:**

**1. Minimize Rebuilds:**
```dart
// Bad: Rebuilds entire subtree
BlocBuilder<RadioListCubit, RadioListState>(
  builder: (context, state) => ExpensiveWidget(state),
)

// Good: Selective rebuilds
context.select((RadioListCubit c) => c.state.radioList)
```

**2. Use const Constructors:**
```dart
// Prevents unnecessary rebuilds
const SizedBox(height: 16),
const Icon(Icons.play_arrow),
```

**3. Lazy Loading:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

**4. Image Optimization:**
```dart
CachedNetworkImage(
  imageUrl: url,
  memCacheHeight: 200,  // Resize in memory
  maxHeightDiskCache: 400,
)
```

**5. Avoid Expensive Operations in Build:**
```dart
// Bad: Computed in build
Widget build(context) {
  final sorted = list.sort();  // O(n log n) every build!
}

// Good: Computed in state
void updateList() {
  final sorted = list.sort();
  emit(state.copyWith(sortedList: sorted));
}
```

**Learning resources:**
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Reducing Widget Rebuilds](https://docs.flutter.dev/perf/rendering-performance)

---

### Memory Management

**Why it matters:**
- Radio apps run for extended periods
- Real-time features (transcripts, visualization) generate data
- Memory leaks cause crashes

**Key practices:**

**1. Dispose Resources:**
```dart
@override
void dispose() {
  _controller.dispose();
  _subscription.cancel();
  _timer?.cancel();
  super.dispose();
}
```

**2. Cancel Network Requests:**
```dart
CancelToken? _token;

void loadData() {
  _token?.cancel();
  _token = CancelToken();
  repository.getData(cancelToken: _token);
}
```

**3. Limit Cached Data:**
```dart
// Don't keep unlimited history
if (chunks.length > maxChunks) {
  chunks.removeRange(0, chunks.length - maxChunks);
}
```

**4. Use Weak References for Caches:**
```dart
final _cache = Expando<ExpensiveObject>();
```

---

## CI/CD & DevOps

### GitHub Actions for Flutter

**What it is:** GitHub's built-in CI/CD platform that can build, test, and deploy Flutter apps.

**Why investigate:**
- Automate testing on every PR
- Catch regressions early
- Automate release builds

**Example workflow:**
```yaml
name: Flutter CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'

      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
```

**Learning resources:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)

---

### Fastlane for Mobile Deployment

**What it is:** A tool to automate building and releasing mobile apps, handling code signing, screenshots, and store deployment.

**Why investigate:**
- Automate Play Store / App Store uploads
- Manage signing certificates
- Generate screenshots automatically

**Example Fastfile:**
```ruby
lane :beta do
  build_flutter_app(
    build_type: "appbundle"
  )
  upload_to_play_store(
    track: "beta"
  )
end
```

**Learning resources:**
- [Fastlane Documentation](https://docs.fastlane.tools)
- [Flutter Fastlane Setup](https://docs.flutter.dev/deployment/cd#fastlane)

---

### Firebase App Distribution (Worth Investigating)

**What it is:** Firebase service for distributing pre-release apps to testers.

**Why investigate:**
- Easy beta distribution
- Tester management
- Crash reporting integration
- No app store review delays

**Learning resources:**
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)

---

## Security

### Flutter Secure Storage

**What it is:** A plugin that stores data in secure storage (Keychain on iOS, KeyStore on Android).

**Why it matters:**
- Current project uses `SharedPreferences` for all data
- Sensitive data (tokens, user preferences) should be encrypted

**Usage:**
```dart
final storage = FlutterSecureStorage();

// Write
await storage.write(key: 'token', value: 'secret-token');

// Read
String? token = await storage.read(key: 'token');

// Delete
await storage.delete(key: 'token');
```

**Learning resources:**
- [flutter_secure_storage Package](https://pub.dev/packages/flutter_secure_storage)

---

### OWASP Mobile Security

**What it is:** The Open Web Application Security Project's guidelines for mobile app security.

**Key areas:**
- **M1:** Improper Platform Usage
- **M2:** Insecure Data Storage
- **M3:** Insecure Communication
- **M4:** Insecure Authentication
- **M5:** Insufficient Cryptography

**Learning resources:**
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)

---

## Emerging Technologies

### Flutter Web & Desktop

**What it is:** Flutter's ability to compile to web (HTML/JS/WebAssembly) and desktop (Windows, macOS, Linux) from the same codebase.

**Why investigate:**
- Expand to web browsers
- Create desktop companion apps
- Single codebase for all platforms

**Considerations:**
- Audio playback differences between platforms
- Platform-specific UI adaptations
- Web limitations (no background audio without PWA)

**Learning resources:**
- [Flutter Web](https://docs.flutter.dev/platform-integration/web)
- [Flutter Desktop](https://docs.flutter.dev/platform-integration/desktop)

---

### Dart 3 Features

**What it is:** Dart 3 introduced major language features that improve code expressiveness and safety.

**Key features to learn:**

**1. Records:**
```dart
// Return multiple values
(String, int) getNameAndAge() => ('John', 30);
final (name, age) = getNameAndAge();
```

**2. Patterns:**
```dart
// Pattern matching
switch (state) {
  case LoadingState(): return CircularProgressIndicator();
  case ErrorState(message: var msg): return Text(msg);
  case DataState(items: var list): return ListView(...);
}
```

**3. Class Modifiers:**
```dart
// Sealed classes for exhaustive switching
sealed class Result {}
class Success extends Result {}
class Failure extends Result {}
```

**Learning resources:**
- [Dart 3 Documentation](https://dart.dev/resources/dart-3-migration)
- [Patterns and Records](https://dart.dev/language/patterns)

---

### AI/ML Integration

**What it is:** Using machine learning models in Flutter apps for features like speech recognition, translation, or recommendations.

**Why investigate:**
- Enhanced transcription accuracy
- Personalized radio recommendations
- On-device audio processing

**Options:**
- **TensorFlow Lite:** On-device ML inference
- **ML Kit:** Google's ML APIs (text recognition, translation)
- **Custom Models:** Via `tflite_flutter` package

**Learning resources:**
- [TensorFlow Lite Flutter](https://pub.dev/packages/tflite_flutter)
- [ML Kit for Flutter](https://pub.dev/packages/google_mlkit_commons)

---

## Learning Path Recommendations

### For New Flutter Developers

1. **Week 1-2:** Dart fundamentals, null safety, async programming
2. **Week 3-4:** Flutter basics, widget lifecycle, layouts
3. **Week 5-6:** State management with BLoC/Cubit
4. **Week 7-8:** Navigation with GoRouter, networking with Dio

### For Experienced Flutter Developers New to This Project

1. **Day 1:** Read `docs/architecture.md` and `docs/bloc-cubit-usage.md`
2. **Day 2:** Explore `lib/features/` structure, trace a feature end-to-end
3. **Day 3:** Understand `GlobalCubitConnection` and cross-cubit communication
4. **Day 4:** Review `docs/security-assessment.md` and `docs/app-quality-evaluation.md`

### For Improving the Codebase

1. **Immediate:** Add unit tests for cubits
2. **Short-term:** Implement code generation (freezed, json_serializable)
3. **Medium-term:** Set up CI/CD with GitHub Actions
4. **Long-term:** Investigate WebSockets for real-time features

---

## Conclusion

This stack uses well-established technologies (Flutter, BLoC, GoRouter, Dio) that have strong community support and documentation. Focus your learning on:

1. **BLoC/Cubit mastery** - Essential for understanding and extending the app
2. **Testing** - Critical gap that needs immediate attention
3. **Performance optimization** - Important for long-running radio streaming
4. **Security practices** - Address current vulnerabilities

The emerging technologies section highlights areas for future improvement, but the core stack is solid and widely used in production apps.
