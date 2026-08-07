# Releasing

How a build gets from this repo to Google Play, the App Store and F-Droid.

Every step is a `make` target. Most of them dispatch a GitHub Actions workflow,
which is what makes releasing possible from any machine: the signing keys live
in GitHub secrets, not on your laptop. See
[From another computer](#from-another-computer) for what you need locally.

`make help` lists every target and variable.

## Versioning

One place drives everything: `version: x.y.z+N` in `pubspec.yaml`. The `+N`
becomes the Android `versionCode` **and** the iOS `CFBundleVersion`, so both
stores stay in step.

```bash
make bump         # 1.0.3+21 -> 1.0.3+22   (new build of the same version)
make bump-patch   # 1.0.3+21 -> 1.0.4+22   (new version)
```

Commit the bump before building — CI builds whatever is on `main`. A
`versionCode` can never be reused: Play rejects a second upload of the same
number, and Apple rejects a second build with the same `CFBundleVersion` inside
one version train.

## Release notes

Android reads them from a file per version code, and F-Droid reads the same
layout:

```
fastlane/metadata/android/de-DE/changelogs/<versionCode>.txt
fastlane/metadata/android/en-US/changelogs/<versionCode>.txt
```

Create the file for the new version code *before* the release run — that is the
only route that carries notes automatically. Everything else takes them ad hoc:

```bash
make <target> WHATS_NEW="single line"
make <target> WHATS_NEW_FILE=fastlane/metadata/android/de-DE/changelogs/21.txt
```

Use `WHATS_NEW_FILE` for anything longer than one line; make cannot pass a
multi-line variable into a recipe. If you set nothing, the build ships without
notes — stale notes are never carried over from an older build.

## Android (Google Play)

The ladder is `closed-internal` → `Closed testing - Beta` → `production`.

```bash
make play-info                      # what is on which track right now
make play-dry-run                   # build + validate the upload, publishes nothing
make play-closed-internal           # build in CI, upload to closed-internal
make play-beta VC=22                # promote to the beta group (15 testers)
make play-production VC=22          # promote to production
make play-production VC=22 ROLLOUT=0.2   # staged rollout to 20 % of users
```

`play-dry-run` only says something useful right after a `make bump` — it builds
the current version, so with an already-uploaded version code it fails with
"Version code N has already been used" before it validates anything else.

Promotion carries the release notes of the source track along, so notes set on
`closed-internal` reach production without repeating them.

To move an already-built version code between tracks without rebuilding
(**local only**, needs the Play service account, see below):

```bash
make play-push VC=22 TRACK_PUSH=closed-internal WHATS_NEW_FILE=…
```

## iOS (TestFlight and the App Store)

TestFlight and a store release are two separate processes.

```bash
make ios-testflight                 # build on macOS CI, sign, upload to TestFlight
```

Internal testers get that build as soon as Apple finishes processing it —
nothing else to do. External testers (the public-link group) need Apple's beta
review first:

```bash
make ios-external DRY=1                       # report only, changes nothing
make ios-external WHATS_NEW_FILE=…            # submit to beta review + assign group
make ios-external BUILD=21 GROUP=External-1   # defaults: latest build, External-1
```

The store release is its own version object, its own review, and takes days
rather than hours:

```bash
make ios-production DRY=1                       # report only
make ios-production WHATS_NEW_FILE=…            # create version, attach build — stays editable
make ios-production WHATS_NEW_FILE=… SUBMIT=1   # hand it to App Store review
make ios-production … RELEASE=auto              # release right after approval (default: manual)
make ios-production … PHASED=1                  # roll out over 7 days
```

Preparing and submitting are deliberately separate: without `SUBMIT=1` the
version is created and stays editable in App Store Connect, so you can check
metadata and screenshots before Apple sees it. With `SUBMIT=1` the tooling
refuses to submit when a build, description, "What's New", screenshots or the
review contact are missing, and lists what is.

With the default `RELEASE=manual` the app does **not** go live on approval —
press Release in App Store Connect when you want it.

## F-Droid

```bash
make fdroid-release
```

Builds the reproducible APKs, signs them and publishes them as a GitHub
release. F-Droid's own buildserver then rebuilds from source and compares the
result; the app is only published there once that matches. The build steps live
in `.github/workflows/fdroid-release.yml`, the app's F-Droid metadata in the
`fdroiddata` fork (`metadata/de.radiozeit.freiesradio.fdroid.yml`).

Two things bite here: the reference build must happen at F-Droid's buildserver
path, because Flutter bakes the absolute build directory into `libapp.so`, and
the workflow's docker script is single-quoted — an apostrophe in a comment
breaks the quoting.

## From another computer

**The CI targets need nothing but `gh`.** The signing keys and API credentials
are GitHub secrets; the workflow uses them, your machine never sees them.

```bash
gh auth login          # once, with an account that can write to this repo
make play-closed-internal
```

Works from any machine, including Linux, and for anyone with repo access:

| Target | Needs |
|---|---|
| `play-dry-run`, `play-closed-internal` | `gh` |
| `play-beta`, `play-production`, `play-info` | `gh` |
| `ios-testflight` | `gh` |
| `ios-external` | `gh` |
| `fdroid-release` | `gh` |

**Three targets run locally and need private keys** that deliberately live
*outside* the repo, one directory up:

| Target | Needs |
|---|---|
| `play-push` | `../radiozeit-play-ci-serviceaccount.json` (override with `SA_JSON=`) |
| `ios-external-local` | `../AuthKey_<KEYID>.p8` (override with `ASC_KEY=`) |
| `ios-production` | the same `.p8` |

Both files are secrets: the Play service-account JSON and the App Store Connect
API key. Ask a team member, store them in the password manager, and keep them
out of any repo. They are the same credentials as the `PLAY_SERVICE_ACCOUNT_JSON`
and `ASC_KEY_P8_BASE64` secrets — only the key ID and issuer ID are harmless
enough to sit in the `Makefile`.

`ios-production` has no CI counterpart yet, so an App Store release currently
requires the `.p8` locally. Everything else is reachable with `gh` alone.

Local targets create a Python virtualenv (`.venv-play/`) on first use and
install what they need; nothing to set up by hand.

## Checking state without changing anything

```bash
make play-info                     # Play tracks, releases, testers
make ios-external-local DRY=1      # TestFlight build + beta review state
make ios-production DRY=1          # what a store release would do
make play-dry-run                  # validate a Play upload (after a bump)
```

## Known constraints

- **iOS builds run on `macos-26`.** Apple rejects uploads built with an SDK
  older than iOS 26, and the job asserts the SDK version before building rather
  than failing after the upload.
- **The export uses `ios/fastlane/ExportOptions.plist`**, not gym's generated
  one, because Xcode 26 only accepts the export method name
  `app-store-connect` and fastlane cannot emit it.
- **The Program License Agreement blocks everything Apple** when unsigned —
  every API call returns 403 `FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED`.
  Only the Account Holder can accept it at developer.apple.com/account.
- **`MinimumOSVersion` is 12.0** and Apple wants 13.0 during 2026 and 15.0 from
  spring 2027. Raising it means changing `ios/Podfile` (both the `platform` line
  and the `post_install` override), `ios/Runner.xcodeproj/project.pbxproj` and
  `ios/Flutter/AppFrameworkInfo.plist` together.
- **The F-Droid signing key is permanent.** `android/app/key.jks` is pinned by
  `AllowedAPKSigningKeys` in F-Droid's metadata; losing it ends F-Droid updates
  for this app.
