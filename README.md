# Metafter

A Flutter application foundation with multi-flavor build setup
(local / dev / uat / production).

## Project layout

```
lib/
  main.dart           # Production entrypoint + MetafterApp + bootstrap()
  main_dev.dart       # DEV flavor entrypoint
  main_uat.dart       # UAT flavor entrypoint
  main_local.dart     # LOCAL flavor entrypoint
  core/
    config/           # EnvironmentConfig
    constants/        # AppConstants, FormConstants
    network/          # ApiClient, ApiEndpoints, ApiExceptions
    routes/           # AppRouter (go_router)
    storage/          # SecureStorageService
    theme/            # Colors, dimensions, text styles, theme
    utils/            # Misc helpers
    widgets/          # Reusable form & shared widgets
  features/           # Add feature modules here
```

## Run

```bash
flutter pub get
flutter run -t lib/main_dev.dart           # DEV
flutter run -t lib/main_uat.dart           # UAT
flutter run -t lib/main.dart               # PROD
flutter run -t lib/main_local.dart         # LOCAL
```

## Build flavors

See `BUILD_INSTRUCTIONS.md`, `BUILD_FLAVORS_GUIDE.md`, and the various
`build-*.sh` scripts at the repo root.

## Renaming reminder

The Dart package name is `metafter`. Android `applicationId` and iOS bundle
identifier still reference the previous project — update them under
`android/app/build.gradle.kts` and the Xcode project before publishing.
