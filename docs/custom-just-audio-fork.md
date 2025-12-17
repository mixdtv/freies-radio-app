# Custom just_audio Fork Documentation

## Overview

This project uses a custom fork of the `just_audio` package maintained by Igor Tsaryk (IgoTs).

- **Repository**: https://github.com/IgoTs/just_audio
- **Branch**: `minor`
- **Upstream**: https://github.com/ryanheise/just_audio

## About the Maintainer

**Igor Tsaryk (IgoTs)** is a developer active in the Flutter/Dart ecosystem with a focus on Android media playback and audio libraries.

- **GitHub**: https://github.com/IgoTs
- **User ID**: 6304011

## Custom Modifications

The fork contains 3 commits that differ from the upstream repository (all dated February 13, 2024):

1. **"add update progress timer"** (bcf4943) - Initially added timer-based progress updates
2. **"change progress calc"** (747adac) - Modified progress calculation logic
3. **"Revert 'add update progress timer'"** (2874d99) - Reverted the first commit

### Net Effect

After the revert, only **one meaningful change** remains in the codebase.

## The Critical Change

**File**: `just_audio/lib/just_audio.dart` (lines 575-580)

### Original Code (upstream)
```dart
return playbackEvent.duration == null || result <= playbackEvent.duration!
    ? result
    : playbackEvent.duration!;
```

### Modified Code (IgoTs fork)
```dart
return result;
```

## Why This Fork is Important

This modification **removes boundary checking** that previously capped the progress value to the audio duration.

### Reasons for Using This Fork

1. **Live Streaming Support**: The original boundary check can cause issues with streaming radio, which has no fixed duration
2. **Dynamic Duration Handling**: For live streams or radio stations, the duration is often `null` or constantly changing
3. **Unrestricted Progress Tracking**: The simplified version allows progress calculation to return raw values without artificial constraints

### Relevance to This App

Since this is a **radio streaming application**, this modification likely fixes a bug or improves behavior specific to live audio streaming scenarios where duration-based progress capping doesn't make sense.

In live radio streams:
- Duration is typically `null` or undefined
- Progress tracking needs to work without duration bounds
- The original capping logic could interfere with proper playback state reporting

## Configuration

This fork is configured in `pubspec.yaml`:

```yaml
just_audio:
  git:
    url: https://github.com/IgoTs/just_audio
    ref: minor
    path: just_audio
```

## Upgrade Recommendation

### Current State

The IgoTs fork is based on **just_audio 0.9.36**, which is 10 versions behind the latest 0.9.x release.

### Recommended Upgrade: 0.9.46

Consider upgrading to **just_audio 0.9.46** (either by updating the fork or switching to upstream with the progress calc patch applied). Benefits include:

| Version | Improvement |
|---------|-------------|
| 0.9.40 | Fix JDK 21 compile error |
| 0.9.41 | Fix `stop()` to cause `play()` to return on iOS |
| 0.9.42 | Fix iOS/macOS memory leak on disposal |
| 0.9.42 | Update Gradle to 8.5.0 |
| 0.9.43 | Fix null pointer exceptions on iOS/macOS during load |
| 0.9.43 | Migrate to media3 ExoPlayer 1.4.1 on Android |
| 0.9.44 | Add support for SwiftPM |

### Not Recommended: 0.10.x

**Do not upgrade to just_audio 0.10.x** due to:

1. **AGP Compatibility Issue**: There is a [known bug (#1486)](https://github.com/ryanheise/just_audio/issues/1486) where audio playback fails in release builds when using Android Gradle Plugin (AGP) 8.6 or 8.7. While the project currently uses AGP 8.3.0, this limits future AGP upgrades.

2. **Dart SDK Requirement**: Version 0.10.x requires Dart SDK 3.6+, while the project uses Dart 3.4.0 (bundled with Flutter 3.22.0). Upgrading would require a Flutter version bump.

### Upgrade Path Options

1. **Update the IgoTs fork** to rebase on 0.9.46 and reapply the progress calculation change
2. **Fork upstream 0.9.46** ourselves and apply the single-line progress calc fix
3. **Submit a PR to upstream** with the progress calculation fix and switch to official package if merged

## Maintenance Considerations

- This is a custom fork, so updates from the upstream `just_audio` package won't be automatically received
- Monitor both repositories for important updates:
  - Upstream: https://github.com/ryanheise/just_audio
  - Our fork: https://github.com/IgoTs/just_audio
- Consider submitting the progress calculation fix as a PR to upstream if it proves valuable
- If the fork becomes unmaintained, we may need to either:
  - Fork it ourselves and maintain the changes
  - Find an alternative solution
  - Migrate back to upstream if the issue is resolved there

## Last Updated

2025-12-03