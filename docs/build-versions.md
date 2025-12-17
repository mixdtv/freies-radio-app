# Build Versions

This document lists all SDK and tool versions used for building the app.

## Flutter

| Component | Version | Source |
|-----------|---------|--------|
| Flutter SDK | 3.22.0 | `.fvmrc` |
| Dart SDK | 3.4.0 | Bundled with Flutter |
| FVM | Used for version management | `.fvmrc` |

## Android

| Component | Version | Source |
|-----------|---------|--------|
| Gradle | 8.6 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin (AGP) | 8.3.0 | `android/settings.gradle` |
| Kotlin | 1.9.10 | `android/build.gradle` |
| Java | 17 | `android/app/build.gradle` |
| compileSdkVersion | 34 | Flutter SDK default |
| minSdkVersion | 21 (Android 5.0) | Flutter SDK default |
| targetSdkVersion | 34 (Android 14) | Flutter SDK default |
| NDK | 23.1.7779620 | Flutter SDK default |

### Android Version Support

- **Minimum:** Android 5.0 (API 21)
- **Target:** Android 14 (API 34)
- **Compile:** API 34

## iOS

| Component | Version | Source |
|-----------|---------|--------|
| iOS Deployment Target | 12.0 | `ios/Podfile` |
| Swift | 5.0 | `ios/Runner.xcodeproj/project.pbxproj` |
| CocoaPods | Latest | System installed |

### iOS Version Support

- **Minimum:** iOS 12.0
- **Recommended Xcode:** 15.0+

## Key Audio Dependencies

| Package | Version | Notes |
|---------|---------|-------|
| just_audio | 0.9.36 | Custom fork from `github.com/IgoTs/just_audio` (branch: minor) |
| audio_service | 0.18.13 | Official package |
| audio_session | 0.1.18 | Transitive dependency |

## Updating Versions

### Flutter
```bash
# Update Flutter version in .fvmrc, then:
fvm install
fvm use
```

### Android Gradle Plugin
Update in `android/settings.gradle`:
```gradle
id "com.android.application" version "X.Y.Z" apply false
```

### Gradle
Update in `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-X.Y-all.zip
```

### Kotlin
Update in `android/build.gradle`:
```gradle
ext.kotlin_version = 'X.Y.Z'
```

### iOS Deployment Target
Update in `ios/Podfile`:
```ruby
platform :ios, 'X.Y'
```

## Compatibility Notes

- **Android 8 (API 26)**: Fully supported (minSdk is 21)
- **AGP 8.6/8.7 + just_audio 0.10.x**: Known issue with release builds - audio fails. See [GitHub Issue #1486](https://github.com/ryanheise/just_audio/issues/1486). Current setup uses just_audio 0.9.36 which is unaffected.
- **Live streams on Android**: Return null duration (unlike iOS which returns seekable window duration). The app handles this correctly.
