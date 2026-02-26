FLUTTER := .fvm/flutter_sdk/bin/flutter
CONFIG ?= .env.json

.PHONY: help clean get devices select-device bump \
	android-debug android-release android-bundle android-deploy \
	ios-debug ios-release ios-deploy ios-deploy-release ios-ipa ios-publish

help:
	@echo "Usage: make <target> [CONFIG=<config-file>]"
	@echo ""
	@echo "General:"
	@echo "  get               Install dependencies"
	@echo "  clean             Clean build artifacts"
	@echo "  devices           List available devices"
	@echo "  bump              Increment build number in pubspec.yaml"
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
	@echo "Options:"
	@echo "  CONFIG            Config file for --dart-define-from-file (default: .env.json)"
	@echo "  DEVICE            Target device ID for ios-deploy targets"
	@echo ""
	@echo "Examples:"
	@echo "  make android-release"
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
	$(FLUTTER) build apk --debug --dart-define-from-file=$(CONFIG)

android-release: get
	$(FLUTTER) build apk --release --dart-define-from-file=$(CONFIG)

android-bundle: get
	$(FLUTTER) build appbundle --release --dart-define-from-file=$(CONFIG)

android-deploy: android-release
	$(FLUTTER) install --release

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

ios-ipa: get
	$(FLUTTER) build ipa --release --dart-define-from-file=$(CONFIG)

ios-publish: ios-ipa
	open build/ios/archive/Runner.xcarchive