# Multi-Environment Build Configuration

This project supports separate builds for **DEV**, **UAT**, and **PRODUCTION** environments.

## 📖 Quick Start

### Android (Ready to Use)
```bash
# Build DEV APK
./build-flavors.sh android dev apk

# Build UAT APK
./build-flavors.sh android uat apk
```

### iOS (Setup Required)
1. Complete Xcode configuration: See [IOS_XCODE_SETUP.md](IOS_XCODE_SETUP.md)
2. Then build: `./build-flavors.sh ios dev ipa`

## 📚 Documentation

| File | Description |
|------|-------------|
| **[SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)** | ⭐ Start here - Complete setup guide with checklist |
| **[QUICK_START_BUILDS.md](QUICK_START_BUILDS.md)** | Quick reference for build commands |
| **[BUILD_FLAVORS_GUIDE.md](BUILD_FLAVORS_GUIDE.md)** | Comprehensive configuration guide |
| **[IOS_XCODE_SETUP.md](IOS_XCODE_SETUP.md)** | Step-by-step iOS Xcode setup |
| **[BUILD_ARCHITECTURE.md](BUILD_ARCHITECTURE.md)** | Visual architecture overview |
| **[BUILD_SETUP_SUMMARY.md](BUILD_SETUP_SUMMARY.md)** | What was configured |

## 🎯 What You Get

Three separate, installable apps:

| Environment | Package/Bundle ID | App Name | API |
|------------|-------------------|----------|-----|
| **DEV** | com.techinorm.metafter.dev | Metafter DEV | dev-api.yourcompany.com |
| **UAT** | com.techinorm.metafter.uat | Metafter UAT | uat-api.yourcompany.com |
| **PROD** | com.techinorm.metafter | Metafter | api.yourcompany.com |

✅ All three can be installed simultaneously on the same device!

## 🔧 Configuration

**Update API URLs** in `lib/core/config/environment_config.dart`:

```dart
case Environment.dev:
  return 'YOUR_DEV_API_URL';     // ← Update this
case Environment.uat:
  return 'YOUR_UAT_API_URL';     // ← Update this
case Environment.production:
  return 'YOUR_PROD_API_URL';    // ← Update this
```

## 📱 Distribution

### Android
- **Direct APK:** Share APK files from `builds/android/[environment]/`
- **Google Play:** Upload AAB files to internal testing track
- **Firebase:** Use Firebase App Distribution

### iOS
- **TestFlight:** Upload to App Store Connect (recommended)
- **Ad Hoc:** Create Ad Hoc provisioning profile and share IPA

## ⚙️ Project Structure

```
lib/
├── main.dart              # Production entry point
├── main_dev.dart          # DEV entry point  
├── main_uat.dart          # UAT entry point
└── core/
    └── config/
        └── environment_config.dart  # Environment configuration

android/
└── app/
    └── build.gradle.kts   # Product flavors configuration

ios/
├── Runner/
└── set_environment.sh     # iOS environment script
```

## 🚀 Build Commands

```bash
# Android
./build-flavors.sh android dev apk    # DEV APK
./build-flavors.sh android uat apk    # UAT APK
./build-flavors.sh android dev aab    # DEV AAB (Play Store)
./build-flavors.sh android uat aab    # UAT AAB (Play Store)

# iOS (after Xcode setup)
./build-flavors.sh ios dev ipa        # DEV IPA
./build-flavors.sh ios uat ipa        # UAT IPA

# Test on device
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor uat -t lib/main_uat.dart
```

## ✅ Next Steps

1. **Update API URLs** in `environment_config.dart`
2. **Test Android build:** `./build-flavors.sh android dev apk`
3. **Complete iOS setup:** Follow [IOS_XCODE_SETUP.md](IOS_XCODE_SETUP.md)
4. **Distribute to testers:** See [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)

## 🆘 Need Help?

- **Just starting?** → [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
- **Daily builds?** → [QUICK_START_BUILDS.md](QUICK_START_BUILDS.md)
- **iOS issues?** → [IOS_XCODE_SETUP.md](IOS_XCODE_SETUP.md)
- **Detailed info?** → [BUILD_FLAVORS_GUIDE.md](BUILD_FLAVORS_GUIDE.md)

---

**Status:**
- ✅ Android: Ready to build
- 🔧 iOS: Xcode setup required
- ⚙️ Configuration: Update API URLs
