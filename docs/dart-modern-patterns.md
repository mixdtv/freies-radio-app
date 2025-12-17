# Modern and Uncommon Dart/Flutter Patterns

This document highlights modern and less common Dart language patterns used in this codebase.

## Enhanced Enums (Dart 2.17+)

Enums with fields and const constructors - a powerful feature added in Dart 2.17:

```dart
// lib/features/transcript/bloc/transcript_cubit.dart:24-38
enum TranscriptFontSize {
  small(24),
  medium(30),
  big(45);

  const TranscriptFontSize(this.size);
  final double size;
}

enum TranscriptSpeed {
  speed05(0.5),
  speed075(0.75),
  speedNormal(1);

  const TranscriptSpeed(this.speed);
  final double speed;
}
```

This eliminates the need for separate maps or switch statements to associate values with enum members.

## Super Parameters (Dart 2.17+)

Shorthand syntax for passing parameters to super constructor:

```dart
// lib/app/app_scope.dart:18
const AppScope({super.key, required this.child});
```

Instead of the verbose:
```dart
const AppScope({Key? key, required this.child}) : super(key: key);
```

## Extension Methods

Type-safe extensions to add functionality to existing classes:

```dart
// lib/utils/extensions.dart
extension Date on DateTime {
  String toFormat(String mask) => DateFormat(mask).format(this);
  DateTime toDate() => DateTime(year, month, day);
}

extension Str on String {
  String stripHtml() => replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  String capitalize() => "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}

// Generic extension
extension ListUpdate<T> on List<T> {
  T? tryGet(int i) {
    if (isEmpty || i >= length) return null;
    return this[i];
  }

  T? firstOrNullWhere(bool Function(T) compare) {
    for (int i = 0; i < length; i++) {
      if (compare(this[i])) return this[i];
    }
    return null;
  }
}
```

## Cascade Notation

Chaining method calls on the same object:

```dart
// lib/data/api/repository.dart:187
final totalStopwatch = Stopwatch()..start();
```

## Late Initialization

Defer initialization of non-nullable fields:

```dart
// lib/data/api/repository.dart:60
late HttpApi api;

// lib/app/app_state.dart:16
late final AppLifecycleListener _listener;
```

## Null-Aware Assignment Operator

Singleton pattern using `??=`:

```dart
// lib/data/api/repository.dart:54-58
static Repository? _instance;
static Repository getInstance() {
  _instance ??= Repository._();
  return _instance!;
}
```

## Private Named Constructors

For singleton or factory patterns:

```dart
// lib/utils/settings.dart:27
AppSettings._();

// lib/data/api/repository.dart:66
Repository._();
```

## Getter/Setter Shorthand

Arrow syntax for computed properties:

```dart
// lib/utils/settings.dart:110-118
bool get isAskLocationLater => _prefs.getBool("isAskLocationLather") ?? false;
set isAskLocationLater(bool value) => _prefs.setBool("isAskLocationLather", value);

bool get isFirstStart => _prefs.getBool("isFirstStart") ?? true;
set isFirstStart(bool value) => _prefs.setBool("isFirstStart", value);
```

## Named Constructor for Initial State

Pattern for creating default/initial states:

```dart
// lib/features/transcript/bloc/transcript_cubit.dart:344-361
const TranscriptState.init({
  this.list = const [],
  this.langs = const [],
  this.isLoading = false,
  this.fontSize = TranscriptFontSize.medium,
  this.speed = TranscriptSpeed.speedNormal,
});
```

## Compile-Time Configuration

Using `String.fromEnvironment` and `bool.fromEnvironment`:

```dart
// lib/config/app_config.dart:4-46
class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_URL');
  static const String apiKey = String.fromEnvironment('API_KEY');

  static const bool useSourceStream = bool.fromEnvironment(
    'USE_SOURCE_STREAM',
    defaultValue: true,
  );
}
```

Pass values via `--dart-define=API_KEY=secret` or `--dart-define-from-file=.env.json`.

## AppLifecycleListener (Flutter 3.13+)

Modern replacement for `WidgetsBindingObserver`:

```dart
// lib/app/app_state.dart:19-25
_listener = AppLifecycleListener(
  onPause: _pauseApp,
  onRestart: _unPauseApp,
  onDetach: _stopApp
);
```

More declarative than implementing `didChangeAppLifecycleState`.

## Isolate Compute for Heavy Operations

Top-level functions with `compute()` for CPU-intensive tasks:

```dart
// lib/data/api/repository.dart:19-50
// Must be top-level or static to work with compute()
Map<String, dynamic> _parsePodcastFeedIsolate(Map<String, dynamic> params) {
  final data = params['data'] as String;
  final rssFeed = RssFeed.parse(data);
  // ... heavy parsing work
  return result;
}

// Usage:
final podcastJson = await compute(_parsePodcastFeedIsolate, {
  'data': response.data as String,
  'feedUrl': feedUrl,
});
```

## CopyWith Pattern

Immutable state updates common in BLoC/Cubit:

```dart
// lib/features/auth/session_cubit.dart:43-48
SessionState copyWith({String? lang}) {
  return SessionState(
    lang: lang ?? this.lang,
  );
}
```

## Mixin Composition

Combining multiple behaviors:

```dart
// lib/features/auth/session_cubit.dart:14-15
class SessionCubit extends Cubit<SessionState>
    with BlocPresentationMixin<SessionState, SessionEvents> {
```

## Safe Nullable Chaining

Combining `?.` and `== true` for null-safe boolean checks:

```dart
// lib/features/player/player_cubit.dart:96
if (episode.imageUrl.isNotEmpty && Uri.tryParse(episode.imageUrl)?.hasAbsolutePath == true) {
  artUri = Uri.parse(episode.imageUrl);
}
```

## Typed Collections in Constructors

Default const empty collections:

```dart
// lib/features/podcast/bloc/podcast_cubit.dart:8-17
class PodcastState {
  final List<Podcast> podcasts;

  PodcastState({
    this.podcasts = const [],  // Immutable default
    this.isLoading = false,
    this.error,
  });
}
```

## Future.wait for Parallel Async

Concurrent API calls:

```dart
// lib/features/podcast/bloc/podcast_cubit.dart:70-75
final podcasts = await Future.wait(
  feedUrls.map((url) => repository.loadPodcastFeed(
    feedUrl: url,
    cancelToken: _cancelToken,
  )),
);
```

## Pattern Summary

| Pattern | Dart Version | Location |
|---------|-------------|----------|
| Enhanced Enums | 2.17+ | `transcript_cubit.dart` |
| Super Parameters | 2.17+ | Multiple widgets |
| Extension Methods | 2.6+ | `extensions.dart` |
| Late Variables | 2.9+ | `repository.dart`, `app_state.dart` |
| Null-Aware Assignment | 2.0+ | Singleton patterns |
| Compile-Time Config | 2.0+ | `app_config.dart` |
| AppLifecycleListener | Flutter 3.13+ | `app_state.dart` |
| Compute Isolates | 2.0+ | `repository.dart` |