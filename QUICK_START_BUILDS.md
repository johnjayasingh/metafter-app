# Quick Start: Building UAT and Dev Releases

## Prerequisites
- Flutter SDK installed and configured
- Android Studio (for Android builds)
- Xcode (for iOS builds - macOS only)
- Signing certificates configured (key.properties for Android, Apple Developer account for iOS)

## 🚀 Quick Build Commands

### Android Builds

```bash
# DEV APK (for direct installation)
./build-flavors.sh android dev apk

# UAT APK (for direct installation)
./build-flavors.sh android uat apk

# DEV AAB (for Google Play)
./build-flavors.sh android dev aab

# UAT AAB (for Google Play)
./build-flavors.sh android uat aab
```

**Output Location:** `builds/android/[environment]/`

### iOS Builds

```bash
# DEV
./build-flavors.sh ios dev ipa

# UAT
./build-flavors.sh ios uat ipa
```

⚠️ **Note:** iOS builds require Xcode to create IPA files. After running the command, follow the Xcode archive steps shown in the terminal.

## 📱 What Gets Built

### DEV Environment
- **App Name:** "Metafter DEV"
- **Android Package:** `com.techinorm.metafter.dev`
- **iOS Bundle ID:** `com.techinorm.metafter.dev`
- **API Endpoint:** (configured in environment_config.dart)
- **Debug Banner:** Visible

### UAT Environment
- **App Name:** "Metafter UAT"
- **Android Package:** `com.techinorm.metafter.uat`
- **iOS Bundle ID:** `com.techinorm.metafter.uat`
- **API Endpoint:** (configured in environment_config.dart)
- **Debug Banner:** Visible

## 📤 Distributing to Testers

### Android
1. Navigate to `builds/android/[environment]/`
2. Share the APK file with testers via:
   - Email
   - Cloud storage (Google Drive, Dropbox)
   - Firebase App Distribution
   - Google Play Internal Testing

### iOS
1. Archive in Xcode: `open ios/Runner.xcworkspace`
2. Select the appropriate scheme (dev or uat)
3. Product → Archive
4. Distribute via:
   - TestFlight (recommended)
   - Ad Hoc distribution

## ⚙️ Configuration

### Update API URLs
Edit `lib/core/config/environment_config.dart`:

```dart
static String get baseUrl {
  switch (_environment) {
    case Environment.dev:
      return 'YOUR_DEV_API_URL';      // ← Update
    case Environment.uat:
      return 'YOUR_UAT_API_URL';      // ← Update
    case Environment.production:
      return 'YOUR_PRODUCTION_API_URL'; // ← Update
  }
}
```

## 🧪 Testing Locally

```bash
# Run DEV on connected device/emulator
flutter run --flavor dev -t lib/main_dev.dart

# Run UAT on connected device/emulator
flutter run --flavor uat -t lib/main_uat.dart
```

## 📚 Need More Details?

See [BUILD_FLAVORS_GUIDE.md](BUILD_FLAVORS_GUIDE.md) for:
- Detailed iOS Xcode setup
- Troubleshooting guide
- CI/CD integration
- Advanced configuration options

## ✅ Verification Checklist

Before distributing builds:
- [ ] API URLs are correctly configured
- [ ] Signing certificates are set up
- [ ] App names clearly identify the environment
- [ ] Builds install successfully on test device
- [ ] Can differentiate between DEV and UAT apps on the same device

## 🆘 Common Issues

### "No flavor found"
Run: `flutter clean && flutter pub get`

### iOS scheme not found
Complete the Xcode configuration steps in BUILD_FLAVORS_GUIDE.md

### Signing errors
- Android: Check `android/key.properties` exists and is configured
- iOS: Verify provisioning profiles in Xcode

---

**Quick Test:** After building, both DEV and UAT versions can be installed simultaneously on the same device!
