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
