# Property App - Environment Setup
# -------------------------------
# Usage:
# make setup        -> Install dependencies
# make run-web      -> Run on browser
# make run-android  -> Run on Android
# make run-ios      -> Run on iOS
# make build-web    -> Build web release
# make clean        -> Clean project

APP_NAME := property-app

setup:
@echo "🔧 Setting up Flutter environment for $(APP_NAME)..."
flutter pub get

run-web:
@echo "🌐 Running $(APP_NAME) on Web..."
flutter run -d chrome

run-android:
@echo "🤖 Running $(APP_NAME) on Android..."
flutter run -d android

run-ios:
@echo "🍎 Running $(APP_NAME) on iOS..."
flutter run -d ios

build-web:
@echo "📦 Building $(APP_NAME) for Web..."
flutter build web --release -t lib/main.dart

clean:
@echo "🧹 Cleaning build artifacts..."
flutter clean
