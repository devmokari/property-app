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

.PHONY: help setup run-web run-android run-ios build-web clean

.DEFAULT_GOAL := help

help:
@echo "HomeGPT - Available make targets:"
	@echo "  make setup        -> Install dependencies"
	@echo "  make run-web      -> Run on browser"
	@echo "  make run-android  -> Run on Android"
	@echo "  make run-ios      -> Run on iOS"
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
	flutter run -d emulator-5554

run-ios:
	@echo "🍎 Running $(APP_NAME) on iOS..."
	flutter run -d 563796BD-7F19-4303-A8A0-A5CA51354FEF

build-web:
	@echo "📦 Building $(APP_NAME) for Web..."
	flutter build web --release -t lib/main.dart

clean:
	@echo "🧹 Cleaning build artifacts..."
	flutter clean
