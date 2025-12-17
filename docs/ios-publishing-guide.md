# iOS App Publishing Guide

This guide covers the complete process of publishing a Flutter app to the Apple App Store.

## Overview

Publishing to the App Store involves:
1. Apple Developer Program membership
2. App Store Connect setup
3. Building and uploading
4. App Review process
5. Release

**Timeline:** First submission typically takes 1-3 weeks. Updates are faster (1-3 days).

## Prerequisites

### 1. Apple Developer Program ($99/year)

- Enroll at [developer.apple.com](https://developer.apple.com/programs/)
- Individual or Organization account
- Organization requires D-U-N-S number (can take 1-2 weeks to obtain)

### 2. Development Environment

- macOS (required for iOS development)
- Xcode 15.0+ (latest stable recommended)
- Valid Apple ID connected to Developer Program

### 3. Certificates and Provisioning

**Certificates needed:**
- iOS Distribution Certificate (for App Store builds)
- Push Notification Certificate (if using push notifications)

**Provisioning Profiles:**
- App Store Distribution Profile

**Setup in Xcode:**
1. Xcode → Preferences → Accounts → Add Apple ID
2. Select team → Manage Certificates
3. Create iOS Distribution certificate if missing

## App Store Connect Setup

### 1. Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → (+) → New App
3. Fill in:
   - Platform: iOS
   - Name: Your app name (must be unique on App Store)
   - Primary Language: German (or English)
   - Bundle ID: Your bundle identifier (must match Xcode)
   - SKU: Unique identifier (e.g., `your-app-ios-001`)

### 2. App Information

**Required:**
- App name
- Subtitle (30 characters)
- Privacy Policy URL (required!)
- Category: Music
- Content Rights: Confirm you have rights to content

**Privacy Policy:**
- Must be hosted on a public URL
- Must describe data collection practices
- Required even if you collect no data

### 3. Pricing and Availability

- Price: Free
- Availability: Select countries
- Pre-orders: Optional

## Test Users and TestFlight

### TestFlight Overview

TestFlight allows testing before public release:
- **Internal Testing:** Up to 100 team members (instant, no review)
- **External Testing:** Up to 10,000 testers (requires Beta App Review)

### Setting Up Internal Testing

1. App Store Connect → Users and Access
2. Add team members with appropriate roles
3. Users download TestFlight app on their iOS device
4. They automatically see builds from apps they have access to

**Internal Tester Roles:**
- Admin: Full access
- App Manager: Manage specific apps
- Developer: Upload builds, view analytics
- Marketing: App Store metadata only

### Setting Up External Testing

1. App Store Connect → Your App → TestFlight
2. Create a new external testing group
3. Add testers by email (they don't need Apple Developer account)
4. Submit build for Beta App Review (usually 24-48 hours)
5. Once approved, testers receive email invitation

**External Testing Benefits:**
- Test with real users outside your organization
- Gather feedback before public launch
- Test in-app purchases without real charges
- 90-day expiration on builds

### Adding Test Users

**Internal Testers:**
```
App Store Connect → Users and Access → (+)
- Enter email
- Assign role
- User accepts invitation
- Downloads TestFlight
```

**External Testers:**
```
App Store Connect → TestFlight → External Testing → (+) Group
- Name the group (e.g., "Beta Testers")
- Add testers by email
- Submit build for review
- Testers receive invitation after approval
```

### TestFlight Best Practices

1. **Use Internal Testing First**
   - No review required
   - Faster iteration
   - Limited to team members

2. **External Testing for Wider Feedback**
   - Real user feedback
   - Test on diverse devices
   - Identify edge cases

3. **Include Release Notes**
   - What to test
   - Known issues
   - How to report bugs

4. **Set Up Feedback**
   - Enable screenshot feedback
   - Provide feedback email/form
   - Monitor crash reports in Xcode

## Building for Release

### 1. Configure Build Settings

**In Xcode:**
- Product → Scheme → Edit Scheme → Archive → Build Configuration: Release
- Signing: Select "iOS Distribution" certificate
- Deployment target: iOS 12.0 (or your minimum)

**In Flutter:**
```bash
flutter build ios --release --dart-define-from-file=.env.json
```

### 2. Archive and Upload

**Method 1: Xcode**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as destination
3. Product → Archive
4. Window → Organizer → Distribute App
5. Select "App Store Connect" → Upload

**Method 2: Command Line**
```bash
# Build
flutter build ipa --release --dart-define-from-file=.env.json

# Upload (requires Application Loader or Transporter)
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u YOUR_APPLE_ID -p APP_SPECIFIC_PASSWORD
```

### 3. Build Processing

After upload:
- Apple processes build (5-30 minutes)
- Automated checks run
- Build appears in App Store Connect / TestFlight

## App Store Review

### What Apple Reviews

1. **Functionality:** App works as described
2. **Design:** Follows Human Interface Guidelines
3. **Legal:** Privacy policy, content rights
4. **Safety:** No malicious code, appropriate content
5. **Performance:** No crashes, reasonable battery usage

### Common Rejection Reasons

#### 1. Guideline 2.1 - App Completeness
**Problem:** App crashes, has placeholder content, or features don't work.
**Prevention:**
- Test thoroughly on real devices
- Remove placeholder text/images
- Ensure all buttons lead somewhere

#### 2. Guideline 2.3 - Accurate Metadata
**Problem:** Screenshots don't match app, misleading description.
**Prevention:**
- Use real screenshots from current build
- Description matches actual functionality
- Don't mention unreleased features

#### 3. Guideline 4.2 - Minimum Functionality
**Problem:** App is too simple, web wrapper, or duplicate.
**Prevention:**
- Provide native app experience
- Add value beyond website
- Unique functionality

#### 4. Guideline 5.1.1 - Data Collection and Storage
**Problem:** Missing privacy policy, unclear data usage.
**Prevention:**
- Privacy policy URL is valid and accessible
- Accurately describe data collection in App Privacy
- Request only necessary permissions

#### 5. Guideline 5.1.2 - Data Use and Sharing
**Problem:** App collects data without consent.
**Prevention:**
- Request permissions at point of use
- Explain why you need location/microphone
- Don't collect unnecessary data

### App Privacy Details

Required in App Store Connect:
- What data you collect
- How data is used
- Whether data is linked to user identity

**For this app:**
- Location: For nearby radio stations (optional)
- Device ID: For app functionality
- Usage data: For analytics (if applicable)

### Preparing for Review

1. **Demo Account (if needed)**
   - Provide login credentials if app requires account
   - Not needed for this app (no login)

2. **Review Notes**
   - Explain non-obvious features
   - Describe how to test location features
   - Note any regional limitations

3. **Contact Information**
   - Ensure phone number is correct
   - Be available during review

### Review Timeline

| Type | Typical Duration |
|------|------------------|
| First submission | 24-48 hours (can be up to 1 week) |
| Update | 24 hours |
| Rejection resubmission | 24 hours |
| Expedited review | Same day (emergency only) |

## App Store Listing

### Screenshots (Required)

**Required sizes:**
- 6.7" (iPhone 14 Pro Max): 1290 x 2796 px
- 6.5" (iPhone 11 Pro Max): 1284 x 2778 px
- 5.5" (iPhone 8 Plus): 1242 x 2208 px
- 12.9" iPad Pro: 2048 x 2732 px (if supporting iPad)

**Best practices:**
- Show key features
- Include device frame (optional)
- Localize for each language
- First screenshot is most important

### App Description

**Structure:**
```
[Hook - what the app does]

[Key features as bullet points]

[Call to action]
```

**Example:**
```
Freies Radio brings independent German community radio to your fingertips. Discover stations near you, explore programs, and enjoy crystal-clear streaming.

Features:
• Find radio stations based on your location
• Browse program guides and schedules
• Stream in high quality
• Background playback support

Start listening to independent radio today!
```

### Keywords (100 characters max)

- Comma-separated
- Use relevant search terms
- Include German and English terms
- Don't repeat app name

Example: `radio,streaming,german,local,fm,live,music,news,podcast`

### What's New (Release Notes)

- Required for each version
- Keep it user-focused
- Mention new features and bug fixes

## Release Options

### Manual Release

- You control when app goes live
- Good for coordinated launches
- App approved → You click "Release"

### Automatic Release

- App goes live immediately after approval
- Good for updates
- Less control over timing

### Phased Release

- Gradual rollout over 7 days
- Starts with 1%, increases to 100%
- Can pause if issues arise
- Recommended for updates

## Post-Release

### Monitor

- App Store Connect → App Analytics
- Xcode → Organizer → Crashes
- User reviews and ratings

### Respond to Issues

- Monitor crash reports
- Respond to user reviews
- Submit updates for critical bugs

### Updates

- Same process: Archive → Upload → Review
- Faster review (usually 24 hours)
- Use phased release for safety

## Checklist Before Submission

### Technical
- [ ] App runs without crashes
- [ ] All features work correctly
- [ ] Tested on multiple iOS versions
- [ ] Tested on multiple device sizes
- [ ] Background audio works
- [ ] Location permission handled gracefully
- [ ] No console warnings/errors
- [ ] Performance is acceptable

### App Store Connect
- [ ] App name finalized
- [ ] Description complete
- [ ] Keywords added
- [ ] Screenshots uploaded (all sizes)
- [ ] App icon correct
- [ ] Privacy policy URL valid
- [ ] App Privacy details completed
- [ ] Contact info correct
- [ ] Age rating questionnaire completed
- [ ] Pricing set

### Legal
- [ ] Privacy policy published
- [ ] All content rights confirmed
- [ ] Third-party licenses documented

## Timeline Planning

| Phase | Duration | Notes |
|-------|----------|-------|
| Developer enrollment | 1-7 days | Longer for organizations |
| App Store Connect setup | 1-2 hours | |
| Build & upload | 30 min - 1 hour | |
| TestFlight testing | 1-2 weeks | Recommended |
| App Review | 1-3 days | Can be longer for first submission |
| **Total (first submission)** | **2-4 weeks** | |

## Troubleshooting

### Build Upload Fails

```
ERROR: Unable to upload
```
- Check internet connection
- Verify signing certificate
- Ensure provisioning profile matches

### "Missing Compliance" Warning

Apple asks about encryption:
- The app uses HTTPS (standard encryption)
- Answer: Uses encryption → Exempt (standard HTTPS)

### Review Rejection

1. Read rejection reason carefully
2. Fix the issue
3. Reply in Resolution Center
4. Resubmit

## Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
