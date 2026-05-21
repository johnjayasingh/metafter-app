# Android Build Scripts

## Overview
Convenient shell scripts for building Android APKs and AABs (App Bundles) for all environments (DEV, UAT, Production).

## Available Scripts

### DEV Environment

#### 1. `build-dev-apk.sh` - DEV APK for Testing
Builds a DEV APK that can be installed directly on devices for testing.

**Usage:**
```bash
./build-dev-apk.sh
```

**Output:**
- File: `build/app/outputs/flutter-apk/app-dev-release.apk` (38.5MB)
- Package ID: `com.nydsystems.digitalwill.dev`
- App Name: "Will Cloud DEV"

**Installation:**
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-dev-release.apk

# Or transfer APK to device and install manually
```

#### 2. `build-dev-aab.sh` - DEV AAB for Google Play
Builds a DEV App Bundle for uploading to Google Play Console (Internal/Alpha/Beta testing tracks).

**Usage:**
```bash
./build-dev-aab.sh
```

**Output:**
- File: `build/app/outputs/bundle/devRelease/app-dev-release.aab` (55MB)
- Package ID: `com.nydsystems.digitalwill.dev`
- App Name: "Will Cloud DEV"

**Upload to Play Console:**
1. Go to https://play.google.com/console
2. Create/select DEV app
3. Navigate to Release → Testing → Internal/Alpha/Beta
4. Upload the AAB file

---

### UAT Environment

#### 3. `build-uat-apk.sh` - UAT APK for Testing
Builds a UAT APK for user acceptance testing on devices.

**Usage:**
```bash
./build-uat-apk.sh
```

**Output:**
- File: `build/app/outputs/flutter-apk/app-uat-release.apk` (38.5MB)
- Package ID: `com.nydsystems.digitalwill.uat`
- App Name: "Will Cloud UAT"

**Installation:**
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-uat-release.apk

# Or transfer APK to device and install manually
```

#### 4. `build-uat-aab.sh` - UAT AAB for Google Play
Builds a UAT App Bundle for uploading to Google Play Console testing tracks.

**Usage:**
```bash
./build-uat-aab.sh
```

**Output:**
- File: `build/app/outputs/bundle/uatRelease/app-uat-release.aab` (55MB)
- Package ID: `com.nydsystems.digitalwill.uat`
- App Name: "Will Cloud UAT"

**Upload to Play Console:**
1. Go to https://play.google.com/console
2. Create/select UAT app
3. Navigate to Release → Testing → Internal/Alpha/Beta
4. Upload the AAB file

---

### Production Environment

#### 5. `build-prod-apk.sh` - Production APK
Builds a Production APK for final testing before Play Store release.

**Usage:**
```bash
./build-prod-apk.sh
```

**Output:**
- File: `build/app/outputs/flutter-apk/app-prod-release.apk` (38.5MB)
- Package ID: `com.nydsystems.digitalwill`
- App Name: "Will Cloud"

**Installation:**
```bash
# Via ADB (for final testing only)
adb install build/app/outputs/flutter-apk/app-prod-release.apk
```

#### 6. `build-prod-aab.sh` - Production AAB for Play Store
Builds the Production App Bundle for uploading to Google Play Console Production track.

**Usage:**
```bash
./build-prod-aab.sh
```

**Output:**
- File: `build/app/outputs/bundle/prodRelease/app-prod-release.aab` (55MB)
- Package ID: `com.nydsystems.digitalwill`
- App Name: "Will Cloud"

**Upload to Play Console:**
1. Go to https://play.google.com/console
2. Select your production app
3. Navigate to Release → Production
4. Upload the AAB file

---

## Quick Reference

| Script | Environment | Type | Output Size | Use Case |
|--------|-------------|------|-------------|----------|
| `build-dev-apk.sh` | DEV | APK | 38.5MB | Direct device testing |
| `build-dev-aab.sh` | DEV | AAB | 55MB | Play Console internal testing |
| `build-uat-apk.sh` | UAT | APK | 38.5MB | UAT device testing |
| `build-uat-aab.sh` | UAT | AAB | 55MB | Play Console UAT testing |
| `build-prod-apk.sh` | Production | APK | 38.5MB | Final device testing |
| `build-prod-aab.sh` | Production | AAB | 55MB | Play Store production release |

## APK vs AAB

### APK (Android Package)
- ✅ Can be installed directly on devices
- ✅ Good for quick testing and sharing with testers
- ✅ Works without Google Play
- ❌ Larger file size (contains all resources for all device types)
- ❌ Cannot be uploaded to Play Store production (AAB required)

### AAB (Android App Bundle)
- ✅ Smaller download size for users (Play Store optimizes per device)
- ✅ Required for Play Store uploads
- ✅ Better for production distribution
- ❌ Cannot be installed directly on devices
- ❌ Requires Google Play Console for distribution

## Environment Display

All builds include environment badges:

- **DEV builds**: Orange "DEV BUILD" banner on login screen
- **UAT builds**: Blue "UAT BUILD" banner on login screen
- **Production builds**: Clean UI (no banner)

Each badge shows:
- Environment name (DEV/UAT)
- Version number (e.g., v1.0.3)
- Build number (e.g., 21)

## Common Issues

### 1. Debug Symbols Warning
When building AAB, you may see:
```
Release app bundle failed to strip debug symbols from native libraries.
```

**Solution**: This is non-fatal and can be ignored. The AAB is built successfully and is valid for upload.

### 2. Gradle Build Errors
If builds fail, try:
```bash
flutter clean
flutter pub get
./build-dev-apk.sh  # or whichever script you need
```

### 3. ADB Not Found
If `adb install` doesn't work:
```bash
# Check if ADB is available
which adb

# If not, install Android SDK Platform Tools
# Or use Android Studio's ADB: ~/Library/Android/sdk/platform-tools/adb
```

## Build Time Estimates

| Build Type | Clean Build | Incremental Build |
|------------|-------------|-------------------|
| APK | 40-60 seconds | 5-10 seconds |
| AAB | 15-20 seconds | 5-10 seconds |

*Note: AAB builds are faster because they reuse compiled artifacts from previous APK builds.*

## Comparison with iOS Scripts

### iOS Scripts
- [build-dev-testflight.sh](build-dev-testflight.sh) - DEV TestFlight IPA (34MB)
- [build-uat-testflight.sh](build-uat-testflight.sh) - UAT TestFlight IPA (34MB)
- [build-appstore.sh](build-appstore.sh) - Production App Store IPA

### Android Scripts (New)
- `build-dev-apk.sh` / `build-dev-aab.sh` - DEV builds
- `build-uat-apk.sh` / `build-uat-aab.sh` - UAT builds
- `build-prod-apk.sh` / `build-prod-aab.sh` - Production builds

## Distribution Workflow

### Internal Testing (DEV)
1. Build: `./build-dev-apk.sh` or `./build-dev-aab.sh`
2. For APK: Share file or install via ADB
3. For AAB: Upload to Play Console → Internal Testing

### User Acceptance Testing (UAT)
1. Build: `./build-uat-apk.sh` or `./build-uat-aab.sh`
2. For APK: Share with UAT testers
3. For AAB: Upload to Play Console → Closed Testing (Alpha/Beta)

### Production Release
1. Build: `./build-prod-aab.sh` (AAB required for production)
2. Upload to Play Console → Production
3. Google Play optimizes and distributes to users

## Tips

1. **Use APK for quick testing**: Faster to build and install directly
2. **Use AAB for distribution**: Required for Play Store, smaller for users
3. **Test locally first**: Use APK to test on your device before uploading AAB
4. **Keep both environments**: DEV and UAT can coexist on same device (different package IDs)
5. **Version management**: Update version in `pubspec.yaml` before building

## Next Steps

After building:

1. **For APKs**: Test on multiple devices with different screen sizes and Android versions
2. **For AABs**: Upload to Play Console and use internal testing to verify
3. **Monitor crashes**: Check Play Console for crash reports
4. **Update regularly**: Increment version numbers for each release

## Related Documentation

- [ENVIRONMENT_API_SETUP.md](ENVIRONMENT_API_SETUP.md) - API endpoint configuration
- [ENVIRONMENT_DISPLAY_SETUP.md](ENVIRONMENT_DISPLAY_SETUP.md) - Environment badge setup
- [BUILD_FLAVORS_GUIDE.md](BUILD_FLAVORS_GUIDE.md) - Complete flavor configuration guide
