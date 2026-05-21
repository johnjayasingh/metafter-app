# Will Cloud - Digital Will Management App

A Flutter mobile application for creating and managing digital wills, advance health directives, and powers of attorney.

**Current Version:** 1.7.1 (Build 121)
**Flutter SDK:** ^3.10.1
**Platforms:** iOS 13.0+, Android (minSdk 21)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, ^3.10.1)
- [Android Studio](https://developer.android.com/studio) with Android SDK
- [Xcode](https://developer.apple.com/xcode/) (for iOS builds, macOS only)
- [CocoaPods](https://cocoapods.org/) (`gem install cocoapods`)

## Setup

### 1. Clone and install dependencies

```bash
git clone <repository-url>
cd digitalwill
flutter pub get
```

### 2. Android signing setup

Create `android/key.properties` with your release keystore details:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=digitalwill
storeFile=<path-to-your-keystore.jks>
```

To generate a new keystore:

```bash
keytool -genkey -v -keystore digitalwill-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias digitalwill
```

### 3. iOS setup (macOS only)

```bash
cd ios
pod install
cd ..
```

For flavor support after `pod install`, run:

```bash
./ios/restore-flavor-configs.sh
```

#### Xcode Schemes

iOS builds require Xcode schemes for each environment. See `XCODE_SCHEMES_GUIDE.md` for setup instructions:

| Scheme | Bundle ID | Environment |
|---|---|---|
| Runner | `com.nydco.digitalwill` | Production |
| Runner-DEV | `com.nydco.digitalwill.dev` | Development |
| Runner-UAT | `com.nydco.digitalwill.uat` | UAT |

## Environments

The app supports 4 environments, each with its own entry point and API configuration:

| Environment | Entry Point | API Base URL | App Name |
|---|---|---|---|
| Local | `lib/main_local.dart` | `http://13.54.59.56:8000` | Will Cloud LOCAL |
| Dev | `lib/main_dev.dart` | `http://13.54.59.56:8000` | Will Cloud DEV |
| UAT | `lib/main_uat.dart` | `http://16.176.75.140:8000` | Will Cloud UAT |
| Production | `lib/main.dart` | `http://16.176.75.140:8000` | Will Cloud |

Each environment has a unique package ID so all versions can be installed simultaneously on the same device.

## Running the App

```bash
# Run on iOS simulator
flutter emulators --launch apple_ios_simulator
flutter run -d apple_ios_simulator --flavor dev -t lib/main_dev.dart

# Run on Android emulator
flutter run --flavor dev -t lib/main_dev.dart

# Or use the helper script
./run-app.sh
```

Replace `dev` / `main_dev.dart` with the desired environment.

## Building

### Using the universal build script

```bash
./build-flavors.sh <platform> <flavor> <type>

# Examples:
./build-flavors.sh android dev apk
./build-flavors.sh android uat aab
./build-flavors.sh ios dev ipa
```

Output is copied to the `builds/` directory with a timestamp.

### Android

```bash
# APK (for direct install)
flutter build apk --release --flavor dev -t lib/main_dev.dart
flutter build apk --release --flavor uat -t lib/main_uat.dart
flutter build apk --release --flavor prod -t lib/main.dart

# App Bundle (for Google Play)
flutter build appbundle --release --flavor dev -t lib/main_dev.dart
flutter build appbundle --release --flavor uat -t lib/main_uat.dart
flutter build appbundle --release --flavor prod -t lib/main.dart
```

Or use the dedicated scripts:

| Script | Output |
|---|---|
| `./build-dev-apk.sh` | `build/app/outputs/flutter-apk/app-dev-release.apk` |
| `./build-dev-aab.sh` | `build/app/outputs/bundle/devRelease/app-dev-release.aab` |
| `./build-uat-apk.sh` | `build/app/outputs/flutter-apk/app-uat-release.apk` |
| `./build-uat-aab.sh` | `build/app/outputs/bundle/uatRelease/app-uat-release.aab` |
| `./build-prod-apk.sh` | `build/app/outputs/flutter-apk/app-release.apk` |
| `./build-prod-aab.sh` | `build/app/outputs/bundle/prodRelease/app-release.aab` |

### iOS

```bash
# Build IPA for TestFlight
flutter build ipa --release --flavor dev -t lib/main_dev.dart --export-options-plist=ios/ExportOptions-dev-testflight.plist

# Build IPA for App Store
flutter build ipa --release --flavor prod -t lib/main.dart --export-options-plist=ios/ExportOptions-appstore.plist
```

Or use the dedicated scripts:

| Script | Purpose |
|---|---|
| `./build-dev-testflight.sh` | DEV build for TestFlight |
| `./build-uat.sh` | UAT ad-hoc distribution |
| `./build-uat-testflight.sh` | UAT build for TestFlight |
| `./build-appstore.sh` | Production build for App Store |

## Publishing

### Android (Google Play)

1. Build the AAB for the target environment:
   ```bash
   ./build-prod-aab.sh
   ```
2. Open [Google Play Console](https://play.google.com/console)
3. Upload the `.aab` file to the appropriate track:
   - **Internal testing** for dev/UAT builds
   - **Production** for release builds

### iOS (App Store / TestFlight)

1. Build the IPA:
   ```bash
   ./build-appstore.sh          # for App Store
   ./build-uat-testflight.sh    # for UAT TestFlight
   ```
2. Upload the `.ipa` using **Apple Transporter** or **Xcode Organizer**:
   ```bash
   xcrun altool --upload-app -f build/ios/ipa/digitalwill.ipa -t ios -u <apple-id> -p <app-specific-password>
   ```
3. Manage the release in [App Store Connect](https://appstoreconnect.apple.com)

## Project Structure

```
lib/
├── core/                  # Config, theme, networking, utilities
│   ├── config/            # Environment & payment configuration
│   ├── network/           # API client (Dio-based)
│   └── theme/             # App theming
├── features/              # Feature modules (will, ahd, poa, vault, etc.)
│   └── <feature>/
│       ├── data/          # Repositories, models, DTOs
│       └── presentation/  # Screens, widgets, BLoCs
├── main.dart              # Production entry point
├── main_dev.dart          # Dev entry point
├── main_uat.dart          # UAT entry point
└── main_local.dart        # Local entry point

android/                   # Android platform code & Gradle config
ios/                       # iOS platform code, Podfile, export plists
assets/
├── images/                # App icons and images
└── config/                # Payment configuration
```

## Key Configuration Files

| File | Purpose |
|---|---|
| `lib/core/config/environment_config.dart` | API URLs & environment settings |
| `assets/config/payment_config.json` | Stripe price IDs per environment |
| `android/app/build.gradle.kts` | Android flavors & signing |
| `android/key.properties` | Android keystore credentials |
| `ios/ExportOptions-*.plist` | iOS distribution profiles |
| `ios/set_environment.sh` | Updates iOS display name per environment |

## App Launcher Icons

To regenerate launcher icons after updating `assets/images/app_icon.png`:

```bash
flutter pub run flutter_launcher_icons
```
