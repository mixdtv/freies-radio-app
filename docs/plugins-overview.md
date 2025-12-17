# Plugins & Dependencies Overview

## Project Information

**Version:** 1.0.0+2
**Dart SDK:** >=3.2.0 <4.0.0

---

## Dependencies by Category

### 🎵 Audio & Media Playback

#### just_audio (Custom Fork)
- **Version:** Custom fork from IgoTs/just_audio (minor branch)
- **Source:** https://github.com/IgoTs/just_audio
- **Purpose:** Primary audio player for streaming radio stations
- **Why Custom Fork:** Removes progress boundary checking that interferes with live streaming
- **iOS Minimum:** 13.0 (via RevenueCat)
- **Documentation:** See `docs/custom-just-audio-fork.md`

#### audio_service ^0.18.13
- **Purpose:** Background audio playback and media notification controls
- **Features:**
  - Keep audio playing when app is in background
  - Lock screen media controls
  - Notification player controls
  - Integration with system media session
- **iOS Minimum:** 8.0

### 🎨 UI & Visual Components

#### cupertino_icons ^1.0.2
- **Purpose:** iOS-style icons from the Cupertino design library
- **Use Case:** Consistent iOS look and feel

#### flutter_svg ^2.0.9
- **Purpose:** Render SVG (Scalable Vector Graphics) images
- **Use Case:** Vector icons and graphics that scale without quality loss

#### cached_network_image ^3.3.1
- **Purpose:** Load and cache images from URLs
- **Features:**
  - Automatic caching (reduces bandwidth)
  - Placeholder and error widgets
  - Smooth loading animations
- **Use Case:** Radio station logos, album art

#### blurrycontainer ^2.1.0
- **Purpose:** Create glassmorphism/frosted glass UI effects
- **Use Case:** Modern, aesthetic blur effects in UI

#### toastification ^2.1.0
- **Purpose:** Display toast notifications to users
- **Use Case:** Success messages, errors, informational alerts

### 🧭 Navigation & Routing

#### go_router ^13.0.1
- **Purpose:** Declarative routing solution for Flutter
- **Features:**
  - URL-based navigation
  - Deep linking support
  - Type-safe routing
  - Nested navigation
- **Use Case:** Navigate between radio lists, player, settings pages

### 🏗️ State Management & Architecture

#### bloc ^8.1.2
- **Purpose:** Core BLoC (Business Logic Component) pattern implementation
- **Features:**
  - Predictable state management
  - Separation of business logic from UI
  - Event-driven architecture

#### flutter_bloc ^8.1.3
- **Purpose:** Flutter widgets for BLoC pattern
- **Features:**
  - BlocProvider, BlocBuilder, BlocListener widgets
  - Integration between BLoC and Flutter UI

#### bloc_presentation ^1.0.0
- **Purpose:** Handle one-time presentation events (like navigation, dialogs)
- **Use Case:** Navigate after successful action, show error dialogs

### 🌐 Networking & HTTP

#### dio ^5.4.0
- **Purpose:** Powerful HTTP client for Dart
- **Features:**
  - Interceptors (logging, auth)
  - Request cancellation
  - File download/upload
  - Global configuration
- **Use Case:** API calls to backend for station data

### 💾 Data Persistence

#### shared_preferences ^2.2.2
- **Purpose:** Store simple key-value data persistently
- **Use Case:** User settings, favorites, last played station, preferences

### 📍 Location Services

#### geolocator ^12.0.0
- **Purpose:** Platform-independent geolocation/location services
- **Features:**
  - Get current device location
  - Location permissions handling
  - Distance calculations
- **Use Case:** Find local/nearby radio stations

#### geolocator_android ^4.5.5
- **Purpose:** Android-specific implementation for geolocator
- **Reason:** Explicit dependency for Android location features

### 🔧 Utilities

#### intl ^0.20.2
- **Purpose:** Internationalization and localization
- **Features:**
  - Date/time formatting
  - Number formatting
  - Message translation
- **Use Case:** Format dates, numbers according to user locale

#### uuid ^4.4.0
- **Purpose:** Generate RFC4122 UUIDs (Universally Unique Identifiers)
- **Use Case:** Generate unique IDs for analytics, session tracking

#### after_layout ^1.2.0
- **Purpose:** Execute callback after widget's first layout
- **Use Case:** Perform actions after UI is rendered (e.g., show dialogs)

#### scrollable_positioned_list ^0.3.8
- **Purpose:** Scrollable list that can jump to specific positions
- **Features:**
  - Jump to index
  - Animated scrolling
  - Track visible items
- **Use Case:** Radio station lists with ability to jump to specific station

#### url_launcher ^6.2.6
- **Purpose:** Launch URLs in external applications
- **Features:**
  - Open web URLs in browser
  - Make phone calls
  - Send emails
  - Open maps
- **Use Case:** Open radio station websites, social media links

### 📱 Device Information

#### device_info_plus ^10.1.0
- **Purpose:** Get device information (model, OS version, etc.)
- **Use Case:** Analytics, debugging, device-specific behavior

#### android_id ^0.4.0
- **Purpose:** Get unique Android device ID
- **Use Case:** Device identification for analytics or user tracking


### 🌍 Localization

#### flutter_localizations (SDK)
- **Purpose:** Official Flutter localization support
- **Features:**
  - Support for multiple languages
  - Locale-specific formatting
  - RTL support
- **Use Case:** Multi-language support (German, English based on l10n files)

---

## Dev Dependencies

### flutter_test (SDK)
- **Purpose:** Flutter testing framework
- **Use Case:** Unit, widget, and integration tests

### flutter_native_splash ^2.3.9
- **Purpose:** Generate native splash screens for iOS and Android
- **Use Case:** Branded launch screen while app loads

### flutter_lints ^2.0.0
- **Purpose:** Recommended linting rules for Flutter projects
- **Use Case:** Code quality, consistent code style

---

## Dependency Overrides

### win32: ^5.5.0
- **Purpose:** Windows FFI bindings
- **Reason for Override:** Resolve version conflicts in dependency tree

---

## Critical Dependencies Summary

### Must-Have for Core Functionality

1. **just_audio** - Audio streaming (custom fork required)
2. **audio_service** - Background playback
3. **dio** - API communication
4. **bloc/flutter_bloc** - State management
5. **go_router** - Navigation
6. **geolocator** - Location-based stations


### User Experience Enhancements

1. **cached_network_image** - Smooth image loading
2. **toastification** - User feedback
3. **blurrycontainer** - Modern UI effects
4. **flutter_localizations** - Multi-language support

---

## Platform Requirements

### iOS
- **Minimum Version:** 12.0
- **Key iOS Features:**
  - Background audio playback
  - Media controls on lock screen
  - Location services

### Android
- **Minimum SDK:** API 21 (Android 5.0)
- **Key Android Features:**
  - Background audio service
  - Notification controls
  - Location services

---

## Potential Issues & Considerations

### 1. Custom Fork Maintenance
- **Risk:** IgoTs/just_audio fork may become outdated
- **Mitigation:** Monitor upstream just_audio for updates, consider maintaining own fork

### 2. iOS 12 Minimum Requirement
- **Status:** App supports iOS 12.0+
- **Impact:** Broad device compatibility

### 3. Location Permissions
- **Consideration:** Requires careful permission handling and user explanation
- **Config:** Already configured with `BYPASS_PERMISSION_LOCATION_ALWAYS=1` in Podfile

### 4. Background Audio Permissions
- **iOS:** Requires background modes capability
- **Android:** Requires foreground service permission

---

## Assets & Resources

### Custom Fonts
- **DMMono** (Light 300, Regular 400, Medium 500)
- **Inter** (Thin 100 - Black 900, full weight range)

### Asset Directories
- `assets/fonts/` - Custom font files
- `assets/icons/` - App icons and UI icons
- `assets/images/` - Images and graphics

---

## Package Count

- **Production Dependencies:** 20
- **Dev Dependencies:** 4
- **SDK Dependencies:** 2 (flutter, flutter_localizations)
- **Custom/Fork Dependencies:** 1 (just_audio)

---

## Version Status & Security

### 📊 Dependency Update Status

| Package | Your Version | Latest Version | Status | Priority |
|---------|--------------|----------------|--------|----------|
| **dio** | ^5.4.0 | 5.9.0 | ⚠️ Minor outdated | Medium |
| **go_router** | ^13.0.1 | 17.2.4 | 🔴 Major outdated | High |
| **bloc** | ^8.1.2 | 9.1.0 | 🔴 Major outdated | High |
| **flutter_bloc** | ^8.1.3 | 9.1.1 | 🔴 Major outdated | High |
| **geolocator** | ^12.0.0 | 13.0.2 | 🔴 Major outdated | Medium |
| **cached_network_image** | ^3.3.1 | 3.4.1 | ⚠️ Minor outdated | Low |
| **audio_service** | ^0.18.13 | 0.18.18 | ⚠️ Minor outdated | Low |
| **shared_preferences** | ^2.2.2 | 2.5.3 | ⚠️ Minor outdated | Low |
| **url_launcher** | ^6.2.6 | 6.3.2 | ⚠️ Minor outdated | Low |
| **intl** | ^0.20.2 | 0.20.2 | ✅ Up to date | - |
| **just_audio** | Custom fork | N/A | ⚠️ Custom | Monitor |

**Legend:**
- ✅ Up to date (within same minor version)
- ⚠️ Minor outdated (patch/minor versions behind)
- 🔴 Major outdated (major version behind)

### 🔒 Known Security Vulnerabilities

#### ⚠️ dio - CVE-2021-31402 (PATCHED)

**Severity:** High (CVSS 7.5)
**Status:** ✅ **Not Affected** (You're using 5.4.0, vulnerability fixed in 5.0.0)

**Details:**
- **Vulnerability:** CRLF injection if attacker controls HTTP method string
- **Affected Versions:** < 5.0.0
- **Fixed In:** 5.0.0+ (commit 927f79e)
- **Your Status:** SAFE - Using 5.4.0

**Impact if exploited:**
- HTTP response splitting attacks
- Header injection
- Potential XSS via response manipulation

**Action Required:** None - You're already on a safe version. Consider updating to 5.9.0 for bug fixes and improvements.

#### ✅ All Other Packages

**Status:** No known CVEs or security vulnerabilities found for:
- purchases_flutter (9.9.6)
- flutter_bloc / bloc
- geolocator
- All other dependencies

**Note:** Regular security audits don't show active CVEs. However, staying updated is still recommended for bug fixes and improvements.

### 📈 Recommended Updates

#### High Priority (Breaking Changes Expected)

**1. State Management (bloc/flutter_bloc): 8.x → 9.x**
- **Current:** bloc ^8.1.2, flutter_bloc ^8.1.3
- **Latest:** bloc 9.1.0, flutter_bloc 9.1.1
- **Why Update:**
  - Performance improvements
  - Better debugging tools
  - Bug fixes from 31 days ago
- **Migration Required:** Yes (v9.0 had breaking changes)
- **Effort:** Medium (state management changes may require code updates)

**2. Navigation (go_router): 13.x → 17.x**
- **Current:** ^13.0.1
- **Latest:** 17.0.0 (published 8 days ago)
- **Why Update:**
  - 4 major versions behind
  - New navigation features
  - Bug fixes and performance improvements
  - Better type safety
- **Migration Required:** Likely (multiple major versions)
- **Effort:** High (routing changes may affect entire app navigation)


#### Medium Priority

**3. Location (geolocator): 12.x → 13.x**
- **Current:** ^12.0.0
- **Latest:** 13.0.2
- **Migration Required:** Possibly
- **Effort:** Medium

**4. HTTP Client (dio): 5.4.0 → 5.9.0**
- **Current:** ^5.4.0
- **Latest:** 5.9.0 (published 3 months ago)
- **Migration Required:** No (same major version)
- **Effort:** Low (should be drop-in replacement)

#### Low Priority (Minor Updates)

- **cached_network_image**: 3.3.1 → 3.4.1 (minor improvements)
- **audio_service**: 0.18.13 → 0.18.18 (bug fixes)
- **shared_preferences**: 2.2.2 → 2.5.3 (improvements)
- **url_launcher**: 6.2.6 → 6.3.2 (minor updates)

### ⚠️ Update Considerations

#### Before Updating

1. **Review Changelogs**
   - bloc 9.0: https://pub.dev/packages/bloc/changelog
   - go_router 17.0: https://pub.dev/packages/go_router/changelog

2. **Test Thoroughly**
   - State management changes (bloc) affect entire app
   - Navigation changes (go_router) affect all routing

3. **Consider Staged Rollout**
   - Update one major package at a time
   - Test extensively between updates
   - Start with less critical packages

#### Breaking Change Risk

| Package | Risk Level | Testing Required |
|---------|------------|------------------|
| go_router | 🔴 High | Extensive - test all routes |
| bloc/flutter_bloc | 🟡 Medium | Moderate - test state flows |
| geolocator | 🟡 Medium | Moderate - test location features |
| dio | 🟢 Low | Light - test API calls |

### 🛡️ Security Best Practices

1. **Keep Dependencies Updated**
   - Review updates quarterly
   - Subscribe to security advisories
   - Monitor package health on pub.dev

2. **Monitor Custom Fork (just_audio)**
   - Check IgoTs/just_audio for updates: https://github.com/IgoTs/just_audio
   - Compare with upstream ryanheise/just_audio
   - Consider maintaining own fork if IgoTs becomes inactive

3. **Security Resources**
   - Dart Security Advisories: https://dart.dev/tools/pub/security-advisories
   - GitHub Security Alerts: Enable for your repository
   - pub.dev Security: https://pub.dev/help/security

4. **Regular Audits**
   - Run `flutter pub outdated` monthly
   - Check pub.dev for "DISCONTINUED" or "UNLISTED" warnings
   - Review package health scores (popularity, likes, pub points)

### 📋 Update Action Plan

#### Phase 1: Low-Risk Updates (Week 1)
- [ ] Update dio to 5.9.0
- [ ] Update minor packages (cached_network_image, audio_service, etc.)
- [ ] Test API calls and image loading

#### Phase 2: Medium-Risk Updates (Week 2-3)
- [ ] Review bloc 9.0 migration guide
- [ ] Update bloc and flutter_bloc to 9.x
- [ ] Test all state management flows
- [ ] Update geolocator to 14.x
- [ ] Test location features

#### Phase 3: High-Risk Updates (Optional - Week 4-5)
- [ ] Review go_router 17.0 changelog
- [ ] Update go_router incrementally (13→14→15→16→17)
- [ ] Test all navigation flows and deep links

#### Phase 4: Verification (Week 4-6)
- [ ] Full regression testing
- [ ] Test on both iOS and Android
- [ ] Verify all critical user flows
- [ ] Monitor crash reports and analytics

---

---

## Related Documentation

- [Plugin Update Guide](plugin-update-guide.md) - Detailed update instructions for Flutter 3.22 & iOS 12
- [Code Simplification Opportunities](code-simplification-opportunities.md) - Dead code and simplifications

---

## Last Updated

November 2025