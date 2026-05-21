# Setup Checklist for Multi-Environment Builds

Use this checklist to complete the setup and create your first builds.

## ✅ Setup Phase

### 1. Configuration Files ✅ DONE
- [x] Created `lib/main_dev.dart`
- [x] Created `lib/main_uat.dart`
- [x] Created `lib/core/config/environment_config.dart`
- [x] Modified `lib/main.dart` to use environment config
- [x] Updated `android/app/build.gradle.kts` with product flavors
- [x] Updated `android/app/src/main/AndroidManifest.xml` for dynamic app name
- [x] Created `build-flavors.sh` automation script
- [x] Created `ios/set_environment.sh` script

### 2. Update API URLs 🔧 TODO
Open `lib/core/config/environment_config.dart` and update:
- [ ] DEV API URL (line ~12): `return 'https://dev-api.yourcompany.com';`
- [ ] UAT API URL (line ~14): `return 'https://uat-api.yourcompany.com';`
- [ ] Production API URL (line ~16): `return 'https://api.yourcompany.com';`

### 3. Android Setup 🤖
- [x] Product flavors configured
- [x] Build script ready
- [ ] Test build: `./build-flavors.sh android dev apk`
- [ ] Verify APK created in `builds/android/dev/`
- [ ] Test install on device/emulator
- [ ] Verify app name shows "Will Cloud DEV"

### 4. iOS Setup 🍎
- [x] Environment script created
- [ ] Complete Xcode configuration (see `IOS_XCODE_SETUP.md`):
  - [ ] Open Xcode: `open ios/Runner.xcworkspace`
  - [ ] Create build configurations (Debug-dev, Release-dev, Debug-uat, Release-uat)
  - [ ] Duplicate Runner scheme to create "dev" scheme
  - [ ] Duplicate Runner scheme to create "uat" scheme
  - [ ] Set bundle IDs for each configuration
  - [ ] Add pre-action scripts to schemes
  - [ ] Configure signing & provisioning profiles
- [ ] Test build: `./build-flavors.sh ios dev ipa`
- [ ] Archive in Xcode
- [ ] Verify app name shows "Will Cloud DEV"

## 🧪 Testing Phase

### Android Testing
- [ ] Build DEV APK: `./build-flavors.sh android dev apk`
- [ ] Install DEV APK on test device
- [ ] Build UAT APK: `./build-flavors.sh android uat apk`
- [ ] Install UAT APK on same test device
- [ ] Verify both apps appear with different names
- [ ] Verify both apps can run simultaneously
- [ ] Check each connects to correct API endpoint

### iOS Testing
- [ ] Build DEV in Xcode with "dev" scheme
- [ ] Install DEV on test device
- [ ] Build UAT in Xcode with "uat" scheme
- [ ] Install UAT on same test device
- [ ] Verify both apps appear with different names
- [ ] Verify both apps can run simultaneously
- [ ] Check each connects to correct API endpoint

## 📤 Distribution Phase

### Prepare Distribution
- [ ] Choose distribution method:
  - [ ] Direct APK/IPA files (simplest)
  - [ ] Firebase App Distribution (recommended for teams)
  - [ ] TestFlight (iOS, professional)
  - [ ] Google Play Internal Testing (Android, professional)

### Android Distribution
**If using direct APK distribution:**
- [ ] Build release APKs:
  - [ ] `./build-flavors.sh android dev apk`
  - [ ] `./build-flavors.sh android uat apk`
- [ ] Upload APKs to shared location (Drive, Dropbox, etc.)
- [ ] Share links with testers
- [ ] Provide installation instructions

**If using Google Play:**
- [ ] Build AABs:
  - [ ] `./build-flavors.sh android dev aab`
  - [ ] `./build-flavors.sh android uat aab`
- [ ] Upload to Google Play Console
- [ ] Set up internal testing tracks
- [ ] Add tester emails

### iOS Distribution
**If using TestFlight:**
- [ ] Ensure you have Apple Developer account ($99/year)
- [ ] Create App Store Connect entries for each bundle ID
- [ ] Archive builds in Xcode
- [ ] Upload to App Store Connect
- [ ] Add testers in TestFlight
- [ ] Notify testers

**If using Ad Hoc:**
- [ ] Collect device UDIDs from testers
- [ ] Add devices to Apple Developer Portal
- [ ] Create Ad Hoc provisioning profiles
- [ ] Archive and export Ad Hoc builds
- [ ] Share IPA files with testers

## 📋 Tester Instructions

### Android Testers
Send testers these instructions:

```
1. Download the APK file
2. On your Android device, go to Settings > Security
3. Enable "Install from Unknown Sources" or "Install Unknown Apps"
4. Open the downloaded APK file
5. Tap "Install"
6. Look for "Will Cloud DEV" or "Will Cloud UAT" on your home screen
```

### iOS Testers
**For TestFlight:**
```
1. Install TestFlight from the App Store
2. Accept the email invitation
3. Open TestFlight
4. Install "Will Cloud DEV" or "Will Cloud UAT"
```

**For Ad Hoc:**
```
1. Download and install Apple Configurator 2 (Mac) or use Xcode
2. Connect your device
3. Install the IPA file through the tool
```

## 🔍 Verification

### Build Verification
- [ ] DEV and UAT apps have different names on device
- [ ] DEV and UAT apps have different icons (if configured)
- [ ] Both apps can be installed simultaneously
- [ ] Each app connects to its respective API endpoint
- [ ] App versions are displayed correctly
- [ ] Environment indicators are visible

### Tester Feedback
- [ ] Testers can download builds
- [ ] Testers can install builds successfully
- [ ] Testers can distinguish between DEV and UAT
- [ ] No conflicts between different builds
- [ ] All core features work in both environments

## 🎯 Quick Commands Reference

```bash
# Android
./build-flavors.sh android dev apk   # DEV APK
./build-flavors.sh android uat apk   # UAT APK
./build-flavors.sh android dev aab   # DEV AAB (Play Store)
./build-flavors.sh android uat aab   # UAT AAB (Play Store)

# iOS
./build-flavors.sh ios dev ipa       # DEV (then archive in Xcode)
./build-flavors.sh ios uat ipa       # UAT (then archive in Xcode)

# Test on device
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor uat -t lib/main_uat.dart
```

## 📚 Documentation Reference

| Document | Use When |
|----------|----------|
| `BUILD_SETUP_SUMMARY.md` | Overview of what was set up |
| `QUICK_START_BUILDS.md` | Daily build commands |
| `BUILD_FLAVORS_GUIDE.md` | Detailed configuration reference |
| `IOS_XCODE_SETUP.md` | iOS Xcode configuration |
| `BUILD_ARCHITECTURE.md` | Understanding the architecture |
| This checklist | Step-by-step setup and distribution |

## 🆘 Troubleshooting

### Issue: Build fails with "No flavor found"
**Solution:** 
```bash
flutter clean
flutter pub get
./build-flavors.sh android dev apk
```

### Issue: iOS scheme not found
**Solution:** Complete the Xcode setup in `IOS_XCODE_SETUP.md`

### Issue: Apps overwrite each other
**Solution:** Verify package/bundle IDs are different:
- Android: Check `android/app/build.gradle.kts`
- iOS: Check Build Settings > Product Bundle Identifier in Xcode

### Issue: Wrong API endpoint
**Solution:** Update `lib/core/config/environment_config.dart`

### Issue: Can't distribute to testers
**Solution:** Choose simpler distribution method:
- Android: Direct APK file sharing
- iOS: TestFlight (requires Apple Developer account)

## ✨ Success Criteria

You're done when:
- ✅ You can build DEV and UAT for Android
- ✅ You can build DEV and UAT for iOS
- ✅ Both builds can be installed simultaneously
- ✅ Each connects to the correct API
- ✅ Testers can receive and install builds
- ✅ Apps are clearly identifiable

## 🎉 Next Steps After Setup

Once everything is working:
1. Set up automated builds (CI/CD) - see `BUILD_FLAVORS_GUIDE.md`
2. Consider different app icons for each environment
3. Add crash reporting with environment tags
4. Set up beta testing programs
5. Document your release process

---

**Need Help?** Refer to the detailed guides in this directory.
