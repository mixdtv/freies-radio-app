# Android App Publishing Guide

This guide covers the complete process of publishing a Flutter app to the Google Play Store.

## Overview

Publishing to Google Play involves:
1. Google Play Developer account
2. Play Console setup
3. Building and uploading
4. Review process
5. Release (internal → closed → open → production)

**Timeline:** First submission typically takes 3-7 days. Updates are faster (hours to 3 days).

## Prerequisites

### 1. Google Play Developer Account ($25 one-time)

- Register at [play.google.com/console](https://play.google.com/console)
- Requires Google account
- Identity verification required (can take days)
- One-time fee (unlike Apple's annual fee)

### 2. Development Environment

- Android Studio (recommended) or any IDE
- Android SDK
- Java/Kotlin development tools

### 3. App Signing

Two options (see [android-signing.md](android-signing.md)):
- **Google Play App Signing** (recommended)
- **Self-managed signing key**

## Google Play Console Setup

### 1. Create App

1. Play Console → All apps → Create app
2. Fill in:
   - App name: Your app name
   - Default language: German
   - App or game: App
   - Free or paid: Free
3. Accept declarations

### 2. Store Listing

#### Main Store Listing

**Required:**
- App name (30 characters max)
- Short description (80 characters max)
- Full description (4000 characters max)

**Example:**
```
Short: Freies Radio - Die Platform für unabhängige Radios

Full:
Freies Radio – Die Platform für unabhängige Radios.
Entdecke Sender in deiner Nähe, durchstöbere Programmguides
und genieße kristallklares Streaming.

Funktionen:
• Finde Radiosender basierend auf deinem Standort
• Durchsuche Programmführer und Sendepläne
• Streame in hoher Qualität
• Wiedergabe im Hintergrund

Starte jetzt mit lokalem Radio!
```

#### Graphics

**Required:**
| Asset | Size | Notes |
|-------|------|-------|
| App icon | 512 x 512 px | PNG, 32-bit, no alpha |
| Feature graphic | 1024 x 500 px | Displayed at top of store listing |
| Screenshots | Min 2, max 8 | See below |

**Screenshot requirements:**
- Minimum: 320px
- Maximum: 3840px
- Aspect ratio: 16:9 or 9:16
- PNG or JPEG

**Recommended screenshots:**
- Phone: 1080 x 1920 px (portrait)
- 7" tablet: 1200 x 1920 px (optional)
- 10" tablet: 1600 x 2560 px (optional)

### 3. App Content

#### Privacy Policy

- **Required for all apps**
- Must be publicly accessible URL
- Must describe data collection/usage

#### App Access

If app requires login or special access:
- Provide test credentials
- This app: No special access needed

#### Ads

- Declare if app contains ads
- This app: No ads

#### Content Rating

Complete IARC questionnaire:
1. Play Console → App content → Content rating
2. Answer questions about content
3. Receive rating (likely: Everyone/PEGI 3)

#### Target Audience

- Select age groups
- If includes children under 13, additional requirements apply
- This app: Likely "13 and over" or "Everyone"

#### News App

- If app provides news content, additional requirements
- This app: May apply (radio news content)

#### Data Safety

Declare what data your app collects:

| Data Type | Collected | Purpose |
|-----------|-----------|---------|
| Location | Optional | Find nearby stations |
| Device ID | Yes | App functionality |
| App activity | Yes | Analytics (if applicable) |

## Testing Tracks

Google Play has multiple release tracks for testing before production:

### 1. Internal Testing (Recommended First)

**What:** Quick testing with up to 100 testers.

**Benefits:**
- No review required
- Immediate availability
- Perfect for development team

**Setup:**
1. Play Console → Testing → Internal testing
2. Create new release
3. Upload AAB file
4. Add testers by email
5. Testers join via opt-in link

**Testers setup:**
```
Play Console → Internal testing → Testers tab
→ Create email list
→ Add emails (up to 100)
→ Copy opt-in URL
→ Share URL with testers
```

**Tester experience:**
1. Receives opt-in URL
2. Accepts invitation (must be signed into Play Store with invited email)
3. Downloads app from Play Store (marked as "internal test")
4. Can provide feedback via Play Store

### 2. Closed Testing (Alpha/Beta)

**What:** Larger test group, requires review.

**Benefits:**
- Up to 2,000 testers per track
- Can create multiple tracks
- Pre-launch report included

**Setup:**
1. Play Console → Testing → Closed testing
2. Create track (e.g., "Alpha", "Beta")
3. Upload AAB
4. Add tester lists
5. Submit for review (few hours to 3 days)

**Use cases:**
- Extended beta testing
- Partner testing
- Staged rollout preparation

### 3. Open Testing (Public Beta)

**What:** Anyone can join and test.

**Benefits:**
- Unlimited testers
- Public opt-in link
- Great for gathering feedback at scale

**Setup:**
1. Play Console → Testing → Open testing
2. Upload AAB
3. Submit for review
4. Anyone can join via Play Store

**Considerations:**
- App is publicly visible as "Early Access"
- Reviews can affect your public rating
- Good for final validation before production

### 4. Production

**What:** Full public release.

**Setup:**
1. Play Console → Production
2. Upload AAB (or promote from testing track)
3. Submit for review
4. Release after approval

## Comparison: Testing Tracks

| Feature | Internal | Closed | Open | Production |
|---------|----------|--------|------|------------|
| Max testers | 100 | 2,000/track | Unlimited | Unlimited |
| Review required | No | Yes | Yes | Yes |
| Review time | Instant | Hours-days | Hours-days | Hours-days |
| Public visibility | No | No | Yes (Early Access) | Yes |
| Pre-launch report | No | Yes | Yes | Yes |
| Ratings affect store | No | No | Yes | Yes |
| Best for | Dev team | Beta users | Public beta | Launch |

## Adding Test Users

### Internal Testing

```
1. Play Console → Testing → Internal testing
2. Testers tab → Create email list
3. Enter list name (e.g., "Development Team")
4. Add email addresses (one per line):

   developer1@example.com
   developer2@example.com
   qa-team@example.com

5. Save → Copy opt-in URL
6. Share URL with testers
```

**Tester joins:**
1. Open opt-in URL on Android device
2. Sign in to Play Store with invited email
3. Accept invitation
4. Download app

### Closed Testing

Same as internal, but:
- Can have multiple tracks (Alpha, Beta)
- Requires review before testers can download
- Can use Google Groups for large tester lists

### Open Testing

No tester list needed:
- Anyone can opt-in via Play Store
- Just submit build for review
- Share Play Store link when approved

### License Testing (For In-App Purchases)

If testing purchases:
```
Play Console → Settings → License testing
Add emails of test accounts
These accounts can make "purchases" without being charged
```

## Building for Release

### 1. Build App Bundle (AAB)

Google Play requires AAB format (not APK):

```bash
# Using FVM (this project)
.fvm/flutter_sdk/bin/flutter build appbundle --release --dart-define-from-file=.env.json

# Or without FVM
flutter build appbundle --release --dart-define-from-file=.env.json
```

**Note:** The `--dart-define-from-file=.env.json` flag is required - it provides environment configuration (API endpoints, etc.) that the app needs to function.

Output: `build/app/outputs/bundle/release/freiesradio-v<versionCode>(<versionName>)-release.aab`

Example: `freiesradio-v2(1.0.0)-release.aab`

### 2. Verify Build

Before uploading:
```bash
# Check bundle contents
bundletool build-apks --bundle=app-release.aab --output=app.apks

# Test on device
bundletool install-apks --apks=app.apks
```

### 3. Upload to Play Console

1. Play Console → Select track
2. Create new release
3. Upload AAB file
4. Add release notes
5. Review and submit

## App Review Process

### What Google Reviews

1. **Policy compliance:** Content, ads, permissions
2. **Malware:** No malicious code
3. **Functionality:** App works as described
4. **Metadata:** Description matches app

### Review Timeline

| Submission Type | Typical Duration |
|-----------------|------------------|
| New app (first ever) | 7+ days |
| New app (established account) | 1-3 days |
| Update | Hours to 3 days |
| Internal testing | Instant |

**Note:** New developer accounts have longer review times until you build trust.

### Common Rejection Reasons

#### 1. Policy: Permissions

**Problem:** Requesting unnecessary permissions.

**Prevention:**
- Only request permissions you actually use
- Location: Only if needed for core feature
- Remove unused permissions from AndroidManifest.xml

**App permissions:**
- `INTERNET` - Required for streaming
- `ACCESS_FINE_LOCATION` - For nearby stations (justified)
- `FOREGROUND_SERVICE` - For background playback
- `WAKE_LOCK` - Keep audio playing

#### 2. Policy: Data Safety

**Problem:** Data safety declaration doesn't match behavior.

**Prevention:**
- Accurately declare data collection
- Review third-party SDKs' data collection
- Update declaration when adding features

#### 3. Policy: Functionality

**Problem:** App crashes, features don't work.

**Prevention:**
- Test on multiple devices
- Check Pre-launch report
- Handle offline scenarios

#### 4. Policy: Intellectual Property

**Problem:** Using trademarked names, copyrighted content.

**Prevention:**
- Own or license all content
- Don't use other brands' names
- Be careful with radio station logos

#### 5. Policy: Store Listing

**Problem:** Misleading description, wrong category.

**Prevention:**
- Description matches functionality
- Screenshots show actual app
- Category is accurate (Music & Audio)

### Pre-launch Report

Google automatically tests your app on real devices:

1. Play Console → Release → Pre-launch report
2. View after uploading to Closed/Open testing
3. Shows:
   - Crashes
   - Performance issues
   - Accessibility problems
   - Security vulnerabilities

**Act on findings before production release!**

## Release Strategies

### Staged Rollout (Recommended)

Release to percentage of users:

```
Day 1: 5% of users
Day 2: 10% (if no issues)
Day 3: 25%
Day 4: 50%
Day 5+: 100%
```

**Benefits:**
- Catch issues before all users affected
- Can halt rollout if problems
- Monitor crash rate per stage

**Setup:**
1. Create production release
2. Set rollout percentage (e.g., 5%)
3. Monitor Play Console for issues
4. Increase percentage over time
5. Click "Full rollout" when confident

### Immediate Full Rollout

Release to 100% immediately:
- Faster distribution
- Higher risk
- Good for critical fixes

### Managed Publishing

Control exactly when updates go live:
1. Play Console → Publishing overview → Managed publishing
2. Submit update → Goes to "Pending publication"
3. Click "Go live" when ready

## Post-Release

### Monitor

**Play Console:**
- Crashes and ANRs (App Not Responding)
- User reviews
- Install/uninstall metrics
- Country-specific data

**Android Vitals:**
- Crash rate (target: <1.09%)
- ANR rate (target: <0.47%)
- Excessive wake locks
- Stuck partial wake locks

### Respond to Reviews

- Reply to user reviews
- Thank positive reviewers
- Address negative feedback professionally
- Report fake reviews

### Updates

Same process:
1. Increment version in `pubspec.yaml`
2. Build new AAB
3. Upload to testing or production
4. Submit for review

## Checklist Before Submission

### Technical
- [ ] App runs without crashes
- [ ] All features work
- [ ] Tested on multiple Android versions (API 21+)
- [ ] Tested on multiple screen sizes
- [ ] Background audio works
- [ ] Location permission handled gracefully
- [ ] Offline behavior is reasonable
- [ ] No excessive battery drain

### Play Console
- [ ] Store listing complete
- [ ] Screenshots uploaded
- [ ] Feature graphic uploaded
- [ ] App icon uploaded
- [ ] Short description written
- [ ] Full description written
- [ ] Category selected
- [ ] Contact email set
- [ ] Privacy policy URL valid

### Content Rating
- [ ] IARC questionnaire completed
- [ ] Rating appropriate

### Data Safety
- [ ] All data collection declared
- [ ] Third-party SDK data included
- [ ] Purposes explained

### Signing
- [ ] Signing configured (Play App Signing or self-managed)
- [ ] Keystore backed up securely

## Timeline Planning

| Phase | Duration | Notes |
|-------|----------|-------|
| Developer registration | 1-5 days | Identity verification |
| Play Console setup | 2-4 hours | Store listing, graphics |
| Internal testing | 1-2 weeks | Team testing |
| Closed testing | 1-2 weeks | Beta users |
| Open testing (optional) | 1-2 weeks | Public beta |
| Production review | 1-7 days | Longer for new accounts |
| Staged rollout | 1 week | Gradual increase |
| **Total (new app)** | **4-8 weeks** | Conservative estimate |

## Comparing iOS and Android

| Aspect | iOS | Android |
|--------|-----|---------|
| Developer fee | $99/year | $25 one-time |
| Review time (first app) | 1-3 days | 3-7 days |
| Review time (updates) | 1 day | Hours-3 days |
| Internal testing | 100 testers | 100 testers |
| External/Closed testing | 10,000 testers | 2,000/track |
| Open testing | Via TestFlight | Native support |
| Staged rollout | Yes | Yes |
| App bundle format | IPA | AAB |
| Signing | Certificates/Profiles | Keystore |

## Troubleshooting

### Upload Fails

**"Upload failed. You uploaded an APK..."**
- Use AAB format, not APK
- `flutter build appbundle` not `flutter build apk`

**"Version code already used"**
- Increment `versionCode` in pubspec.yaml
- `version: 1.0.0+2` → `version: 1.0.0+3`

**"Signing certificate mismatch"**
- Use same signing key as previous uploads
- Check Play App Signing configuration

### Review Rejection

1. Read rejection email carefully
2. Check Policy Status in Play Console
3. Fix issues
4. Resubmit
5. Reply to appeal if needed

### Testers Can't Find App

- Ensure tester email matches Play Store account
- Tester must accept opt-in link
- Check tester is in correct list
- For closed testing, wait for review approval

## Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Developer Policy Center](https://play.google.com/about/developer-content-policy/)
- [App Quality Guidelines](https://developer.android.com/quality)
- [Pre-launch Report](https://support.google.com/googleplay/android-developer/answer/7002270)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
