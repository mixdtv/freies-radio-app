# Android App Signing

This document explains how to manage the Android signing key for the app.

## Background

Android requires all apps to be digitally signed before installation. The signing key:
- Proves the app comes from you
- Is required for publishing updates on Google Play
- Must remain the same for the lifetime of the app

## Current Setup

The app uses a Java KeyStore file (`key.jks`) located at `android/app/key.jks`. This file is **not tracked in git** for security reasons.

**To build a release:**
1. Obtain `key.jks` from secure storage (ask a team member)
2. Place it at `android/app/key.jks`
3. Configure passwords in `android/local.properties` (see `local.properties.example`)

## Options for Key Management

### Option 1: Google Play App Signing (Recommended)

Google Play App Signing lets Google manage your app signing key. You keep an "upload key" which can be reset if lost.

**Benefits:**
- If your upload key is lost or compromised, you can reset it
- Google optimizes APKs for different devices
- Smaller app downloads for users
- More secure: your signing key is stored in Google's secure infrastructure

**How to enable:**

1. **Go to Google Play Console**
   - Open [Google Play Console](https://play.google.com/console)
   - Select your app

2. **Navigate to App Signing**
   - Go to: Setup → App integrity → App signing

3. **Export and upload your existing key**

   Since the app is already published, you need to upload your existing key:

   a. Download the PEPK tool from Google Play Console (link provided on the page)

   b. Run the PEPK tool to encrypt your key:
   ```bash
   java -jar pepk.jar \
     --keystore=android/app/key.jks \
     --alias=radio \
     --output=encrypted-key.zip \
     --include-cert \
     --encryptionkey=<encryption-key-from-console>
   ```

   c. Upload `encrypted-key.zip` to Google Play Console

   d. Google will confirm the key matches your published app

4. **Generate a new upload key**

   After Google has your signing key, create a new upload key:
   ```bash
   keytool -genkey -v \
     -keystore upload-key.jks \
     -alias upload \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000
   ```

5. **Register the upload key with Google**
   - Export the certificate:
     ```bash
     keytool -export -rfc \
       -keystore upload-key.jks \
       -alias upload \
       -file upload-cert.pem
     ```
   - Upload `upload-cert.pem` to Google Play Console

6. **Update your build configuration**

   Update `android/app/build.gradle` to use the new upload key:
   ```groovy
   signingConfigs {
       release {
           storeFile file("upload-key.jks")
           storePassword System.getenv("ANDROID_STORE_PASSWORD") ?: localProperties.getProperty('android.storePassword')
           keyAlias "upload"
           keyPassword System.getenv("ANDROID_KEY_PASSWORD") ?: localProperties.getProperty('android.keyPassword')
       }
   }
   ```

7. **Secure storage**
   - Store the old `key.jks` securely as backup (password manager, encrypted cloud storage)
   - Store `upload-key.jks` securely
   - You can now safely delete local copies after backing up

**After enabling:**
- You sign app bundles with your upload key
- Google re-signs them with your app signing key before distribution
- If you lose your upload key, request a reset in Google Play Console

### Option 2: Self-Managed Signing Key

Continue managing the signing key yourself.

**Benefits:**
- Full control over your signing key
- No dependency on Google's infrastructure

**Risks:**
- If `key.jks` is lost, you can never update the app
- If `key.jks` is compromised, attackers can sign malicious updates
- No recovery option

**Requirements:**
- Store `key.jks` in multiple secure locations
- Never commit to version control
- Rotate passwords if team members leave

**Secure storage options:**
- Password manager (1Password, Bitwarden)
- Encrypted cloud storage
- Hardware security module (for enterprises)

**Backup checklist:**
- [ ] `key.jks` file backed up in 2+ secure locations
- [ ] `storePassword` documented securely
- [ ] `keyPassword` documented securely
- [ ] `keyAlias` documented (currently: `radio`)

## Recommendations

1. **Enable Google Play App Signing** - It's the industry standard and provides recovery options
2. **Back up everything** before making changes
3. **Test on internal track** after any signing changes
4. **Document all passwords** in a password manager

## Troubleshooting

**"App not signed with upload key"**
- Ensure you're using the correct keystore file
- Verify the alias matches (`radio` for old key, `upload` for new)

**"Signature mismatch"**
- The signing key doesn't match the published app
- You cannot change the signing key without Google Play App Signing

**Lost upload key (with Play App Signing enabled)**
1. Go to Google Play Console → Setup → App integrity
2. Click "Request upload key reset"
3. Follow Google's verification process
4. Generate and register a new upload key

## References

- [Google Play App Signing documentation](https://developer.android.com/studio/publish/app-signing)
- [Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [PEPK tool documentation](https://developer.android.com/studio/publish/app-signing#generate-key)
