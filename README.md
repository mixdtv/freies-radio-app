# Freies Radio

Die Plattform für unabhängige Radios - A Flutter-based radio streaming application for iOS and Android.

## Setup

**Before running the app, create a `.env.json` file in the project root:**

```json
{
  "API_KEY": "your-api-key",
  "API_URL": "http://localhost:5001/",
  "EPG_URL": "http://localhost:5004/radio/epg/",
  "USE_SOURCE_STREAM": true
}
```

Then run with:
```bash
flutter run --dart-define-from-file=.env.json
```

> **Note:** `.env.json` is gitignored. Copy from `.env.example.json` and ask a team member for the API key.

## Project Information

Flutter 3.22.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5dcb86f68f (1 year, 6 months ago) • 2024-05-09 07:39:20 -0500
Engine • revision f6344b75dc
Tools • Dart 3.4.0 • DevTools 2.34.3

## Features

- Live radio streaming
- Location-based radio discovery
- Multi-language support (English, German)
- Audio playback with background service
- Radio transcripts
- Station search and favorites

## Prerequisites

- Flutter SDK 3.22.0 (managed via FVM)
- Dart SDK >=3.2.0 <4.0.0
- For iOS: Xcode 15.0+ (macOS required)
- For Android: Android SDK with API level 21+

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Localization Files

Localization files are generated automatically during `flutter pub get`, but you can manually generate them:

```bash
flutter gen-l10n
```

### 3. Run the App

```bash
# Run on connected device/emulator
flutter run --dart-define-from-file=.env.json

# Run on specific platform
flutter run -d ios --dart-define-from-file=.env.json
flutter run -d android --dart-define-from-file=.env.json
```

## Configuration

The app uses a `.env.json` file for configuration (see [Setup](#setup)). All config options:

| Key | Description | Default |
|-----|-------------|---------|
| `API_KEY` | API authentication key | *required* |
| `API_URL` | Main API base URL | *required* |
| `EPG_URL` | Electronic Program Guide URL | `http://localhost:5004/radio/epg/` |
| `USE_SOURCE_STREAM` | Use source stream (true) or HLS (false) | `true` |

### IDE Configuration

**VS Code:** Add to `.vscode/launch.json`:
```json
{
  "configurations": [
    {
      "name": "Flutter",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define-from-file=.env.json"]
    }
  ]
}
```

**Android Studio/IntelliJ:**
- Run → Edit Configurations
- Additional run args: `--dart-define-from-file=.env.json`

## Project Structure

```
lib/
├── app/                    # App-level UI (navigation, drawer, styling)
├── config/                 # App configuration
├── data/                   # Data layer (API, models, repositories)
├── features/               # Feature modules
│   ├── auth/               # Authentication and splash
│   ├── location/           # Location services
│   ├── player/             # Audio player
│   ├── podcast/            # Podcast playback
│   ├── radio_about/        # Radio station details
│   ├── radio_list/         # Radio station lists
│   ├── timeline/           # Timeline feature
│   ├── transcript/         # Radio transcripts
│   └── visual/             # Visual features
├── l10n/                   # Localization files (ARB files)
├── utils/                  # Utility functions and helpers
└── main.dart               # App entry point
```

## Architecture

This project follows the **BLoC (Business Logic Component)** pattern for state management. See [docs/bloc-architecture.md](docs/bloc-architecture.md) for details.

## Key Dependencies

- **State Management:** `flutter_bloc` ^8.1.3
- **Navigation:** `go_router` ^13.0.1
- **Audio Playback:** Custom fork of `just_audio` (see [docs/custom-just-audio-fork.md](docs/custom-just-audio-fork.md))
- **Background Audio:** `audio_service` ^0.18.13
- **Localization:** Built-in Flutter localization (`flutter_localizations`)
- **Networking:** `dio` ^5.4.0
- **Location Services:** `geolocator` ^12.0.0

## Localization

The app supports multiple languages:
- English (en)
- German (de)

Translation files are located in `lib/l10n/`:
- `app_en.arb` - English (template)
- `app_de.arb` - German

Generated localization files are automatically created in `lib/l10n/` and excluded from version control.

## Building

### iOS

```bash
flutter build ios --release --dart-define-from-file=.env.json
```

### Android

**Setup signing credentials:**

1. Copy `android/local.properties.example` to `android/local.properties`
2. Add your signing credentials (ask a team member):
   ```properties
   android.storePassword=your-store-password
   android.keyPassword=your-key-password
   ```

**Build:**
```bash
flutter build apk --release --dart-define-from-file=.env.json
# or
flutter build appbundle --release --dart-define-from-file=.env.json
```

**CI/CD:** Instead of `local.properties`, set environment variables:
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`

## Documentation

Additional documentation can be found in the `docs/` folder:
- [Build Versions](docs/build-versions.md) - SDK and tool versions for Android/iOS builds
- [BLoC Architecture](docs/bloc-architecture.md)
- [Custom Just Audio Fork](docs/custom-just-audio-fork.md)
- [Plugins Overview](docs/plugins-overview.md)

## Environment Setup

### Flutter PATH Configuration (macOS)

Add Flutter to your PATH by adding this to your `~/.zshrc`:

```bash
export PATH="$PATH:/Applications/flutter-sdk/flutter/bin"
```

Then reload your shell:

```bash
source ~/.zshrc
```

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

Third-party dependencies are listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).