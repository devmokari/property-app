<!-- .github/copilot-instructions.md for property-app -->
# Copilot / AI agent instructions — Property App

Purpose: brief, actionable guidance so an AI coding agent can be immediately productive in this repository.

1) Big picture
- Single-package Flutter app (cross-platform: iOS/Android/Web).
- Entrypoint: `lib/main.dart` (a tiny MaterialApp that displays “Hello Property App 👋”).
- No backend/service boundaries in this repo — it is a UI starter. Add integrations by adding packages (see "Dependencies").

2) Key files to read or edit
- `lib/main.dart` — main app widget, scaffold, and the displayed text.
- `pubspec.yaml` — SDK constraint (Dart >=3.0.0) and Flutter dependency; add packages here and run setup.
- `Makefile` — canonical developer commands (use these instead of memorizing flutter CLI flags):
  - `make setup` — runs `flutter pub get`
  - `make run-web` — runs on Chrome
  - `make run-android` / `make run-ios` — run on mobile targets
  - `make build-web` — builds a web release (`flutter build web --release -t lib/main.dart`)
  - `make clean` — runs `flutter clean`
- `README.md` — project-level notes and quick-start (mirrors Makefile).

3) Conventions and patterns (project-specific)
- Use the Makefile targets for local development and CI scripts (preferred over calling `flutter` directly in most quick edits).
- Keep the single `PropertyApp` widget in `lib/main.dart` as the primary entry; small edits often only require changing `home:` or `Text` content.
- Pubspec is minimal — when adding a package: update `pubspec.yaml`, then run `make setup` before running targets.

4) Typical quick changes (examples)
- Change displayed text: edit `lib/main.dart` -> Center -> `Text('Hello Property App 👋')` and run `make run-web` to verify.
- Add a route: modify `MaterialApp(...)` to include `routes: {...}` and set `home:` to a new `Widget`.
- Add dependency: add to `pubspec.yaml` then `make setup` and `make run-web` to smoke test.

5) Debugging & validation steps
- Validate environment: `flutter doctor`
- Run locally: `make run-web` is the fastest feedback loop for UI text/layout changes.
- View logs: use `flutter logs` or run with `flutter run -d <device-id>` for device logs.

6) Integration points / external dependencies
- Currently none (no external APIs present in this repo). Any integration will appear via new packages in `pubspec.yaml` or added platform code.

7) Merge guidance for editing this file
- If you find an existing `.github/copilot-instructions.md` content, preserve any project-specific examples (Makefile targets, special debug flags).
- Keep this file short (20–50 lines). Be concrete: reference exact files and Makefile targets.

If anything above is unclear or you want more details (local CI, platform setup, or preferred code style), tell me which area to expand and I will update this file.
