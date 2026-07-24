FLUTTER := .fvm/flutter_sdk/bin/flutter
CONFIG ?= .env.json
FLAVOR ?= play
ROLLOUT ?= 1.0

.PHONY: help clean get devices select-device bump bump-patch \
	android-debug android-release android-bundle android-deploy \
	ios-debug ios-release ios-deploy ios-deploy-release ios-ipa ios-publish \
	play-dry-run play-closed-internal play-beta play-production play-info fdroid-release

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
	@echo "  play-closed-internal  Build + upload to the closed-internal track"
	@echo "  play-beta         Promote a build to 'Closed testing - Beta' (VC=<code>)"
	@echo "  play-production   Promote a build to production (VC=<code> [ROLLOUT=1.0])"
	@echo "  play-info         List Play tracks, releases and testers"
	@echo "  fdroid-release    Build + sign + publish the F-Droid reproducible APKs"
	@echo ""
	@echo "Options:"
	@echo "  CONFIG            Config file for --dart-define-from-file (default: .env.json)"
	@echo "  FLAVOR            Android flavor: play or fdroid (default: play)"
	@echo "  DEVICE            Target device ID for ios-deploy targets"
	@echo ""
	@echo "Examples:"
	@echo "  make android-release"
	@echo "  make android-release FLAVOR=fdroid"
	@echo "  make ios-deploy DEVICE=00008101-XXXX"
	@echo "  make ios-ipa CONFIG=.env.local.json"

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

# F-Droid — reproducible build + sign + publish to GitHub releases
fdroid-release:
	gh workflow run "F-Droid reproducible build & release"