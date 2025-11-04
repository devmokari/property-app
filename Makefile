# HomeGPT - Environment Setup
# -------------------------------
# Usage:
# make setup        -> Install dependencies
# make run-web      -> Run on browser
# make run-android  -> Run on Android
# make run-ios      -> Run on iOS
# make build-web    -> Build web release
# make clean        -> Clean project

APP_NAME := homegpt
IOS_DEVICE_ID := 563796BD-7F19-4303-A8A0-A5CA51354FEF
IOS_EMULATOR_ID := apple_ios_simulator
ANDROID_DEVICE_ID := emulator-5554
ANDROID_EMULATOR_ID := Medium_Phone_API_36.1

.PHONY: help setup run-web run-android run-ios build-web clean launch-ios-simulator launch-android-emulator

.DEFAULT_GOAL := help

help:
	@echo "HomeGPT - Available make targets:"
	@echo "  make setup        -> Install dependencies"
	@echo "  make run-web      -> Run on browser"
	@echo "  make run-android  -> Run on Android"
	@echo "  make run-ios      -> Run on iOS"
	@echo "  make launch-ios-simulator    -> Launch iOS simulator"
	@echo "  make launch-android-emulator -> Launch Android emulator"
	@echo "  make build-web    -> Build web release"
	@echo "  make clean        -> Clean project"

setup:
	@echo "🔧 Setting up Flutter environment for $(APP_NAME)..."
	flutter pub get
	flutter create .

run-web:
	@echo "🌐 Running $(APP_NAME) on Web..."
	flutter run -d chrome

run-android:
        @echo "🤖 Running $(APP_NAME) on Android..."
        @check_android() { flutter devices | grep -q "$(ANDROID_DEVICE_ID)"; }; \
        if ! check_android; then \
                flutter emulators --launch $(ANDROID_EMULATOR_ID); \
                attempts=0; \
                while [ $$attempts -lt 12 ] && ! check_android; do \
                        sleep 5; \
                        attempts=$$((attempts + 1)); \
                done; \
        fi; \
        if ! check_android; then \
                echo "Android emulator unavailable."; \
                exit 1; \
        fi
        flutter run -d $(ANDROID_DEVICE_ID)

run-ios:
        @echo "🍎 Running $(APP_NAME) on iOS..."
        @check_ios() { flutter devices | grep -q "$(IOS_DEVICE_ID)"; }; \
        if ! check_ios; then \
                flutter emulators --launch $(IOS_EMULATOR_ID); \
                attempts=0; \
                while [ $$attempts -lt 12 ] && ! check_ios; do \
                        sleep 5; \
                        attempts=$$((attempts + 1)); \
                done; \
        fi; \
        if ! check_ios; then \
                echo "iOS simulator unavailable."; \
                exit 1; \
        fi
        flutter run -d $(IOS_DEVICE_ID)

launch-ios-simulator:
	@echo "🚀 Launching iOS simulator..."
	flutter emulators --launch $(IOS_EMULATOR_ID)

launch-android-emulator:
	@echo "🚀 Launching Android emulator..."
	flutter emulators --launch $(ANDROID_EMULATOR_ID)

build-web:
	@echo "📦 Building $(APP_NAME) for Web..."
	flutter build web --release -t lib/main.dart

clean:
	@echo "🧹 Cleaning build artifacts..."
	flutter clean
