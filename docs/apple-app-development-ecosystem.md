# Apple App Development Ecosystem

A comprehensive guide to developing, distributing, and maintaining iOS/macOS applications.

---

## Table of Contents

1. [Overview](#overview)
2. [Development Tools](#development-tools)
3. [Apple Developer Program](#apple-developer-program)
4. [Code Signing & Provisioning](#code-signing--provisioning)
5. [App Store Connect](#app-store-connect)
6. [Release Process](#release-process)
7. [Testing & Distribution](#testing--distribution)
8. [Important But Often Unknown Facts](#important-but-often-unknown-facts)
9. [Advanced Knowledge](#advanced-knowledge)
10. [Flutter Integration](#flutter-integration)

---

## Overview

Apple's app development ecosystem is a tightly integrated system of tools, services, and processes that govern how applications are built, signed, distributed, and monetized on Apple platforms (iOS, iPadOS, macOS, watchOS, tvOS, visionOS).

### Key Principles

- **Closed ecosystem**: All apps must be signed by Apple-issued certificates
- **Sandboxing**: Apps run in isolated environments with limited system access
- **Review process**: Every app (and update) is reviewed before publication
- **Privacy-first**: Extensive privacy controls and transparency requirements

---

## Development Tools

### Xcode (Primary IDE)

The official IDE for Apple platform development.

| Component | Purpose |
|-----------|---------|
| **Xcode IDE** | Code editor, UI designer, debugging |
| **Interface Builder** | Visual UI design (Storyboards, XIBs) |
| **Instruments** | Performance profiling and analysis |
| **Simulator** | iOS/watchOS/tvOS device simulation |
| **Accessibility Inspector** | Accessibility testing |
| **Network Link Conditioner** | Network condition simulation |

**Key Xcode Features:**
- SwiftUI Previews (live UI preview)
- Source Control integration (Git)
- Test Navigator (unit/UI tests)
- Memory Graph Debugger
- View Hierarchy Debugger

### Command Line Tools

```bash
# Xcode Command Line Tools
xcode-select --install

# Key CLI tools:
xcodebuild      # Build projects from command line
xcrun           # Run Xcode developer tools
simctl          # Control iOS Simulator
altool          # App Store submission (deprecated, use xcrun notarytool)
codesign        # Code signing utility
security        # Keychain and certificate management
plutil          # Property list utility
actool          # Asset catalog compiler
```

### Package Managers

| Tool | Purpose |
|------|---------|
| **Swift Package Manager (SPM)** | Native Swift dependency management |
| **CocoaPods** | Ruby-based dependency manager (most popular) |
| **Carthage** | Decentralized dependency manager |

### Additional Development Tools

- **TestFlight**: Beta testing distribution
- **Transporter**: App binary upload tool
- **Apple Configurator**: Device management
- **Console.app**: Device log viewing
- **Keychain Access**: Certificate management
- **xcbeautify/xcpretty**: Build output formatting

---

## Apple Developer Program

### Membership Types

| Program | Cost | Capabilities |
|---------|------|--------------|
| **Individual** | $99/year | App Store distribution, TestFlight |
| **Organization** | $99/year | Same + team management |
| **Enterprise** | $299/year | Internal distribution only (no App Store) |
| **Free (Apple ID)** | $0 | Device testing only (7-day certificates) |

### Enrollment Requirements

**Individual:**
- Apple ID with two-factor authentication
- Valid payment method
- Legal age in jurisdiction

**Organization:**
- D-U-N-S Number (free from Dun & Bradstreet)
- Legal entity status
- Binding legal authority
- Organization's website domain

### Team Roles

| Role | Capabilities |
|------|--------------|
| **Account Holder** | Full access, legal agreements, payments |
| **Admin** | Manage team, certificates, apps |
| **App Manager** | Manage specific apps, TestFlight |
| **Developer** | Development certificates, provisioning |
| **Marketing** | App Store metadata only |
| **Finance** | Financial reports, tax forms |
| **Sales** | Sales reports only |

---

## Code Signing & Provisioning

### The Code Signing Chain

```
Apple Root CA
    └── Apple Worldwide Developer Relations CA
            └── Your Development/Distribution Certificate
                    └── Signed Application Binary
```

### Certificate Types

| Certificate | Purpose | Validity |
|-------------|---------|----------|
| **iOS Development** | Run on devices during development | 1 year |
| **iOS Distribution** | App Store & Ad Hoc distribution | 1 year |
| **Apple Push Services** | Push notifications | 1 year |
| **Pass Type ID** | Apple Wallet passes | 1 year |
| **Mac Development** | macOS development | 1 year |
| **Mac App Distribution** | Mac App Store | 1 year |
| **Developer ID Application** | macOS outside App Store | 5 years |
| **Developer ID Installer** | macOS pkg installers | 5 years |

### Provisioning Profiles

Provisioning profiles link:
- App ID (bundle identifier)
- Certificate(s)
- Device UDIDs (for development/ad hoc)
- Entitlements (capabilities)

**Profile Types:**

| Type | Devices | Certificate | Use Case |
|------|---------|-------------|----------|
| **Development** | Registered only | Development | Local testing |
| **Ad Hoc** | Registered only (100 max) | Distribution | Beta testing |
| **App Store** | Any | Distribution | App Store release |
| **Enterprise** | Any | Enterprise | Internal distribution |

### App IDs and Bundle Identifiers

```
# Explicit App ID (recommended)
com.company.appname

# Wildcard App ID (limited capabilities)
com.company.*
```

**Capabilities requiring Explicit App ID:**
- Push Notifications
- App Groups
- iCloud
- HealthKit
- HomeKit
- Sign in with Apple
- Associated Domains

### Entitlements

Entitlements are key-value pairs that grant specific capabilities:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>production</string>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:example.com</string>
    </array>
</dict>
</plist>
```

---

## App Store Connect

### Key Sections

| Section | Purpose |
|---------|---------|
| **My Apps** | App management, submissions |
| **TestFlight** | Beta testing |
| **Sales and Trends** | Revenue analytics |
| **Payments and Financial Reports** | Payment processing |
| **Users and Access** | Team management |
| **Agreements, Tax, and Banking** | Legal and financial setup |

### App Store Connect API

RESTful API for automation:

```bash
# Authentication via JWT with API Key
# Key obtained from App Store Connect > Users and Access > Keys

# Example: List apps
curl -H "Authorization: Bearer $JWT_TOKEN" \
  "https://api.appstoreconnect.apple.com/v1/apps"
```

**API Capabilities:**
- App metadata management
- Build management
- TestFlight management
- Sales reports
- User invitations
- Bundle ID management

---

## Release Process

### Step-by-Step App Store Submission

#### 1. Pre-Submission Preparation

```bash
# Ensure correct version and build number
# Version: User-facing (1.0.0)
# Build: Internal identifier (must increment)

# In Xcode: Target > General > Identity
```

**Required Assets:**
- App icon (1024x1024, no alpha)
- Screenshots for each device size
- App preview videos (optional)
- Privacy policy URL
- Support URL

#### 2. Archive and Upload

```bash
# Via Xcode
Product > Archive > Distribute App > App Store Connect

# Via Command Line
xcodebuild archive \
  -workspace App.xcworkspace \
  -scheme App \
  -archivePath build/App.xcarchive

xcodebuild -exportArchive \
  -archivePath build/App.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist

# Upload via xcrun
xcrun altool --upload-app \
  -f build/App.ipa \
  -t ios \
  -u "email@example.com" \
  -p "@keychain:AC_PASSWORD"
```

#### 3. App Store Connect Configuration

**App Information:**
- Name (30 characters max)
- Subtitle (30 characters max)
- Category (primary + secondary)
- Content Rights
- Age Rating questionnaire

**Pricing and Availability:**
- Price tier or custom price
- Territory availability
- Pre-order settings
- Volume Purchase Program

**App Privacy:**
- Privacy Nutrition Labels
- Data collection declarations
- Tracking disclosure

#### 4. Version Information

**Required for Each Version:**
- What's New text
- Screenshots per device
- Keywords (100 characters)
- Description (4000 characters)
- Promotional text (170 characters)
- Support URL
- Marketing URL (optional)

#### 5. Build Selection

- Select uploaded build
- Export compliance (encryption)
- IDFA usage declaration

#### 6. Submit for Review

**Review Guidelines Checklist:**
- No crashes or bugs
- Accurate metadata
- Privacy policy compliance
- In-app purchase compliance
- No placeholder content

### Review Process

| Stage | Duration | Description |
|-------|----------|-------------|
| **Waiting for Review** | Variable | In queue |
| **In Review** | 24-48 hours typical | Under examination |
| **Pending Developer Release** | Until released | Approved, awaiting release |
| **Ready for Sale** | - | Live on App Store |
| **Rejected** | - | Issues found, requires fixes |

**Common Rejection Reasons:**
1. Crashes and bugs
2. Broken links
3. Placeholder content
4. Incomplete information
5. Guideline 4.3 (spam/duplicate apps)
6. Privacy policy issues
7. Misleading metadata
8. In-app purchase issues

---

## Testing & Distribution

### TestFlight

**Internal Testing:**
- Up to 100 internal testers
- App Store Connect users only
- No review required
- Builds available immediately

**External Testing:**
- Up to 10,000 external testers
- Beta App Review required (first build)
- Public link option
- Feedback collection built-in

**TestFlight Limits:**
- 100 builds per app
- 90-day build expiration
- 100 internal testers
- 10,000 external testers

#### External Tester Experience

**What External Testers Receive:**

1. **Email Invitation** - An email from Apple with:
   - App name and icon
   - Developer name
   - "View in TestFlight" button
   - Redemption code (if using invite link)

2. **Or a Public Link** - A URL like `https://testflight.apple.com/join/AbCdEfGh` that anyone can use

**What External Testers Must Do:**

```
1. Install TestFlight app (free from App Store)
          ↓
2. Open invitation email or public link
          ↓
3. Tap "View in TestFlight" / "Accept"
          ↓
4. TestFlight app opens automatically
          ↓
5. Tap "Install" on the beta app
          ↓
6. App appears on home screen with orange dot indicator
```

**What They Get:**

| Feature | Description |
|---------|-------------|
| **Beta app** | Separate from App Store version (can have both installed) |
| **Orange dot badge** | Visual indicator it's a beta |
| **Automatic updates** | New builds install automatically (can disable) |
| **Feedback tool** | Screenshot → shake device → send feedback to developer |
| **Crash reports** | Automatically sent to developer |
| **Build expiration** | Each build expires after **90 days** |
| **What's New** | Developer's release notes for each build |

**Tester Requirements:**
- iOS 13.0+ (or equivalent for other platforms)
- Apple ID (free, no developer account needed)
- TestFlight app installed
- Accept Apple's TestFlight Terms of Service (one-time)

**Key Limitations for External Testers:**
- **90-day build expiration** - App stops working, must install new build
- **No real purchases** - In-app purchases use sandbox environment only
- **Beta App Review** - First build requires Apple review (24-48 hours)
- **Feedback only to developer** - No public reviews

### Ad Hoc Distribution

```bash
# Register devices (100 per device type per year)
# UDIDs collected from:
# - Xcode Devices window
# - Apple Configurator
# - Third-party services (Firebase App Distribution)

# Create Ad Hoc provisioning profile
# Build and distribute IPA
```

### Enterprise Distribution

For organizations with Enterprise Developer Program ($299/year):

```bash
# Enterprise distribution is for INTERNAL use only
# Distributing to public = program termination

# Create In-House provisioning profile
# Host IPA and manifest.plist on HTTPS server
# Install via: itms-services://?action=download-manifest&url=...
```

---

## Important But Often Unknown Facts

### Device Registration Limits

- **100 devices per device type per membership year**
- Device types: iPhone, iPad, Apple Watch, Apple TV, Mac
- Reset annually (membership renewal)
- Removed devices still count until reset
- TestFlight does NOT count against this limit

### Build Number Requirements

- Must increment for each upload
- Independent per platform (iOS vs macOS)
- Cannot reuse numbers even after rejection
- Version can stay same, build must increase

### Certificate Limits

| Certificate Type | Limit |
|------------------|-------|
| iOS Development | 2 per team |
| iOS Distribution | 3 per team |
| Apple Push Services | 2 per App ID |
| Pass Type ID | 1 per Pass Type |

### App Store Optimization Secrets

- **Keyword field**: 100 characters, comma-separated, no spaces after commas
- **App name + subtitle**: Indexed for search
- **Localization**: Each locale can have different keywords
- **Update frequency**: Affects ranking algorithm
- **Ratings reset**: Option to reset ratings with each version

### Review Tips

- **Expedited Review**: Request available for critical bugs
- **App Review Board**: Appeal option after rejection
- **Demo Account**: Provide if login required
- **Notes for Reviewer**: Explain non-obvious features
- **Attachments**: Can add documents, videos for reviewers

### Hidden Quotas and Limits

- **App name changes**: Limited (not officially documented)
- **Screenshot changes**: Immediate after first approval
- **Promotional text**: Can be changed without review
- **In-app purchase limit**: 10,000 per app
- **App group container**: 1GB default limit

### Provisioning Profile Pitfalls

- Profiles embedded at build time (not install time)
- Expired profile = app won't launch
- Push notification profile separate from app profile
- Automatic signing can cause CI/CD issues

### Binary Secrets

```bash
# Check entitlements in binary
codesign -d --entitlements - App.app

# Verify signature
codesign -vvv --deep --strict App.app

# Check if binary is encrypted (App Store)
otool -l App.app/App | grep -A4 LC_ENCRYPTION_INFO
```

---

## Advanced Knowledge

### Notarization (macOS)

Required for apps distributed outside Mac App Store:

```bash
# Submit for notarization
xcrun notarytool submit App.dmg \
  --apple-id "email@example.com" \
  --team-id "TEAM_ID" \
  --password "@keychain:AC_PASSWORD" \
  --wait

# Staple ticket to binary
xcrun stapler staple App.dmg

# Verify
xcrun stapler validate App.dmg
spctl -a -vvv -t install App.dmg
```

### Hardened Runtime (macOS)

Security feature required for notarization:

```xml
<!-- Entitlements for hardened runtime exceptions -->
<key>com.apple.security.cs.allow-jit</key>
<true/>
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
```

### Universal Links / Associated Domains

```json
// apple-app-site-association (hosted at domain root)
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.company.app",
      "paths": ["/path/*", "/other/path"]
    }]
  }
}
```

**Requirements:**
- HTTPS only
- Valid SSL certificate
- No redirects for AASA file
- Content-Type: application/json

### App Thinning

Apple automatically creates optimized variants:

| Technology | Description |
|------------|-------------|
| **Slicing** | Device-specific executables and resources |
| **Bitcode** | Intermediate representation (deprecated in Xcode 14) |
| **On-Demand Resources** | Downloaded content as needed |

```bash
# Check thinning report
# App Store Connect > Activity > Build > App Thinning Size Report
```

### Custom URL Schemes vs Universal Links

| Feature | URL Schemes | Universal Links |
|---------|-------------|-----------------|
| Setup | Info.plist only | Server + entitlements |
| Uniqueness | Not guaranteed | Unique per domain |
| Fallback | No | Opens website |
| User prompt | Yes | No |
| Security | Low | High |

### Background Modes

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>location</string>
    <string>voip</string>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
```

**Scrutinized Modes:**
- `location` - Requires justification string
- `voip` - Must be actual VoIP app
- `bluetooth-central/peripheral` - Needs explanation

### App Store Server Notifications

Server-to-server notifications for:
- Subscription renewals
- Refunds
- Grace period
- Billing issues

```json
{
  "signedPayload": "eyJhbGciOiJFUzI1NiIs..."
}
// JWT signed by Apple, verify with Apple's public key
```

### StoreKit 2 vs Original StoreKit

| Feature | Original | StoreKit 2 |
|---------|----------|------------|
| API | Completion handlers | async/await |
| Receipt | Local receipt file | JWS transactions |
| Verification | Server-side recommended | Built-in verification |
| Subscription status | Complex parsing | Simple API |

### Privacy Manifest (iOS 17+)

```xml
<!-- PrivacyInfo.xcprivacy -->
<key>NSPrivacyTracking</key>
<false/>
<key>NSPrivacyTrackingDomains</key>
<array/>
<key>NSPrivacyCollectedDataTypes</key>
<array>
    <dict>
        <key>NSPrivacyCollectedDataType</key>
        <string>NSPrivacyCollectedDataTypeName</string>
        <key>NSPrivacyCollectedDataTypeLinked</key>
        <false/>
        <key>NSPrivacyCollectedDataTypeTracking</key>
        <false/>
        <key>NSPrivacyCollectedDataTypePurposes</key>
        <array>
            <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        </array>
    </dict>
</array>
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string>
        </array>
    </dict>
</array>
```

### Xcode Cloud

Apple's CI/CD service:

```yaml
# ci_scripts/ci_post_clone.sh
#!/bin/bash
# Runs after source cloned
# Install dependencies, generate files

# ci_scripts/ci_pre_xcodebuild.sh
# Runs before build

# ci_scripts/ci_post_xcodebuild.sh
# Runs after successful build
```

**Environment Variables:**
- `CI_XCODE_CLOUD` = 1
- `CI_WORKSPACE`
- `CI_BUILD_NUMBER`
- `CI_COMMIT`
- `CI_BRANCH`

---

## Flutter Integration

### How Flutter Builds for iOS

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
├─────────────────────────────────────────────────────────┤
│  Dart Code (lib/)                                       │
│    ↓ (AOT Compilation)                                  │
│  App.framework (compiled Dart)                          │
├─────────────────────────────────────────────────────────┤
│  Flutter.framework (engine)                             │
│  - Skia (rendering)                                     │
│  - Dart VM (release: AOT, debug: JIT)                   │
│  - Platform channels                                    │
├─────────────────────────────────────────────────────────┤
│  Runner.app (native iOS shell)                          │
│  - AppDelegate                                          │
│  - Info.plist                                           │
│  - Native plugins                                       │
└─────────────────────────────────────────────────────────┘
```

### iOS Project Structure

```
ios/
├── Runner/
│   ├── AppDelegate.swift          # App entry point
│   ├── Info.plist                 # App configuration
│   ├── Assets.xcassets/           # App icons, images
│   ├── Base.lproj/
│   │   ├── LaunchScreen.storyboard
│   │   └── Main.storyboard
│   └── Runner-Bridging-Header.h   # Swift/ObjC bridging
├── Runner.xcodeproj/              # Xcode project
├── Runner.xcworkspace/            # Xcode workspace (use this)
├── Podfile                        # CocoaPods dependencies
├── Podfile.lock                   # Locked versions
└── Flutter/
    ├── Debug.xcconfig
    ├── Release.xcconfig
    └── AppFrameworkInfo.plist
```

### Flutter-Specific Configuration

#### Info.plist Additions

```xml
<!-- Flutter requires these -->
<key>io.flutter.embedded_views_preview</key>
<true/>

<!-- For background audio (just_audio, audio_service) -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<!-- Privacy descriptions -->
<key>NSMicrophoneUsageDescription</key>
<string>Required for voice recording</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Required for location-based features</string>
```

#### Podfile Configuration

```ruby
platform :ios, '12.0'  # Minimum iOS version

# Recommended Flutter settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      # For Apple Silicon Macs
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

### Building & Releasing Flutter iOS Apps

```bash
# Development build
flutter run -d <device_id>

# Release build (IPA)
flutter build ipa

# Build with specific configuration
flutter build ipa \
  --release \
  --export-options-plist=ios/ExportOptions.plist

# For App Store submission
flutter build ipa --release

# Output location
# build/ios/ipa/App.ipa
```

#### ExportOptions.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>  <!-- or: ad-hoc, development, enterprise -->
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>  <!-- Bitcode deprecated -->
</dict>
</plist>
```

### Platform Channels

Native iOS code integration:

```dart
// Dart side
const platform = MethodChannel('com.example.app/native');

Future<String> getNativeValue() async {
  final result = await platform.invokeMethod('getValue');
  return result;
}
```

```swift
// Swift side (AppDelegate.swift)
let controller = window?.rootViewController as! FlutterViewController
let channel = FlutterMethodChannel(
    name: "com.example.app/native",
    binaryMessenger: controller.binaryMessenger
)

channel.setMethodCallHandler { call, result in
    if call.method == "getValue" {
        result("Native value")
    } else {
        result(FlutterMethodNotImplemented)
    }
}
```

### Common Flutter iOS Issues

#### 1. Signing Issues

```bash
# Automatic signing (development)
# Xcode > Runner > Signing & Capabilities > Team

# Manual signing (CI/CD)
# Set in ios/Runner.xcodeproj/project.pbxproj or via Xcode
```

#### 2. CocoaPods Issues

```bash
# Clean and reinstall pods
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Caches/CocoaPods
pod install --repo-update
```

#### 3. Archive Fails

```bash
# Clean build folder
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf ios/.symlinks
flutter pub get
cd ios && pod install && cd ..
flutter build ipa
```

#### 4. Module Not Found Errors

```ruby
# In Podfile, add use_modular_headers!
use_modular_headers!

# Or for specific pods
pod 'SomePod', :modular_headers => true
```

### Flavors / Build Configurations

```bash
# Create flavors for different environments
flutter build ipa --flavor production --target lib/main_production.dart
flutter build ipa --flavor staging --target lib/main_staging.dart
```

Xcode scheme and configuration setup required:
1. Duplicate configurations (Debug, Release, Profile) per flavor
2. Create schemes per flavor
3. Set bundle ID per configuration

### CI/CD Integration

#### GitHub Actions Example

```yaml
name: iOS Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Install CocoaPods
        run: cd ios && pod install

      - name: Import certificates
        env:
          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Create keychain
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain

          # Import certificate
          echo "${{ secrets.CERTIFICATE_P12 }}" | base64 --decode > certificate.p12
          security import certificate.p12 -k build.keychain -P "$P12_PASSWORD" -T /usr/bin/codesign

          # Allow codesign access
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain

      - name: Install provisioning profile
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.PROVISIONING_PROFILE }}" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

      - name: Build IPA
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

      - name: Upload to App Store Connect
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_API_KEY }}
        run: |
          xcrun altool --upload-app \
            -f build/ios/ipa/*.ipa \
            -t ios \
            --apiKey $API_KEY_ID \
            --apiIssuer $API_ISSUER_ID
```

### Flutter-Specific App Store Guidelines

1. **Performance**: Flutter apps must meet same performance standards
2. **Native Feel**: UI should feel native (Flutter does this well)
3. **Minimum Functionality**: WebView-only apps may be rejected
4. **Privacy**: Must declare all data collection (including analytics)
5. **Binary Size**: Flutter adds ~5-10MB to app size (acceptable)

### Debugging iOS-Specific Issues

```bash
# View device logs
flutter logs

# Attach to running app
flutter attach -d <device_id>

# Open Xcode for native debugging
open ios/Runner.xcworkspace
```

### Performance Optimization for iOS

```dart
// Use release mode for testing performance
// flutter run --release

// Enable Impeller (new rendering engine)
// In Info.plist:
// <key>FLTEnableImpeller</key>
// <true/>
```

---

## Quick Reference

### Essential Commands

```bash
# Build
flutter build ipa --release

# List devices
flutter devices

# Run on specific device
flutter run -d DEVICE_ID

# Clean build
flutter clean && flutter pub get

# Update iOS pods
cd ios && pod update && cd ..

# Open Xcode
open ios/Runner.xcworkspace
```

### Key Files Checklist

- [ ] `ios/Runner/Info.plist` - App configuration
- [ ] `ios/Runner/Assets.xcassets/AppIcon.appiconset` - App icons
- [ ] `ios/Runner.xcodeproj/project.pbxproj` - Build settings
- [ ] `ios/Podfile` - Native dependencies
- [ ] `ios/ExportOptions.plist` - Archive export settings

### Submission Checklist

- [ ] Bundle ID registered in Developer Portal
- [ ] App ID has required capabilities
- [ ] Provisioning profile created and valid
- [ ] App icon (1024x1024, no alpha channel)
- [ ] Screenshots for all device sizes
- [ ] Privacy policy URL
- [ ] App Store Connect app record created
- [ ] Export compliance answered
- [ ] Privacy nutrition labels completed
- [ ] TestFlight testing completed
- [ ] Version and build number incremented

---

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Flutter iOS Documentation](https://docs.flutter.dev/deployment/ios)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [WWDC Videos](https://developer.apple.com/videos/)