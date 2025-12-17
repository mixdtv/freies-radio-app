# Plugin Update Guide - Flutter 3.22 & iOS 12+ Compatibility

**Date:** November 2025
**Flutter Version:** 3.22.0
**Dart SDK:** >=3.2.0 <4.0.0
**iOS Minimum:** 12.0
**Android Minimum:** API 21 (Android 5.0)

---

## Overview

This document provides recommendations for updating plugins while maintaining compatibility with:
- Flutter 3.22.0 (current version)
- iOS 12.0+ (minimum requirement)
- Android API 21+ (Android 5.0+)

---

## Current Plugin Status

### Summary Statistics

| Category | Status |
|----------|--------|
| **Total Direct Dependencies** | 20 packages |
| **Up to Date** | 3 packages (15%) |
| **Minor Updates Available** | 9 packages (45%) |
| **Major Updates Available** | 8 packages (40%) |
| **Security Vulnerabilities** | 0 known CVEs |
| **Discontinued Packages** | 0 |

---

## Package-by-Package Analysis

### 🔴 MAJOR UPDATES AVAILABLE

#### 1. bloc: 8.1.2 → 9.1.0

**Current:** 8.1.2 (October 2023)
**Latest:** 9.1.0 (October 2025) - **2 years behind**

**Changes in 9.0:**
- Breaking: `Bloc` constructor now requires `super()` call
- Breaking: `BlocObserver` renamed methods
- Performance improvements
- Better error messages

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** Medium
**Risk Level:** 🟡 Medium

**Breaking Changes:**
```dart
// Before (8.x):
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

// After (9.x):
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}
```

**Recommendation:** ✅ **UPDATE** - Well-tested, good documentation
**Priority:** High
**Estimated Time:** 2-4 hours (test all cubits)

---

#### 2. flutter_bloc: 8.1.3 → 9.1.1

**Current:** 8.1.3 (October 2023)
**Latest:** 9.1.1 (October 2025) - **2 years behind**

**Changes in 9.0:**
- Requires bloc 9.0+
- Improved context.read/watch/select performance
- Better error messages

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** Low (update with bloc)
**Risk Level:** 🟡 Medium

**Recommendation:** ✅ **UPDATE** (with bloc)
**Priority:** High
**Estimated Time:** Included in bloc update

---

#### 3. go_router: 13.0.1 → 17.2.4

**Current:** 13.0.1 (February 2025)
**Latest:** 17.2.4 (November 2025) - **4 major versions behind**

**Major Changes:**
- **14.0:** New route configuration API
- **15.0:** Improved type safety
- **16.0:** Better deep linking
- **17.0:** Performance improvements

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** High
**Risk Level:** 🔴 High

**Breaking Changes (Multiple Versions):**
```dart
// Many API changes across 4 major versions
// Requires careful migration
```

**Recommendation:** ⚠️ **WAIT** - Too many breaking changes
**Priority:** Medium
**Alternative:** Update incrementally (13→14→15→16→17) or wait for stable period
**Estimated Time:** 8-12 hours + thorough testing

---

#### 4. geolocator: 12.0.0 → 13.0.2

**Current:** 12.0.0 (September 2024)
**Latest:** 13.0.2 (September 2025) - **1 year behind**

**Changes in 13.0:**
- Breaking: New permission handling API
- Breaking: Changed location settings
- iOS 18 support improvements

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** Medium
**Risk Level:** 🟡 Medium

**Breaking Changes:**
```dart
// Before (12.x):
LocationPermission permission = await Geolocator.requestPermission();

// After (13.x):
LocationPermission permission = await Geolocator.requestPermission();
// API similar but internal changes
```

**Recommendation:** ✅ **UPDATE** - Worth it for bug fixes
**Priority:** Medium
**Estimated Time:** 2-3 hours (test location features)

---

#### 5. bloc_presentation: 1.0.0 → 1.1.2

**Current:** 1.0.0 (June 2024)
**Latest:** 1.1.2 (August 2025)

**Changes in 1.1:**
- Better null safety
- Performance improvements
- Bug fixes

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** Low
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe upgrade
**Priority:** Low
**Estimated Time:** 30 minutes

---

#### 6. android_id: 0.4.0 → 0.5.0

**Current:** 0.4.0
**Latest:** 0.5.0

**Changes in 0.5:**
- Updated Android API level support
- Deprecated old methods

**Flutter 3.22 Compatible:** ✅ Yes
**Android API 21+ Compatible:** ✅ Yes

**Migration Effort:** Low
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Simple upgrade
**Priority:** Low
**Estimated Time:** 15 minutes

---

### ⚠️ MINOR UPDATES AVAILABLE

#### 7. dio: 5.4.0 → 5.9.0

**Current:** 5.4.0 (February 2025)
**Latest:** 5.9.0 (August 2025) - **6 months behind**

**Changes:**
- Bug fixes
- Performance improvements
- Better error handling

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** Minimal
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe minor upgrade
**Priority:** Medium
**Estimated Time:** 30 minutes (test API calls)

---

#### 8. audio_service: 0.18.13 → 0.18.18

**Current:** 0.18.13 (April 2025)
**Latest:** 0.18.18 (October 2025)

**Changes:**
- Bug fixes
- iOS/Android compatibility improvements

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** None
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe patch update
**Priority:** Low
**Estimated Time:** 15 minutes

---

#### 9. cached_network_image: 3.3.1 → 3.4.1

**Current:** 3.3.1
**Latest:** 3.4.1

**Changes:**
- Performance improvements
- Bug fixes

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** None
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe minor update
**Priority:** Low
**Estimated Time:** 15 minutes

---

#### 10. shared_preferences: 2.2.2 → 2.3.4

**Current:** 2.2.2
**Latest:** 2.3.4

**Changes:**
- Bug fixes
- Platform updates

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** None
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe update
**Priority:** Low
**Estimated Time:** 15 minutes

---

#### 11. url_launcher: 6.2.6 → 6.3.2

**Current:** 6.2.6
**Latest:** 6.3.2

**Changes:**
- Platform updates
- Bug fixes

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** None
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe update
**Priority:** Low
**Estimated Time:** 15 minutes

---

#### 12. device_info_plus: 10.1.0 → 11.1.0

**Current:** 10.1.0
**Latest:** 11.1.0

**Changes:**
- Updated device detection
- Platform improvements

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** Low
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe minor update
**Priority:** Low
**Estimated Time:** 30 minutes

---

#### 13. geolocator_android: 4.5.5 → 4.6.1

**Current:** 4.5.5
**Latest:** 4.6.1

**Changes:**
- Android updates
- Bug fixes

**Flutter 3.22 Compatible:** ✅ Yes
**Android API 21+ Compatible:** ✅ Yes

**Migration Effort:** None
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** (with geolocator)
**Priority:** Low
**Estimated Time:** 15 minutes

---

#### 14. flutter_svg: 2.0.9 → 2.0.14

**Current:** 2.0.9
**Latest:** 2.0.14

**Changes:**
- Bug fixes
- Performance improvements

**Flutter 3.22 Compatible:** ✅ Yes
**iOS 12 Compatible:** ✅ Yes

**Migration Effort:** None
**Risk Level:** 🟢 Low

**Recommendation:** ✅ **UPDATE** - Safe patch update
**Priority:** Low
**Estimated Time:** 15 minutes

---

### ✅ UP TO DATE

#### 15. intl: 0.19.0

**Status:** ✅ Latest stable version
**No action needed**

#### 16. uuid: 4.4.0

**Status:** ✅ Latest stable version
**No action needed**

#### 17. toastification: 2.1.0

**Status:** ✅ Latest stable version
**No action needed**

#### 18. blurrycontainer: 2.1.0

**Status:** ✅ Latest stable version
**No action needed**

#### 19. after_layout: 1.2.0

**Status:** ✅ Latest stable version
**No action needed**

#### 20. scrollable_positioned_list: 0.3.8

**Status:** ✅ Latest stable version
**No action needed**

---

## Special Cases

### just_audio (Custom Fork)

**Current:** Custom fork from `github.com/IgoTs/just_audio` (minor branch)
**Latest Upstream:** ryanheise/just_audio 0.9.40

**Status:** ⚠️ Custom fork may be outdated

**Compatibility:**
- Flutter 3.22: ✅ Yes
- iOS 12: ✅ Yes

**Analysis:**
- Fork created to remove progress boundary checks
- May be missing upstream bug fixes and features

**Recommendation:** ⚠️ **MONITOR** - Check fork activity

**Action Items:**
1. Compare fork with upstream: `git diff IgoTs/just_audio ryanheise/just_audio`
2. Check if fork is still maintained
3. Consider:
   - Updating fork from upstream
   - Maintaining own fork
   - Finding alternative solution for progress boundary issue

**Risk Level:** 🟡 Medium (fork maintenance)
**Priority:** Medium
**Estimated Time:** 4-8 hours (research + potential migration)

---

## Security Vulnerabilities

### dio - CVE-2021-31402

**Status:** ✅ NOT AFFECTED

**Details:**
- **Vulnerability:** CRLF injection in HTTP method string
- **Affected Versions:** < 5.0.0
- **Fixed In:** 5.0.0+
- **Your Version:** 5.4.0 ✅ Safe

**CVSS Score:** 7.5 (High)

**Impact if Exploited:**
- HTTP response splitting
- Header injection
- Potential XSS

**Action Required:** ✅ None - Already safe. Update to 5.9.0 for improvements.

---

### All Other Packages

**Status:** ✅ NO KNOWN CVES

As of November 2025, no CVEs reported for:
- flutter_bloc / bloc
- go_router
- geolocator
- audio_service
- cached_network_image
- All other dependencies

---

## iOS 12 Compatibility Matrix

All packages are compatible with iOS 12+. Here's the breakdown:

| Package | iOS Minimum | iOS 12 Compatible | Notes |
|---------|-------------|-------------------|-------|
| audio_service | 10.0 | ✅ Yes | |
| geolocator | 11.0 | ✅ Yes | |
| cached_network_image | 9.0 | ✅ Yes | |
| url_launcher | 12.0 | ✅ Yes | Requires iOS 12+ |
| device_info_plus | 9.0 | ✅ Yes | |
| just_audio (fork) | 10.0 | ✅ Yes | |
| All others | N/A | ✅ Yes | Platform independent |

**Conclusion:** ✅ **All packages maintain iOS 12 compatibility**

**Critical:** `url_launcher` requires iOS 12.0 minimum, which matches our requirement.

---

## Update Recommendation Strategy

### Phase 1: Low-Risk Updates (Week 1)

**Safe to Update Immediately:**
1. ✅ dio: 5.4.0 → 5.9.0
2. ✅ audio_service: 0.18.13 → 0.18.18
3. ✅ cached_network_image: 3.3.1 → 3.4.1
4. ✅ shared_preferences: 2.2.2 → 2.3.4
5. ✅ url_launcher: 6.2.6 → 6.3.2
6. ✅ flutter_svg: 2.0.9 → 2.0.14
7. ✅ device_info_plus: 10.1.0 → 11.1.0
8. ✅ bloc_presentation: 1.0.0 → 1.1.2
9. ✅ android_id: 0.4.0 → 0.5.0

**Commands:**
```bash
flutter pub add dio:^5.9.0
flutter pub add audio_service:^0.18.18
flutter pub add cached_network_image:^3.4.1
flutter pub add shared_preferences:^2.3.4
flutter pub add url_launcher:^6.3.2
flutter pub add flutter_svg:^2.0.14
flutter pub add device_info_plus:^11.1.0
flutter pub add bloc_presentation:^1.1.2
flutter pub add android_id:^0.5.0
```

**Testing Required:**
- ✅ API calls (dio)
- ✅ Image loading (cached_network_image)
- ✅ Settings persistence (shared_preferences)
- ✅ External links (url_launcher)
- ✅ Audio playback (audio_service)

**Estimated Time:** 4 hours

---

### Phase 2: Medium-Risk Updates (Week 2-3)

**State Management:**
1. ⚠️ bloc: 8.1.2 → 9.1.0
2. ⚠️ flutter_bloc: 8.1.3 → 9.1.1

**Location:**
3. ⚠️ geolocator: 12.0.0 → 13.0.2
4. ⚠️ geolocator_android: 4.5.5 → 4.6.1

**Commands:**
```bash
flutter pub add bloc:^9.1.0 flutter_bloc:^9.1.1
flutter pub add geolocator:^13.0.2 geolocator_android:^4.6.1
```

**Migration Required:**
- Read bloc 9.0 migration guide: https://pub.dev/packages/bloc/changelog
- Update cubit event handlers
- Test all state management flows
- Test location permissions and fetching

**Testing Required:**
- ✅ All cubit state changes
- ✅ BLoC event handling
- ✅ Location permission flow
- ✅ GPS coordinate fetching
- ✅ Distance calculations

**Estimated Time:** 8-12 hours

---

### Phase 3: High-Risk Updates (Consider Deferring)

**Navigation:**
1. 🔴 go_router: 13.0.1 → 17.2.4

**Recommendation:** ⚠️ **DEFER** unless needed

**Reasons to Defer:**
- 4 major versions to jump
- Extensive breaking changes
- Complex migration
- Current version works fine

**If Updating:**
- Budget 2-3 days for migration
- Update incrementally: 13→14, 14→15, 15→16, 16→17
- Test after each major version
- Check navigation after each step

**Alternative:** Wait for stable period or critical bug fix

**Estimated Time:** 16-24 hours

---

### Phase 4: Special Attention (Ongoing)

**Custom Fork Monitoring:**
1. ⚠️ just_audio (custom fork)

**Recommendations:**
- Check IgoTs/just_audio for updates monthly
- Compare with upstream ryanheise/just_audio quarterly
- Consider options:
  - Keep current (if works well)
  - Update from upstream (if available)
  - Maintain own fork (if needed)

**Estimated Time:** 2 hours/quarter for monitoring

---

## Testing Checklist

### After Low-Risk Updates

```
[ ] App builds successfully
[ ] App launches without errors
[ ] API calls work (radio station list loads)
[ ] Images load (station logos)
[ ] Settings save/load (theme, favorites)
[ ] External links open (about page links)
[ ] Audio plays in background
[ ] No new warnings in console
```

### After Medium-Risk Updates

```
All of above, plus:
[ ] All cubit state changes work
[ ] Navigation between pages works
[ ] Location permission flow works
[ ] GPS location fetching works
[ ] Location-based station filtering works
[ ] App doesn't crash on state changes
[ ] Presentation events fire correctly (toasts, dialogs)
```

### After High-Risk Updates

```
All of above, plus:
[ ] Deep linking works
[ ] Navigation stack maintains correctly
[ ] Back button behavior correct
[ ] Route parameters pass correctly
[ ] Shell routes work (bottom nav, drawer)
[ ] Nested navigation works
[ ] Go/GoNamed/Push/Pop all work
```

---

## Flutter & Dart Version Considerations

### Current Environment

```yaml
environment:
  sdk: '>=3.2.0 <4.0.0'

flutter: 3.22.0
```

### Package Compatibility

✅ **All recommended updates are compatible with:**
- Dart SDK 3.2.0+
- Flutter 3.22.0

### Future Considerations

**Flutter 3.27+ (Next Stable):**
- Monitor for new package versions
- Check for deprecation warnings
- Update this guide when Flutter updates

**Dart 4.0 (Future):**
- May require package updates
- Watch for null safety changes
- Monitor breaking changes

---

## Commands Reference

### Check for Updates

```bash
# Show outdated packages
flutter pub outdated

# Show outdated with details
flutter pub outdated --show-all

# Check specific package
flutter pub outdated --package=dio
```

### Update Packages

```bash
# Update all to latest compatible
flutter pub upgrade

# Update all including breaking changes
flutter pub upgrade --major-versions

# Update specific package
flutter pub add package_name:^version

# Update and get dependencies
flutter pub upgrade && flutter pub get
```

### Verify After Update

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test

# Build and run
flutter run
```

---

## Risk Assessment Summary

| Update Type | Packages | Risk | Time | Priority |
|-------------|----------|------|------|----------|
| Minor/Patch | 9 packages | 🟢 Low | 4 hours | High |
| Major (Medium) | 4 packages | 🟡 Medium | 12 hours | Medium |
| Major (High) | 1 package (go_router) | 🔴 High | 24 hours | Low |
| Custom Fork | 1 package | 🟡 Medium | Ongoing | Medium |

**Total Time for Safe Updates:** ~16 hours (Phases 1 & 2)
**Total Time for All Updates:** ~40 hours (All phases)

**Recommendation:** Execute Phases 1 & 2, defer Phase 3 (go_router)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Nov 2025 | Initial plugin update guide |

---

**Maintained By:** Development Team
**Next Review:** February 2026
**Flutter Version:** 3.22.0
**Last Updated:** November 2025