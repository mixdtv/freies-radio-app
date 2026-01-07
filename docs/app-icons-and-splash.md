# App Icons and Splash Screen Guide

This document describes how to generate and update app icons and splash screens for the Freies Radio app.

## Source Files

All source logos are located in:
```
/workspace/radiozeit/mabb-app-planning/logos/
```

| File | Usage |
|------|-------|
| `fr1_eckig.png` | App icon (square, fills edge-to-edge) |
| `FINAL_fr1_rund.png` | Splash screen, in-app logo (has rounded corners) |

## App Icons

### Important: iOS Alpha Channel Requirement

**Apple App Store rejects icons with alpha channels (transparency).** The iOS app icon must be fully opaque with no alpha channel. This is enforced during App Store Connect upload.

### Generate App Icons

The app icons should fill the entire icon area without padding. iOS and Android apply their own masks (rounded corners, circles, etc.).

```bash
# Trim whitespace, resize to 1024x1024, and remove alpha channel
magick /path/to/mabb-app-planning/logos/fr1_eckig.png \
  -trim +repage -resize 1024x1024! \
  -background white -alpha remove -alpha off \
  assets/images/app_icon_ios.png

magick /path/to/mabb-app-planning/logos/fr1_eckig.png \
  -trim +repage -resize 1024x1024! \
  assets/images/app_icon_android.png

# Generate all icon sizes
.fvm/flutter_sdk/bin/dart run flutter_launcher_icons

# IMPORTANT: Remove alpha from generated iOS icons
for f in ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png; do
  magick "$f" -background white -alpha remove -alpha off "$f"
done
```

### Verify No Alpha Channel

```bash
# Check source image
sips -g hasAlpha assets/images/app_icon_ios.png
# Should show: hasAlpha: no

# Check all generated iOS icons (should return nothing)
find ios -name "*.png" -path "*AppIcon*" -exec sips -g hasAlpha {} \; | grep "hasAlpha: yes"
```

### Configuration (pubspec.yaml)

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path_android: "assets/images/app_icon_android.png"
  image_path_ios: "assets/images/app_icon_ios.png"
  adaptive_icon_foreground: "assets/images/app_icon_android.png"
  remove_alpha_ios: true
```

## Splash Screens

### iOS Native Splash

The iOS splash uses a centered image on a dark background. The image size determines how large the logo appears on screen.

```bash
# Create iOS splash (500x500 logo on dark background)
magick assets/images/logo_freies_radio.png -resize 500x500 \
  -background '#0E0E0F' -gravity center -extent 500x500 \
  assets/images/splash_app_ios.png
```

### Android Splash (Pre-Android 12)

```bash
# Create Android splash (300x300 logo on dark background)
magick assets/images/logo_freies_radio.png -resize 300x300 \
  -background '#0E0E0F' -gravity center -extent 300x300 \
  assets/images/splash_app.png
```

### Android 12+ Splash

Android 12+ clips the splash icon to a circle. To prevent clipping, the logo must fit within the safe circle area.

```bash
# Create Android 12 splash (550x550 logo centered on 1152x1152 canvas)
# The logo must fit inside a 768px diameter circle
magick -size 1152x1152 xc:'#0E0E0F' \
  \( assets/images/logo_freies_radio.png -resize 550x550 \) \
  -gravity center -composite \
  assets/images/android12splash.png
```

### Generate Splash Screens

```bash
.fvm/flutter_sdk/bin/dart run flutter_native_splash:create
```

### Configuration (flutter_native_splash.yaml)

Key settings:
```yaml
flutter_native_splash:
  color: "#0E0E0F"
  image: assets/images/splash_app.png

  color_dark: "#0E0E0F"
  image_dark: assets/images/splash_app_ios.png

  android_12:
    image: assets/images/android12splash.png
    color: "#0E0E0F"
    icon_background_color: "#0E0E0F"

  image_ios: assets/images/splash_app_ios.png
  color_ios: "#0E0E0F"
```

## In-App Logo Usage

| Location | File | Size |
|----------|------|------|
| Welcome/Location page | `logo_freies_radio.png` | 140px |
| App drawer/menu | `logo_freies_radio.png` | 200px |

### Copy logo to assets

```bash
cp /path/to/mabb-app-planning/logos/FINAL_fr1_rund.png assets/images/logo_freies_radio.png
```

## Color Reference

| Usage | Color |
|-------|-------|
| Dark background | `#0E0E0F` |
| Light background | `#EAEDF0` |

## Troubleshooting

### iOS app icon has alpha channel (App Store rejection)

**Error:** "Invalid large app icon. The large app icon in the asset catalog in 'Runner.app' can't be transparent or contain an alpha channel."

**Cause:** `flutter_launcher_icons` may not properly remove alpha from all icons, especially if there are old/cached icon files in the asset catalog.

**Fix:** See "Generate App Icons" section above - always run the alpha removal step after generating icons.

### iOS shows two splash screens
- Ensure native splash and Flutter welcome screen use similar logo sizes
- Clean build: `flutter clean && rm -rf ios/Pods ios/.symlinks`

### Android 12 clips the logo
- Ensure logo fits within 768px circle on 1152x1152 canvas
- Use `icon_background_color` matching `color` to hide the circle

### Cached splash on iOS Simulator
- Simulator menu → Device → Erase All Content and Settings
