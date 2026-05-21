# Build Configuration Guide: UAT and Dev Environments

This guide explains how to create separate builds for DEV and UAT environments for both Android and iOS platforms.

## Overview

The project is now configured with three environments:
- **DEV** - Development environment for internal testing
- **UAT** - User Acceptance Testing environment for testers
- **PROD** - Production environment (original main.dart)

## Project Structure

### Entry Points
- `lib/main.dart` - Production entry point
- `lib/main_dev.dart` - DEV environment entry point
- `lib/main_uat.dart` - UAT environment entry point

### Configuration
- `lib/core/config/environment_config.dart` - Environment configuration with API URLs

## Android Configuration

### Flavors Setup
The Android app is configured with three product flavors:
- **dev**: Dev environment with package suffix `.dev`
- **uat**: UAT environment with package suffix `.uat`
- **prod**: Production environment

### Package IDs
- Dev: `com.nydsystems.digitalwill.dev`
- UAT: `com.nydsystems.digitalwill.uat`
- Prod: `com.nydsystems.digitalwill`

### Building Android Apps

#### 1. Build DEV APK
```bash
./build-flavors.sh android dev apk
```
Output: `builds/android/dev/digitalwill-dev-[timestamp].apk`

#### 2. Build UAT APK
```bash
./build-flavors.sh android uat apk
```
Output: `builds/android/uat/digitalwill-uat-[timestamp].apk`

#### 3. Build DEV AAB (for Play Store)
```bash
./build-flavors.sh android dev aab
```
Output: `builds/android/dev/digitalwill-dev-[timestamp].aab`

#### 4. Build UAT AAB (for Play Store)
```bash
./build-flavors.sh android uat aab
```
Output: `builds/android/uat/digitalwill-uat-[timestamp].aab`

### Manual Flutter Commands (Alternative)

```bash
# DEV APK
flutter build apk --release --flavor dev -t lib/main_dev.dart

# UAT APK
flutter build apk --release --flavor uat -t lib/main_uat.dart

# DEV AAB
flutter build appbundle --release --flavor dev -t lib/main_dev.dart

# UAT AAB
flutter build appbundle --release --flavor uat -t lib/main_uat.dart
```

## iOS Configuration

### Schemes Setup (Manual Steps Required)

iOS requires manual Xcode configuration to create schemes:

#### Step 1: Open Xcode
```bash
cd ios
open Runner.xcworkspace
```

#### Step 2: Duplicate the Runner Scheme
1. In Xcode, go to **Product > Scheme > Manage Schemes**
2. Select "Runner" and click the gear icon (⚙️), then choose **Duplicate**
3. Rename it to "dev"
4. Click **Edit Scheme**
5. Under **Build > Pre-actions**, add:
   - Click "+" and select "New Run Script Action"
   - In the script field, enter:
     ```bash
     echo "DEV" > ${SRCROOT}/Flutter/Environment.xcconfig
     ```

#### Step 3: Create UAT Scheme
1. Repeat Step 2 but name the scheme "uat"
2. In the Pre-actions script, use:
   ```bash
   echo "UAT" > ${SRCROOT}/Flutter/Environment.xcconfig
   ```

#### Step 4: Configure Info.plist for Dynamic Bundle IDs

1. Open `ios/Runner/Info.plist`
2. Find `CFBundleIdentifier` and change it to:
   ```xml
   <key>CFBundleIdentifier</key>
   <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
   ```

#### Step 5: Set Bundle IDs in Build Settings
1. In Xcode, select the **Runner** project
2. Select the **Runner** target
3. Go to **Build Settings** tab
4. Search for "Product Bundle Identifier"
5. Set values for each configuration:
   - Debug-dev: `com.nydsystems.digitalwill.dev`
   - Release-dev: `com.nydsystems.digitalwill.dev`
   - Debug-uat: `com.nydsystems.digitalwill.uat`
   - Release-uat: `com.nydsystems.digitalwill.uat`
   - Debug: `com.nydsystems.digitalwill`
   - Release: `com.nydsystems.digitalwill`

### Building iOS Apps

#### Using the Build Script
```bash
# DEV
./build-flavors.sh ios dev ipa

# UAT
./build-flavors.sh ios uat ipa
```

#### Manual Archive in Xcode
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select the appropriate scheme (dev or uat)
3. Choose a real device (not simulator)
4. Go to **Product > Archive**
5. Once archived, click **Distribute App**
6. Choose distribution method:
   - **Ad Hoc** - For direct distribution to testers
   - **Development** - For development devices
   - **App Store Connect** - For TestFlight

### Manual Flutter Commands

```bash
# DEV
flutter build ios --release --flavor dev -t lib/main_dev.dart

# UAT
flutter build ios --release --flavor uat -t lib/main_uat.dart
```

## Environment Configuration

Update the API URLs in `lib/core/config/environment_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.dev:
      return 'https://dev-api.yourcompany.com'; // ← Update this
    case Environment.uat:
      return 'https://uat-api.yourcompany.com'; // ← Update this
    case Environment.production:
      return 'https://api.yourcompany.com'; // ← Update this
  }
}
```

## Distribution to Testers

### Android Distribution

#### Option 1: Direct APK Installation
1. Send the APK file to testers via email/cloud storage
2. Testers need to enable "Install from Unknown Sources"
3. Install the APK

#### Option 2: Firebase App Distribution
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Upload APK
firebase appdistribution:distribute builds/android/dev/digitalwill-dev.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "dev-testers" \
  --release-notes "DEV build for testing"
```

#### Option 3: Google Play Internal Testing
1. Build AAB: `./build-flavors.sh android dev aab`
2. Upload to Google Play Console
3. Create Internal Testing track
4. Add testers by email

### iOS Distribution

#### Option 1: TestFlight (Recommended)
1. Archive in Xcode with the appropriate scheme
2. Distribute to App Store Connect
3. Add testers in App Store Connect
4. Testers receive invitation via email

#### Option 2: Ad Hoc Distribution
1. Add tester device UDIDs to your Apple Developer account
2. Create Ad Hoc provisioning profile
3. Archive and distribute as Ad Hoc
4. Share IPA file with testers (via TestFlight or direct link)

## Identifying Builds

Each environment has clear identifiers:

### Visual Indicators
- **App Name**: 
  - Dev: "Will Cloud DEV"
  - UAT: "Will Cloud UAT"
  - Prod: "Will Cloud"

- **Title Bar** (in app):
  - Dev: "Will Cloud [DEV]"
  - UAT: "Will Cloud [UAT]"
  - Prod: "Will Cloud"

### Package/Bundle IDs
- Android Dev: `com.nydsystems.digitalwill.dev`
- Android UAT: `com.nydsystems.digitalwill.uat`
- iOS Dev: `com.nydsystems.digitalwill.dev`
- iOS UAT: `com.nydsystems.digitalwill.uat`

## Testing the Setup

### Test Android Build
```bash
# Build and install DEV on connected device
flutter run --release --flavor dev -t lib/main_dev.dart

# Build and install UAT on connected device
flutter run --release --flavor uat -t lib/main_uat.dart
```

### Test iOS Build
```bash
# Build and install DEV on connected simulator/device
flutter run --release --flavor dev -t lib/main_dev.dart

# Build and install UAT on connected simulator/device
flutter run --release --flavor uat -t lib/main_uat.dart
```

## Troubleshooting

### Android Issues

**Error: "No flavor configured"**
- Ensure you're using the correct flavor name: `dev`, `uat`, or `prod`
- Check `android/app/build.gradle.kts` has the productFlavors configuration

**Error: "Signing config not found"**
- Ensure `key.properties` file exists in `android/` directory
- Verify signing config in `build.gradle.kts`

### iOS Issues

**Error: "No scheme found"**
- Create schemes in Xcode as described above
- Ensure scheme names match: `dev`, `uat`, `Runner`

**Error: "Bundle identifier already in use"**
- Each flavor needs a unique bundle ID
- Check Build Settings in Xcode for Product Bundle Identifier

**Provisioning Profile Issues**
- Create separate provisioning profiles for each bundle ID
- Update them in Xcode's Signing & Capabilities tab

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build UAT and Dev

on:
  push:
    branches: [ develop, uat ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Build DEV APK
        run: ./build-flavors.sh android dev apk
      - name: Build UAT APK
        run: ./build-flavors.sh android uat apk
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: android-builds
          path: builds/android/

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Build DEV iOS
        run: ./build-flavors.sh ios dev ipa
      - name: Build UAT iOS
        run: ./build-flavors.sh ios uat ipa
```

## Quick Reference

### Build Commands
```bash
# Android
./build-flavors.sh android dev apk    # DEV APK
./build-flavors.sh android uat apk    # UAT APK
./build-flavors.sh android dev aab    # DEV AAB
./build-flavors.sh android uat aab    # UAT AAB

# iOS
./build-flavors.sh ios dev ipa        # DEV IPA
./build-flavors.sh ios uat ipa        # UAT IPA
```

### Run on Device
```bash
# Android
flutter run --release --flavor dev -t lib/main_dev.dart
flutter run --release --flavor uat -t lib/main_uat.dart

# iOS
flutter run --release --flavor dev -t lib/main_dev.dart
flutter run --release --flavor uat -t lib/main_uat.dart
```

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Verify all configuration files are correctly set up
3. Ensure all required dependencies are installed
4. Check Flutter and Dart SDK versions are up to date
