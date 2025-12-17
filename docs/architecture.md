# Application Architecture

**Version:** 1.1
**Last Updated:** December 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Application Initialization](#application-initialization)
4. [State Management Architecture](#state-management-architecture)
5. [Core Features](#core-features)
6. [Services Layer](#services-layer)
7. [Data Layer](#data-layer)
8. [UI Layer](#ui-layer)
9. [Navigation Architecture](#navigation-architecture)
10. [Platform-Specific Implementations](#platform-specific-implementations)
11. [Configuration Management](#configuration-management)
12. [Localization](#localization)
13. [Architectural Patterns](#architectural-patterns)
14. [Data Flow](#data-flow)
15. [Technology Stack](#technology-stack)
16. [Performance Optimizations](#performance-optimizations)
17. [Security Considerations](#security-considerations)
18. [Testing Strategy](#testing-strategy)

---

## Overview

This is a Flutter-based radio streaming application focused on local, non-commercial radio stations from Berlin and Brandenburg. The app provides live audio streaming, program schedules, podcasts, live transcription, and location-based station discovery.

### Key Characteristics

- **Platform:** Cross-platform (iOS & Android)
- **Architecture Pattern:** Feature-based modular architecture
- **State Management:** BLoC pattern using Cubit
- **Navigation:** Declarative routing with GoRouter
- **Target Market:** German-speaking users in Berlin & Brandenburg region
- **Codebase Size:** ~110 Dart files

---

## Project Structure

The project follows a clean, feature-based architecture with clear separation of concerns:

```
lib/
├── app/                    # Application shell & global UI
│   ├── bottom_navigation/  # Bottom navigation bar logic
│   ├── drawer/             # Navigation drawer components
│   ├── pages/              # App-level pages (settings, appearance)
│   ├── widgets/            # Reusable UI components
│   ├── router.dart         # GoRouter configuration
│   ├── app_page.dart       # Main app shell
│   ├── app_scope.dart      # Feature-level BLoC providers
│   ├── app_state.dart      # App state management
│   ├── style.dart          # Theme definitions
│   └── theme_cubit.dart    # Theme state management
│
├── features/               # Feature modules (domain-driven)
│   ├── auth/               # Authentication & splash screen
│   │   ├── session_cubit.dart
│   │   └── splash_page.dart
│   │
│   ├── location/           # GPS location services
│   │   ├── location_cubit.dart
│   │   ├── location_service.dart
│   │   ├── location_request_page.dart
│   │   ├── model/
│   │   └── widgets/
│   │
│   ├── player/             # Audio player & controls
│   │   ├── player_cubit.dart
│   │   ├── media_player.dart
│   │   └── widgets/
│   │
│   ├── radio_list/         # Radio station browsing
│   │   ├── cubit/
│   │   ├── radio_list_page.dart
│   │   ├── radio_list_search_page.dart
│   │   └── widget/
│   │
│   ├── radio_about/        # Station details & info
│   ├── timeline/           # EPG (Electronic Program Guide)
│   ├── transcript/         # Live transcription feature
│   ├── visual/             # Audio visualization
│   └── podcast/            # Podcast browsing & playback
│       ├── bloc/
│       ├── podcast_list_page.dart
│       └── podcast_episodes_page.dart
│
├── data/                   # Data layer
│   ├── api/                # Network layer
│   │   ├── http_api.dart   # Dio-based HTTP client wrapper
│   │   ├── repository.dart # API endpoint implementations
│   │   └── response/       # API response models
│   │
│   └── model/              # Domain models
│       ├── radio.dart
│       ├── podcast.dart
│       ├── transcript_chunk.dart
│       └── ...
│
├── utils/                  # Utilities & helpers
│   ├── adaptive/           # Responsive design utilities
│   ├── settings.dart       # SharedPreferences wrapper
│   ├── app_logger.dart     # Logging utilities
│   └── error_mapper.dart   # Error handling
│
├── config/                 # App configuration
│   └── app_config.dart     # Build-time configuration
│
├── l10n/                   # Localization files
│   ├── app_en.arb          # English translations
│   └── app_de.arb          # German translations
│
└── main.dart               # Application entry point

android/                    # Android native configuration
ios/                        # iOS native configuration
assets/                     # Static assets
│   ├── fonts/              # Custom fonts (Inter, DM Mono)
│   ├── icons/              # App icons
│   └── images/             # Splash screens, logos
│
docs/                       # Project documentation
test/                       # Unit & widget tests
```

### Directory Organization Principles

1. **Feature-Based Structure:** Each feature is self-contained with its own cubits, pages, and widgets
2. **Layer Separation:** Clear boundaries between UI, business logic, and data layers
3. **Shared Resources:** Common utilities and widgets in dedicated directories
4. **Configuration Centralization:** All build-time configs in a single location

---

## Application Initialization

### Entry Point Flow

**File:** `lib/main.dart`

The application initialization follows a sequential bootstrap process:

```dart
Future<void> main() async {
  // 1. Initialize logging
  initLogging(level: Level.INFO);

  // 2. Initialize Flutter bindings
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 3. Preserve native splash screen during initialization
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 4. Load settings from SharedPreferences
  AppSettings settings = AppSettings.getInstance();
  await settings.loadSettings();

  // 5. Generate or retrieve device ID
  String deviceId = await settings.getDeviceId();

  // 6. Initialize repository singleton with device ID
  Repository.getInstance().init(deviceId);

  // 7. Configure router with initial page
  GoRouter router = AppNavigation.initAppRouter(initPage: SplashPage.path);

  // 8. Initialize audio service
  var mediaPlayer = MediaPlayer();
  _audioHandler = await AudioService.init(
    builder: () => mediaPlayer,
    config: AudioServiceConfig(...),
  );

  // 9. Apply saved playback speed
  mediaPlayer.setSpeed(settings.getSpeed().speed);

  // 10. Remove splash screen
  FlutterNativeSplash.remove();

  // 11. Run app with provider tree
  runApp(ToastificationWrapper(
    child: MultiBlocProvider(
      providers: [...],
      child: MaterialApp.router(...),
    ),
  ));
}
```

### Initialization Steps Explained

1. **Logging Setup:** Configures app-wide logging with INFO level
2. **Flutter Bindings:** Ensures Flutter framework is ready before async operations
3. **Native Splash:** Keeps native splash screen visible during initialization
4. **Settings Load:** Retrieves persisted user preferences (theme, favorites, etc.)
5. **Device ID:** Generates unique identifier for API tracking:
   - **Android:** Uses `android_id` package to get Android ID
   - **iOS:** Generates UUID using `uuid` package, persisted in SharedPreferences
6. **Repository:** Initializes singleton HTTP client with device ID header
7. **Router:** Configures declarative routing starting from splash page
8. **Audio Service:** Initializes background audio handler for media playback
9. **Playback Speed:** Restores user's preferred playback speed
10. **Splash Removal:** Removes native splash after initialization
11. **Provider Tree:** Mounts global BLoC providers at root level

---

## State Management Architecture

### BLoC Pattern with Cubit

The app uses the **BLoC (Business Logic Component)** pattern with **Cubit** (simplified BLoC without events).

#### Why Cubit over Full BLoC?

- **Simpler API:** Direct method calls instead of event dispatching
- **Less Boilerplate:** No need to define event classes
- **Type Safety:** Method parameters provide compile-time type checking
- **Easier Debugging:** Direct method calls are easier to trace

### Cubit Hierarchy

#### Global Scope
Created in `main.dart` and available throughout the app:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => SessionCubit(settings: ..., deviceId: ...)),
    BlocProvider(create: (_) => PlayerCubit(mediaPlayer)),
    BlocProvider(create: (_) => ThemeCubit(settings.getThemeType())),
    BlocProvider(create: (_) => LocationCubit()),
  ],
  child: App(),
)
```

- **SessionCubit:** User session & language management
- **PlayerCubit:** Audio playback state and controls
- **ThemeCubit:** Dark/light/auto theme management
- **LocationCubit:** GPS location permissions and data

#### Feature Scope
Created in `AppScope` and available to feature pages:

**File:** `lib/app/app_scope.dart`

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => RadioListCubit()),
    BlocProvider(create: (_) => RadioFavoriteCubit()),
    BlocProvider(create: (_) => TimeLineCubit()),
    BlocProvider(create: (_) => BottomNavigationCubit()),
    BlocProvider(create: (context) => TranscriptCubit(
      player: context.read<PlayerCubit>().player,
    )),
    BlocProvider(create: (_) => PodcastCubit(repository: Repository.getInstance())),
  ],
  child: AppState(child: GlobalCubitConnection(child: child)),
)
```

#### Page Scope
Created per-route for specific page needs:

```dart
BlocProvider(
  create: (context) => RadioListCityCubit(locationCity),
  child: PageRadioListCity(),
)
```

### State Access Patterns

#### 1. Read without Listening (Actions)
```dart
// Trigger action without rebuilding widget
context.read<PlayerCubit>().play();
```

#### 2. Select Specific State (Optimized Rebuilds)
```dart
// Only rebuild when selectedRadio changes
final radio = context.select((PlayerCubit c) => c.state.selectedRadio);
```

#### 3. BlocBuilder (Full State Listening)
```dart
BlocBuilder<PlayerCubit, PlayerState>(
  builder: (context, state) {
    if (state.isPlaying) {
      return PauseButton();
    }
    return PlayButton();
  },
)
```

#### 4. BlocPresentationListener (One-Time Events)
```dart
BlocPresentationListener<SessionCubit, SessionEvent>(
  listener: (context, event) {
    if (event is SessionExpiredEvent) {
      context.go('/login');
    }
  },
  child: child,
)
```

### State Immutability

All state classes use the `copyWith` pattern:

```dart
class PlayerState {
  final AppRadio? selectedRadio;
  final bool isPlaying;
  final bool isLoading;

  PlayerState copyWith({
    AppRadio? selectedRadio,
    bool? isPlaying,
    bool? isLoading,
  }) {
    return PlayerState(
      selectedRadio: selectedRadio ?? this.selectedRadio,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
```

---

## Core Features

### 1. Live Radio Streaming

**Location:** `lib/features/player/`

#### Architecture

```
User Action (Play Button)
    ↓
PlayerCubit.play()
    ↓
MediaPlayer (AudioHandler)
    ↓
just_audio (Custom Fork)
    ↓
Platform Audio Engine
```

#### Key Components

**MediaPlayer (BaseAudioHandler)**
**File:** `lib/features/player/media_player.dart`

Extends `BaseAudioHandler` from `audio_service` package to provide:
- Background audio playback
- Media notification controls
- Playback state management
- Stream URL handling

**PlayerCubit**
**File:** `lib/features/player/player_cubit.dart`

Manages player state:
```dart
class PlayerState {
  final AppRadio? selectedRadio;
  final bool isPlaying;
  final bool isLoading;
  final bool isFavorite;
  final PlaybackSpeed speed;
}
```

**Key Methods:**
- `selectRadio(AppRadio radio)` - Select and start playing a station
- `play()` - Resume playback
- `pause()` - Pause playback
- `setSpeed(PlaybackSpeed speed)` - Adjust playback speed

#### Stream Source Toggle

**File:** `lib/config/app_config.dart`

```dart
static const bool useSourceStream = bool.fromEnvironment(
  'USE_SOURCE_STREAM',
  defaultValue: true,
);
```

**Stream Options:**
- **HLS Stream:** Widely compatible, adaptive bitrate
- **Source Stream (default):** Original broadcaster stream, higher quality

#### Custom just_audio Fork

**Repository:** `https://github.com/IgoTs/just_audio.git`
**Branch:** `minor`

See: [docs/custom-just-audio-fork.md](custom-just-audio-fork.md) for details.

#### Background Audio Service

Uses `audio_service` package for:
- **iOS:** Background audio with AVAudioSession
- **Android:** Foreground service with media notification
- **Media Controls:** Play/pause from lock screen and notification
- **Metadata Display:** Station name, logo, current program

---

### 2. Location-Based Discovery

**Location:** `lib/features/location/`

#### Architecture

```
User Opens App
    ↓
LocationCubit.requestPermission()
    ↓
LocationService.requestPermission()
    ↓
Platform Permission Dialog
    ↓
If Granted: Get GPS Coordinates
    ↓
API Call: /radios?lat={lat}&lng={lng}
    ↓
Display Nearby Stations
```

#### Components

**LocationCubit**
**File:** `lib/features/location/location_cubit.dart`

**LocationService**
**File:** `lib/features/location/location_service.dart`

Wraps `geolocator` package for GPS and permission handling.

#### City Selection Fallback

If user denies location permission or GPS unavailable:
- Search for city by name
- Select from popular cities list
- Filter stations by selected city

---

### 3. Podcasts

**Location:** `lib/features/podcast/`

#### Architecture

```
User Selects Station with Podcasts
    ↓
PodcastCubit.loadPodcasts(feedUrls)
    ↓
Repository.loadPodcastFeed() (for each URL)
    ↓
Parse RSS Feed (dart_rss)
    ↓
Display Podcast List
    ↓
User Selects Podcast
    ↓
Display Episodes
    ↓
Play Episode via PlayerCubit
```

#### Key Components

**PodcastCubit**
**File:** `lib/features/podcast/bloc/podcast_cubit.dart`

```dart
class PodcastState {
  final List<Podcast> podcasts;
  final bool isLoading;
  final String? error;
}
```

**Key Methods:**
- `loadPodcasts(List<String> feedUrls)` - Load podcasts from RSS feeds
- `preloadPodcasts(List<String> feedUrls)` - Background preload for faster navigation
- `clear()` - Reset podcast state

**Podcast Model**
**File:** `lib/data/model/podcast.dart`

```dart
class Podcast {
  final String title;
  final String description;
  final String imageUrl;
  final String feedUrl;
  final List<PodcastEpisode> episodes;
}

class PodcastEpisode {
  final String title;
  final String description;
  final String imageUrl;
  final String audioUrl;
  final DateTime? pubDate;
  final Duration? duration;
}
```

#### Features

- **RSS Feed Parsing:** Uses `dart_rss` package
- **Preloading:** Background loading for faster navigation
- **Cancellation:** Proper request cancellation on navigation
- **Episode Playback:** Integrated with main player

---

### 4. Live Transcription

**Location:** `lib/features/transcript/`

#### Architecture Overview

```
User Opens Transcript
    ↓
TranscriptCubit.startTranscript()
    ↓
Timer (every 1 second)
    ↓
Calculate current chunk timestamp
    ↓
API: /radios/{id}/transcript/chunks/{timestamp}
    ↓
Display words with highlighting
```

#### Features

**Word-Level Synchronization:**
Each word has start/end timestamp for precise highlighting.

**Multi-Language Translation:**
- German (primary)
- English
- Turkish
- Arabic
- Russian
- Ukrainian
- Polish

**Adjustable Settings:**
- Font size options
- Playback speed synchronization
- Auto-scroll

---

### 5. Program Timeline (EPG)

**Location:** `lib/features/timeline/`

#### Architecture

```
User Selects Station
    ↓
TimeLineCubit.loadEpg()
    ↓
API: GET /epg/{epgPrefix}
    ↓
Display Programs with Progress Bars
    ↓
Timer: Auto-refresh
```

#### Features

- **Live Progress Bars:** Show percentage of program completed
- **Current Program Highlight:** Different styling for active program
- **Pagination:** Load more as user scrolls
- **Time Display:** Format times based on user locale

---

### 6. Audio Visualization

**Location:** `lib/features/visual/`

#### Architecture

```
Audio Playback Active
    ↓
Timer (every 100ms)
    ↓
API: GET /radios/{id}/visual/chunks/{timestamp}
    ↓
Parse FFT Data
    ↓
Render Frequency Bars
```

---

## Services Layer

### Network Layer

**File:** `lib/data/api/http_api.dart`

Wrapper around Dio HTTP client with:
- Configurable base URL via environment
- Device ID header for tracking
- Request/response logging
- Timeout configuration

### Repository Pattern

**File:** `lib/data/api/repository.dart`

Centralized API endpoint management as a singleton:

```dart
class Repository {
  static Repository? _instance;

  static Repository getInstance() {
    _instance ??= Repository();
    return _instance!;
  }

  // Radio endpoints
  Future<List<AppRadio>> getRadios({double? lat, double? lng});

  // EPG endpoints
  Future<List<RadioEpg>> getEpg(String epgPrefix);

  // Podcast endpoints
  Future<Podcast> loadPodcastFeed({required String feedUrl, CancelToken? cancelToken});

  // Transcript endpoints
  Future<TranscriptChunk> getTranscriptChunk(String radioId, int timestamp);
}
```

### Persistent Storage

**File:** `lib/utils/settings.dart`

`AppSettings` singleton wrapper around `shared_preferences`:
- Theme mode
- Language preference
- Location permission status
- Playback speed
- Device ID (iOS)

---

## Data Layer

### Domain Models

**Location:** `lib/data/model/`

#### AppRadio
**File:** `radio.dart`

Represents a radio station with stream URLs, metadata, and EPG prefix.

#### Podcast
**File:** `podcast.dart`

```dart
class Podcast {
  final String title;
  final String description;
  final String imageUrl;
  final String feedUrl;
  final List<PodcastEpisode> episodes;
}
```

#### TranscriptChunk
**File:** `transcript_chunk.dart`

Contains timestamped transcript data with word-level timing.

#### VisualChunk
**File:** `visual_chunk.dart`

FFT data for audio visualization.

---

## UI Layer

### Theme System

**File:** `lib/app/style.dart`

#### Theme Structure

```dart
class AppStyle {
  static const String themeDark = 'dark';
  static const String themeLight = 'light';
  static const String themeAuto = 'auto';

  static ThemeData dark() => ThemeData(...);
  static ThemeData light() => ThemeData(...);
}
```

#### Typography

**Fonts:**
- **Primary:** Inter (9 weights: 100-900)
- **Monospace:** DM Mono (Light, Regular, Medium)

#### Theme Management

**ThemeCubit**
**File:** `lib/app/theme_cubit.dart`

Manages theme state with support for dark, light, and system-auto modes.

---

### Adaptive UI

**Location:** `lib/utils/adaptive/`

#### Screen Size Detection

**File:** `screen_type.dart`

```dart
enum ScreenType {
  small,  // < 600px
  medium, // 600-1200px
  big,    // > 1200px
}
```

---

## Navigation Architecture

### GoRouter Configuration

**File:** `lib/app/router.dart`

#### Route Structure

```dart
GoRouter(
  initialLocation: initPage,
  routes: [
    // Standalone routes
    GoRoute(path: '/splash', ...),
    GoRoute(path: '/location-request', ...),

    // App Scope ShellRoute
    ShellRoute(
      builder: (context, state, child) => AppScope(child: child),
      routes: [
        GoRoute(path: '/appearance', ...),
        GoRoute(path: '/search', ...),
        GoRoute(path: '/city', ...),
        GoRoute(path: '/', ...),  // Radio list

        // Detail pages ShellRoute
        ShellRoute(
          builder: (...) => AppPage(child: child),
          routes: [
            GoRoute(path: '/about', ...),
            GoRoute(path: '/timeline', ...),
            GoRoute(path: '/transcript', ...),
            GoRoute(path: '/visual', ...),
            GoRoute(path: '/podcasts', ...),
            GoRoute(path: '/podcast-episodes', ...),
          ],
        ),
      ],
    ),
  ],
)
```

#### Navigation Patterns

**Imperative Navigation:**
```dart
context.go('/timeline');
context.push('/search');
context.pop();
```

---

### Bottom Navigation

**File:** `lib/app/bottom_navigation/`

#### Dynamic Menu Items

Configured in `lib/config/app_config.dart`:

```dart
static const List<String> visibleMenuItems = ['timeline', 'podcasts', 'about'];
```

**Available items:**
- `timeline` - Program schedule
- `podcasts` - Station podcasts (only shown if station has podcasts)
- `transcript` - Live transcript
- `visual` - Audio visualization
- `about` - Station info

---

## Platform-Specific Implementations

### Android Configuration

**Files:**
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`

#### Permissions

```xml
<!-- Network -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Audio Service -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

---

### iOS Configuration

**Files:**
- `ios/Podfile`
- `ios/Runner/Info.plist`

#### Key Configurations

- Location permission description
- Background audio mode
- App Transport Security (allows HTTP for radio streams)

---

## Configuration Management

### Build-Time Configuration

**File:** `lib/config/app_config.dart`

Uses Dart's `--dart-define` for build-time configuration:

```dart
class AppConfig {
  // API Base URL (required via --dart-define-from-file)
  static String get apiBaseUrl { ... }

  // EPG Base URL (required via --dart-define-from-file)
  static String get epgBaseUrl { ... }

  // API Key
  static const String apiKey = String.fromEnvironment('API_KEY');

  // Stream source toggle
  static const bool useSourceStream = bool.fromEnvironment(
    'USE_SOURCE_STREAM',
    defaultValue: true,
  );

  // Visible menu items
  static const List<String> visibleMenuItems = ['timeline', 'podcasts', 'about'];
}
```

### Build Examples

**Development:**
```bash
flutter run --dart-define-from-file=.env.json
```

**Production:**
```bash
flutter build apk --dart-define-from-file=.env.json
```

---

## Localization

### Supported Languages

- **English (en)** - Default/fallback
- **German (de)** - Primary language

### ARB Files

**Location:** `lib/l10n/`

### Usage in Code

```dart
import 'package:radiozeit/l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.playButton)
```

---

## Architectural Patterns

### 1. Repository Pattern
Single `Repository` singleton for all API calls with type-safe methods.

### 2. BLoC Pattern (Cubit)
Cubits manage feature state with immutable state classes.

### 3. Dependency Injection
Constructor injection for dependencies, Provider pattern for widget tree.

### 4. Immutable State
All state classes use `copyWith` pattern for predictable updates.

### 5. Feature Module Organization
Each feature is self-contained with its own cubits, pages, and widgets.

### 6. Presentation Events Pattern
Using `bloc_presentation` for one-time UI events (navigation, dialogs, toasts).

---

## Data Flow

### Typical User Action Flow

```
1. User Action
   ↓
   User taps "Play" button

2. UI Layer
   ↓
   onPressed: () => context.read<PlayerCubit>().play()

3. Business Logic Layer
   ↓
   PlayerCubit.play() {
     emit(state.copyWith(isLoading: true));
     await _audioHandler.play();
     emit(state.copyWith(isLoading: false, isPlaying: true));
   }

4. Service Layer
   ↓
   MediaPlayer.play()

5. State Update
   ↓
   Cubit emits new state

6. UI Rebuild
   ↓
   BlocBuilder rebuilds with new state
```

---

## Technology Stack

### Core Framework

- **Flutter SDK:** >=3.2.0 <4.0.0
- **Dart SDK:** >=3.2.0 <4.0.0

### State Management

- **bloc:** ^8.1.2
- **flutter_bloc:** ^8.1.3
- **bloc_presentation:** ^1.0.0

### Navigation

- **go_router:** ^13.0.1

### Networking

- **dio:** ^5.4.0
- **cached_network_image:** ^3.3.1

### Audio

- **just_audio:** Custom fork from GitHub
- **audio_service:** ^0.18.13

### Podcasts

- **dart_rss:** ^3.0.3

### Location

- **geolocator:** ^12.0.0
- **geolocator_android:** ^4.5.5

### Device Info

- **device_info_plus:** ^10.1.0
- **android_id:** ^0.4.0
- **uuid:** ^4.4.0

### Storage

- **shared_preferences:** ^2.2.2

### UI Components

- **flutter_svg:** ^2.0.9
- **scrollable_positioned_list:** ^0.3.8
- **blurrycontainer:** ^2.1.0
- **toastification:** ^2.1.0
- **after_layout:** ^1.2.0
- **url_launcher:** ^6.2.6

### Internationalization

- **intl:** ^0.20.2
- **flutter_localizations:** SDK

### Build Tools

- **flutter_native_splash:** ^2.3.9
- **flutter_launcher_icons:** ^0.13.1

### Logging

- **logging:** ^1.3.0

---

## Performance Optimizations

### 1. Selective Widget Rebuilds

Use `context.select` to rebuild only when specific state changes:

```dart
final isPlaying = context.select((PlayerCubit c) => c.state.isPlaying);
```

### 2. Image Caching

Use `cached_network_image` for station logos and podcast artwork.

### 3. Podcast Preloading

Background preload podcasts when station is selected for faster navigation.

### 4. Request Cancellation

Proper `CancelToken` usage in API calls to cancel obsolete requests.

### 5. ListView.builder

Lazy loading for long lists - only builds visible items.

---

## Security Considerations

### 1. API Authentication

- Device ID header for tracking
- API key via environment variable

### 2. Network Security

HTTP allowed for radio streams (some stations don't support HTTPS).

### 3. Secure Configuration

Secrets managed via `--dart-define-from-file` with `.env.json` (not committed to git).

---

## Testing Strategy

### Unit Tests

- Cubit business logic
- Model JSON parsing
- Utility functions

### Widget Tests

- UI rendering with different states
- User interactions
- Navigation

### Integration Tests

- End-to-end user flows
- Cross-feature interactions

---

## Related Documentation

- [BLoC Architecture](bloc-architecture.md)
- [Custom just_audio Fork](custom-just-audio-fork.md)
- [Build Versions](build-versions.md)
- [Android Publishing Guide](android-publishing-guide.md)
- [iOS Publishing Guide](ios-publishing-guide.md)

---

**Last Review:** December 2025