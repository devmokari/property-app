# HomeGPT

A minimal Flutter starter configured for the HomeGPT project. The initial goal is to ensure every contributor can bootstrap a working Flutter environment that targets iOS, Android, and Web from a single codebase.

## Prerequisites

- Flutter SDK (3.x or newer) – [installation guide](https://docs.flutter.dev/get-started/install)
- Platform-specific toolchains configured via `flutter doctor`

## Getting Started

```bash
flutter doctor
make setup
```

### Run on the Web

```bash
make run-web
```

### Run on Android

```bash
make run-android
```

### Run on iOS

```bash
make run-ios
```

### Build Web Release

```bash
make build-web
```

### Clean the Workspace

```bash
make clean
```

## Troubleshooting

### Android build fails with `source.properties` missing in the NDK

When the Android toolchain reports an error similar to the following while running `make run-android`:

```
[CXX1101] NDK at <path>/ndk/27.0.12077973 did not have a source.properties file
```

it usually means the NDK download is incomplete or corrupted. Remove the broken
NDK folder and reinstall the same version so Gradle can pick it up correctly.

```bash
rm -rf ~/Library/Android/sdk/ndk/27.0.12077973
sdkmanager --install "ndk;27.0.12077973"
```

You can also reinstall the NDK through Android Studio by opening **SDK Manager →
SDK Tools**, unchecking the existing NDK, applying the change, and then
installing it again. Once the NDK is reinstalled, re-run `flutter doctor` (to
accept any pending licenses) and retry the `make run-android` command.

## Project Structure

```
homegpt/
├── lib/
│   └── main.dart
├── pubspec.yaml
├── Makefile
└── README.md
```

## Hello World

Running any of the `make run-*` targets will display the message **“Hello HomeGPT 👋”** in the selected platform target.
