# Release Audit

Run the release audit after web and Android debug builds:

```powershell
flutter build web --dart-define=SHELF_RUSH_ENV=qa
flutter build apk --debug --dart-define=SHELF_RUSH_ENV=qa
dart run tools/release_audit/bin/check_release_readiness.dart
```

Current CI budgets are intentionally debug-build budgets:

- debug APK: 190 MiB maximum
- web build directory: 40 MiB maximum
- web `main.dart.js`: 4 MiB maximum
- bundled level pack: 2 MiB maximum
- product visual manifest: 256 KiB maximum

Production release builds must still be reviewed against the source-of-truth
install-size target of roughly 100-150 MB and real-device performance goals.
