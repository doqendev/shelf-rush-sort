# Shelf Rush Sort

Flutter + Flame implementation of the Shelf Rush Sort source-of-truth document.

The project is structured around a pure Dart gameplay domain, an application
session controller, a Flame presentation layer, and infrastructure adapters for
save, analytics, ads, IAP, remote config, consent, audio, haptics, and platform
services.

Bundled content includes a generated 300-level dev-test pack, 60 SKU metadata
entries, a product visual manifest, economy defaults, theme data, event catalog
metadata, validation metrics, and JSON schemas. It is not labeled as
soft-launch content until authored human-review metadata exists.

Useful commands:

```powershell
dart run tools/content_builder/bin/build_content.dart
flutter analyze
flutter test
flutter test test/presentation/board_layout_calculator_test.dart
dart run tools/level_validator/bin/validate_levels.dart
flutter run -d chrome --dart-define=SHELF_RUSH_ENV=qa
flutter build apk --debug --dart-define=SHELF_RUSH_ENV=qa
flutter build web --dart-define=SHELF_RUSH_ENV=qa
dart run tools/release_audit/bin/check_release_readiness.dart
```

Supported build environments are selected with `SHELF_RUSH_ENV`: `dev`, `qa`,
`staging`, or `production`. Dev and QA builds expose debug routes and sandbox
ad/IAP adapters; staging and production builds hide debug routes and use
production-service adapter boundaries that fail closed until SDK credentials are
configured. Staging and production also gate non-essential analytics until the
saved consent state is granted; essential operational events can still pass
through the analytics abstraction.

Cloud save is currently local-save-first and cloud-ready, not enabled. The cloud
adapter fails closed until a backend is configured; see
`docs/qa/cloud_save_decision.md`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
