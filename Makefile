FLUTTER := .fvm/flutter_sdk/bin/flutter
CONFIG ?= .env.json
FLAVOR ?= play
ROLLOUT ?= 1.0
SA_JSON ?= ../radiozeit-play-ci-serviceaccount.json
PLAY_VENV := .venv-play
ANDROID_SDK ?= $(HOME)/Library/Android/sdk
ADB ?= $(shell command -v adb 2>/dev/null || echo $(ANDROID_SDK)/platform-tools/adb)
SIM ?= iPhone 17
# App Store Connect API key — same credentials as the ASC_* repo secrets, for the
# local (non-CI) path of ios-external. Only the .p8 is sensitive.
ASC_KEY ?= ../AuthKey_V8UH6AWJW9.p8
ASC_KEY_ID ?= V8UH6AWJW9
ASC_ISSUER_ID ?= 5d8c4905-9596-4fc4-9221-596ab5653283
BUILD ?= latest
GROUP ?= External-1
WHATS_NEW ?=
# Multi-line release notes: point at a file instead (make cannot pass newlines).
WHATS_NEW_FILE ?=

.PHONY: help clean get devices select-device bump bump-patch \
	emulators ios-sim android-emu \
	android-debug android-release android-bundle android-deploy \
	ios-debug ios-release ios-deploy ios-deploy-release ios-ipa ios-publish \
	play-dry-run play-closed-internal play-push play-beta play-production play-info \
	ios-testflight ios-external ios-external-local ios-production fdroid-release

help:
	@echo "Usage: make <target> [CONFIG=<config-file>]"
	@echo ""
	@echo "General:"
	@echo "  get               Install dependencies"
	@echo "  clean             Clean build artifacts"
	@echo "  devices           List available devices"
	@echo "  bump              Increment build number in pubspec.yaml"
	@echo "  bump-patch        Bump patch version and reset build number to 1"
	@echo "  select-device     Select and save device for deploy targets"
	@echo ""
	@echo "Emulators:"
	@echo "  emulators         List available iOS simulators and Android AVDs"
	@echo "  ios-sim           Boot an iOS simulator and open Simulator.app (SIM=<name|udid>)"
	@echo "  android-emu       Start an Android emulator and wait for boot (AVD=<name>)"
	@echo ""
	@echo "Android:"
	@echo "  android-debug     Build debug APK"
	@echo "  android-release   Build release APK"
	@echo "  android-bundle    Build release App Bundle (Play Store)"
	@echo "  android-deploy    Build and install release APK on device"
	@echo ""
	@echo "iOS:"
	@echo "  ios-debug         Build debug iOS app"
	@echo "  ios-release       Build release iOS app"
	@echo "  ios-deploy        Build and install debug app on device (requires DEVICE=<id>)"
	@echo "  ios-deploy-release Build and install release app on device (requires DEVICE=<id>)"
	@echo "  ios-ipa           Build IPA (App Store / TestFlight)"
	@echo "  ios-publish       Build IPA and open archive in Xcode for distribution"
	@echo ""
	@echo "Deployment (CI via gh workflow — requires gh authenticated):"
	@echo "  play-dry-run          Validate a Play build+upload (publishes nothing)"
	@echo "  play-closed-internal  Build (CI) + upload a fresh AAB to closed-internal"
	@echo "  play-push             Attach an already-built VC to a track, no rebuild (VC=<code>)"
	@echo "  play-beta         Promote a build to 'Closed testing - Beta' (VC=<code>)"
	@echo "  play-production   Promote a build to production (VC=<code> [ROLLOUT=1.0])"
	@echo "  play-info         List Play tracks, releases and testers"
	@echo "  ios-testflight    Build on macOS CI + upload to TestFlight (API-key signing)"
	@echo "  ios-external      Submit a build for Beta App Review + give it to the external group"
	@echo "  ios-external-local  Same, run here with the local .p8 instead of CI"
	@echo "  ios-production    Prepare (and with SUBMIT=1 submit) an App Store release"
	@echo "  fdroid-release    Build + sign + publish the F-Droid reproducible APKs"
	@echo ""
	@echo "Options:"
	@echo "  CONFIG            Config file for --dart-define-from-file (default: .env.json)"
	@echo "  FLAVOR            Android flavor: play or fdroid (default: play)"
	@echo "  DEVICE            Target device ID for ios-deploy targets"
	@echo "  SIM               iOS simulator name or udid for ios-sim (default: $(SIM))"
	@echo "  AVD               Android AVD name for android-emu (default: first available)"
	@echo "  BUILD             Build number for ios-external (default: $(BUILD))"
	@echo "  GROUP             External beta group for ios-external (default: $(GROUP))"
	@echo "  DRY               Set to 1 to only report what ios-external would do"
	@echo "  WHATS_NEW         Release notes for ios-external / play-push (what users see)"
	@echo "  WHATS_NEW_FILE    Same, read from a file (use this for multi-line notes)"
	@echo "  SUBMIT            Set to 1 to really submit ios-production to App Store review"
	@echo "  RELEASE           ios-production: 'manual' holds the release after approval"
	@echo ""
	@echo "Examples:"
	@echo "  make android-release"
	@echo "  make android-release FLAVOR=fdroid"
	@echo "  make ios-deploy DEVICE=00008101-XXXX"
	@echo "  make ios-ipa CONFIG=.env.local.json"
	@echo "  make ios-sim SIM='iPhone 16e'"
	@echo "  make android-emu AVD=Medium_Phone_API_36.1"

# General
clean:
	$(FLUTTER) clean

get:
	$(FLUTTER) pub get

devices:
	@$(FLUTTER) devices

select-device:
	@echo "Available devices:"
	@$(FLUTTER) devices --machine 2>/dev/null | python3 -c "import sys,json; devs=json.load(sys.stdin); [print(f\"{i+1}) {d['name']} ({d['id']})\") for i,d in enumerate(devs)]"
	@echo ""
	@read -p "Select device number: " num; \
	device=$$($(FLUTTER) devices --machine 2>/dev/null | python3 -c "import sys,json; devs=json.load(sys.stdin); print(devs[int('$$num')-1]['id'])"); \
	echo "Selected: $$device"; \
	echo "$$device" > .selected_device

DEVICE ?= $(shell cat .selected_device 2>/dev/null)

# Emulators — start a simulator/emulator so the deploy targets have a device to
# talk to. Both print the device id to pass on as DEVICE=<id>.
emulators:
	@echo "iOS simulators:"
	@xcrun simctl list devices available -j | python3 -c "import sys,json; \
	  d=json.load(sys.stdin)['devices']; \
	  [print(f\"  {x['name']:24s} {x['udid']}  [{rt.split('SimRuntime.')[-1]}]{' (booted)' if x['state']=='Booted' else ''}\") \
	   for rt in sorted(d, reverse=True) if 'iOS' in rt for x in d[rt]]" 2>/dev/null \
	  || echo "  (xcrun simctl unavailable — Xcode installed?)"
	@echo ""
	@echo "Android AVDs:"
	@$(FLUTTER) emulators 2>/dev/null | awk -F' *• *' '/• *android *$$/ {printf "  %s (%s)\n", $$1, $$2}' \
	  || echo "  (none — create one in Android Studio)"

ios-sim:
	@udid=$$(xcrun simctl list devices available -j | python3 -c "import sys,json; \
	  d=json.load(sys.stdin)['devices']; \
	  c=[x for rt in sorted(d, reverse=True) if 'iOS' in rt for x in d[rt]]; \
	  m=[x for x in c if '$(SIM)' in (x['name'], x['udid'])] or [x for x in c if '$(SIM)'.lower() in x['name'].lower()]; \
	  print(([x for x in m if x['state']=='Booted'] or m)[0]['udid'] if m else '')"); \
	test -n "$$udid" || { echo "No iOS simulator matches SIM='$(SIM)' — see: make emulators"; exit 1; }; \
	xcrun simctl boot "$$udid" 2>/dev/null || true; \
	open -a Simulator; \
	xcrun simctl bootstatus "$$udid" -b >/dev/null; \
	echo "iOS simulator ready: $$udid"; \
	echo "  make ios-deploy DEVICE=$$udid"

android-emu:
	@avd="$(AVD)"; \
	if [ -z "$$avd" ]; then \
	  avd=$$($(FLUTTER) emulators 2>/dev/null | awk -F' *• *' '/• *android *$$/ {print $$1; exit}'); \
	fi; \
	test -n "$$avd" || { echo "No Android AVD found — create one in Android Studio."; exit 1; }; \
	test -x "$(ADB)" || { echo "adb not found at $(ADB) (set ADB=<path> or ANDROID_SDK=<path>)"; exit 1; }; \
	echo "Launching Android emulator: $$avd"; \
	$(FLUTTER) emulators --launch "$$avd"; \
	for i in $$(seq 1 120); do \
	  [ "$$($(ADB) shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break; \
	  sleep 2; \
	done; \
	serial=$$($(ADB) devices | awk '/emulator-.*device$$/ {print $$1; exit}'); \
	test -n "$$serial" || { echo "Emulator did not finish booting in time."; exit 1; }; \
	echo "Android emulator ready: $$serial"; \
	echo "  make android-deploy DEVICE=$$serial"

# Android
android-debug: get
	$(FLUTTER) build apk --debug --flavor $(FLAVOR) --dart-define-from-file=$(CONFIG)

android-release: get
	$(FLUTTER) build apk --release --flavor $(FLAVOR) --dart-define-from-file=$(CONFIG)

android-bundle: get
	$(FLUTTER) build appbundle --release --flavor $(FLAVOR) --dart-define-from-file=$(CONFIG)

android-deploy: android-release
	$(FLUTTER) install --release --flavor $(FLAVOR) -d $(DEVICE)

# iOS
ios-debug: get
	$(FLUTTER) build ios --debug --dart-define-from-file=$(CONFIG)

ios-release: get
	$(FLUTTER) build ios --release --dart-define-from-file=$(CONFIG)

ios-deploy:
	$(FLUTTER) run --debug -d $(DEVICE) --dart-define-from-file=$(CONFIG)

ios-deploy-release:
	$(FLUTTER) run --release -d $(DEVICE) --dart-define-from-file=$(CONFIG)

bump:
	@current=$$(grep '^version:' pubspec.yaml | sed 's/version: *//'); \
	name=$${current%%+*}; \
	build=$${current##*+}; \
	next=$$((build + 1)); \
	sed -i '' "s/^version: .*/version: $$name+$$next/" pubspec.yaml; \
	echo "Bumped version: $$name+$$build -> $$name+$$next"

bump-patch:
	@current=$$(grep '^version:' pubspec.yaml | sed 's/version: *//'); \
	name=$${current%%+*}; \
	build=$${current##*+}; \
	major=$${name%%.*}; \
	rest=$${name#*.}; \
	minor=$${rest%%.*}; \
	patch=$${rest#*.}; \
	next_patch=$$((patch + 1)); \
	next_build=$$((build + 1)); \
	new_version="$$major.$$minor.$$next_patch+$$next_build"; \
	sed -i '' "s/^version: .*/version: $$new_version/" pubspec.yaml; \
	echo "Bumped version: $$name+$$build -> $$major.$$minor.$$next_patch+$$next_build"

ios-ipa: get
	$(FLUTTER) build ipa --release --dart-define-from-file=$(CONFIG)

ios-publish: ios-ipa
	open build/ios/archive/Runner.xcarchive

# Deployment (CI). These dispatch GitHub Actions workflows via `gh`, which builds
# and signs in CI using the repo secrets. Requires `gh` authenticated for the repo.

# Google Play — tag→internal ladder: internal (devs) → beta group → production
play-dry-run:
	gh workflow run "Play Store release" -f dry_run=true

play-closed-internal:
	gh workflow run "Play Store release" -f dry_run=false

play-beta:
	@test -n "$(VC)" || { echo "Usage: make play-beta VC=<versionCode>"; exit 1; }
	gh workflow run "Play Store promote" -f version_code=$(VC) -f to_track="Closed testing - Beta"

play-production:
	@test -n "$(VC)" || { echo "Usage: make play-production VC=<versionCode> [ROLLOUT=1.0]"; exit 1; }
	gh workflow run "Play Store promote" -f version_code=$(VC) -f to_track=production -f rollout=$(ROLLOUT)

play-info:
	gh workflow run "Play Store info (read-only)"

# Direct push: attach an already-uploaded versionCode to a track (default
# closed-internal) via the Play API — no CI, no rebuild. Needs the service-account
# JSON locally (SA_JSON, default ../radiozeit-play-ci-serviceaccount.json).
TRACK_PUSH ?= closed-internal
play-push:
	@test -n "$(VC)" || { echo "Usage: make play-push VC=<versionCode> [TRACK_PUSH=closed-internal] [SA_JSON=path]"; exit 1; }
	@test -f "$(SA_JSON)" || { echo "service-account json not found: $(SA_JSON) (set SA_JSON=path)"; exit 1; }
	@test -d $(PLAY_VENV) || python3 -m venv $(PLAY_VENV)
	@$(PLAY_VENV)/bin/pip install -q google-api-python-client google-auth
	@$(PLAY_VENV)/bin/python scripts/play_set_track.py "$(SA_JSON)" "$(VC)" "$(TRACK_PUSH)" \
		$(if $(WHATS_NEW),--notes "$(WHATS_NEW)",) $(if $(WHATS_NEW_FILE),--notes-file "$(WHATS_NEW_FILE)",)

# Apple — build on macOS CI, cloud-sign via ASC API key, upload to TestFlight
ios-testflight:
	gh workflow run "iOS TestFlight"

# Hand an already-uploaded build to the external beta group (Beta App Review +
# group assignment). Internal testers get every build without any of this.
ios-external:
	@notes="$(WHATS_NEW)"; \
	if [ -n "$(WHATS_NEW_FILE)" ]; then \
	  test -f "$(WHATS_NEW_FILE)" || { echo "notes file not found: $(WHATS_NEW_FILE)"; exit 1; }; \
	  notes=$$(cat "$(WHATS_NEW_FILE)"); \
	fi; \
	gh workflow run "iOS TestFlight external" -f build=$(BUILD) -f group="$(GROUP)" \
		-f whats_new="$$notes" -f dry_run=$(if $(DRY),true,false)

# Same thing straight from here, using the local .p8 instead of the repo secrets
# — like play-push. DRY=1 only reports what would happen.
ios-external-local:
	@test -f "$(ASC_KEY)" || { echo "ASC key not found: $(ASC_KEY) (set ASC_KEY=path)"; exit 1; }
	@test -d $(PLAY_VENV) || python3 -m venv $(PLAY_VENV)
	@$(PLAY_VENV)/bin/pip install -q pyjwt cryptography
	@$(PLAY_VENV)/bin/python scripts/asc_distribute.py \
		"$(ASC_KEY)" "$(ASC_KEY_ID)" "$(ASC_ISSUER_ID)" "$(BUILD)" "$(GROUP)" \
		$(if $(WHATS_NEW),--whats-new "$(WHATS_NEW)",) $(if $(WHATS_NEW_FILE),--whats-new-file "$(WHATS_NEW_FILE)",) \
		$(if $(DRY),--dry-run,)

# Apple — App Store release: create/attach the store version for an uploaded
# build and hand it to App Store review. SUBMIT=1 actually submits; without it
# the version is only prepared and stays editable in App Store Connect.
# RELEASE=manual holds the release until you press the button.
ios-production:
	@test -f "$(ASC_KEY)" || { echo "ASC key not found: $(ASC_KEY) (set ASC_KEY=path)"; exit 1; }
	@test -d $(PLAY_VENV) || python3 -m venv $(PLAY_VENV)
	@$(PLAY_VENV)/bin/pip install -q pyjwt cryptography
	@$(PLAY_VENV)/bin/python scripts/asc_release.py \
		"$(ASC_KEY)" "$(ASC_KEY_ID)" "$(ASC_ISSUER_ID)" "$(BUILD)" \
		--release-type $(if $(filter manual,$(RELEASE)),MANUAL,AFTER_APPROVAL) \
		$(if $(WHATS_NEW),--whats-new "$(WHATS_NEW)",) $(if $(WHATS_NEW_FILE),--whats-new-file "$(WHATS_NEW_FILE)",) \
		$(if $(SUBMIT),--submit,) $(if $(DRY),--dry-run,)

# F-Droid — reproducible build + sign + publish to GitHub releases
fdroid-release:
	gh workflow run "F-Droid reproducible build & release"