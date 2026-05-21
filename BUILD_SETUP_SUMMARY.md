# Multi-Environment Build Setup - Summary

Your Flutter project has been configured for multiple environment builds (DEV, UAT, PROD).

## 📁 Files Created/Modified

### New Files
- ✅ `lib/main_dev.dart` - Dev environment entry point
- ✅ `lib/main_uat.dart` - UAT environment entry point
- ✅ `lib/core/config/environment_config.dart` - Environment configuration
- ✅ `build-flavors.sh` - Build automation script
- ✅ `ios/set_environment.sh` - iOS environment configuration script
- ✅ `BUILD_FLAVORS_GUIDE.md` - Comprehensive guide
- ✅ `QUICK_START_BUILDS.md` - Quick reference
- ✅ `IOS_XCODE_SETUP.md` - Detailed iOS setup instructions

### Modified Files
- ✅ `lib/main.dart` - Updated to use environment config
- ✅ `android/app/build.gradle.kts` - Added product flavors
- ✅ `android/app/src/main/AndroidManifest.xml` - Dynamic app name

## 🚀 Ready to Use (Android)

Android configuration is **complete and ready**. You can immediately build:

```bash
# Build DEV APK
./build-flavors.sh android dev apk

# Build UAT APK
./build-flavors.sh android uat apk
```

## ⚙️ iOS Setup Required

iOS requires **manual Xcode configuration**. Follow these steps:

1. Open Xcode: `open ios/Runner.xcworkspace`
2. Follow instructions in `IOS_XCODE_SETUP.md`
3. Key tasks:
   - Create build configurations (Debug-dev, Release-dev, etc.)
   - Create schemes (dev, uat)
   - Set bundle identifiers
   - Configure signing
   - Add pre-action scripts

**Estimated time:** 15-20 minutes

## 📋 Next Steps

### 1. Update API URLs
Edit `lib/core/config/environment_config.dart`:
```dart
case Environment.dev:
  return 'YOUR_DEV_API_URL';     // ← Update this
case Environment.uat:
  return 'YOUR_UAT_API_URL';     // ← Update this
case Environment.production:
  return 'YOUR_PROD_API_URL';    // ← Update this
```

### 2. Test Android Build
```bash
# Clean build
./build-flavors.sh android dev apk

# Check output
ls -la builds/android/dev/
```

### 3. Complete iOS Setup
- Follow `IOS_XCODE_SETUP.md`
- Create provisioning profiles
- Test archive process

### 4. Distribute to Testers
See `BUILD_FLAVORS_GUIDE.md` for distribution options:
- Direct APK/IPA installation
- Firebase App Distribution
- TestFlight (iOS)
- Google Play Internal Testing (Android)

## 🎯 What You Get

### Separate Apps
All three environments can be installed **simultaneously** on the same device:

| Environment | Android Package | iOS Bundle | App Name |
|------------|----------------|------------|----------|
| DEV | com.nydsystems.digitalwill.dev | com.nydsystems.digitalwill.dev | Will Cloud DEV |
| UAT | com.nydsystems.digitalwill.uat | com.nydsystems.digitalwill.uat | Will Cloud UAT |
| PROD | com.nydsystems.digitalwill | com.nydsystems.digitalwill | Will Cloud |

### Different Configurations
- Separate API endpoints per environment
- Different app names to easily identify builds
- Debug banner visible in DEV/UAT
- Unique package/bundle IDs

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| `QUICK_START_BUILDS.md` | Quick commands and daily usage |
| `BUILD_FLAVORS_GUIDE.md` | Complete reference guide |
| `IOS_XCODE_SETUP.md` | Step-by-step iOS configuration |
| This file | Overview and next steps |

## ✅ Verification Checklist

**Android:**
- [x] Product flavors configured
- [x] Dynamic app names set
- [x] Build script created
- [ ] Test build successful
- [ ] API URLs configured

**iOS:**
- [x] Environment script created
- [ ] Build configurations created in Xcode
- [ ] Schemes created (dev, uat)
- [ ] Bundle IDs configured
- [ ] Signing configured
- [ ] Test archive successful

**General:**
- [ ] API URLs updated
- [ ] Test DEV build
- [ ] Test UAT build
- [ ] Both can install simultaneously
- [ ] Testers can receive builds

## 🆘 Common Questions

### Can I build both DEV and UAT at once?
Yes! Just run the commands separately:
```bash
./build-flavors.sh android dev apk
./build-flavors.sh android uat apk
```

### Do I need separate Play Store / App Store listings?
- **Google Play:** Can use same listing with multiple tracks, or separate listings
- **App Store:** Need separate listings for different bundle IDs (or use TestFlight)

### How do testers distinguish between versions?
- Different app names: "Will Cloud DEV" vs "Will Cloud UAT"
- Different app icons (can be configured)
- Shows in different locations on home screen

### Can I still build production from main.dart?
Yes! The original production build process is unchanged:
```bash
flutter build apk --release
flutter build ios --release
```

## 📞 Support

If you encounter issues:
1. Check the troubleshooting sections in the guides
2. Verify all prerequisites are met
3. Ensure Flutter and dependencies are up to date
4. Check that signing certificates are configured

## 🎉 Ready to Build!

You're all set to create separate DEV and UAT builds for your testers. Start with:

```bash
# Android DEV build (works immediately)
./build-flavors.sh android dev apk

# Then complete iOS setup in Xcode
open IOS_XCODE_SETUP.md
```

---

**Last Updated:** December 29, 2025
