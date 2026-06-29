# Build Instructions for Digital Will

## Configuration Summary

The app now has proper support for multiple build flavors with different bundle IDs and display names:

### Production
- **Bundle ID:** `com.techinorm.metafter`
- **Display Name:** "Metafter"
- **Entry Point:** `lib/main.dart`
- **Configurations:** Debug, Release, Profile

### Development (DEV)
- **Bundle ID:** `com.techinorm.metafter.dev`
- **Display Name:** "Metafter DEV"
- **Entry Point:** `lib/main_dev.dart`
- **Configurations:** Debug-dev, Release-dev

### UAT
- **Bundle ID:** `com.techinorm.metafter.uat`
- **Display Name:** "Metafter UAT"  
- **Entry Point:** `lib/main_uat.dart`
- **Configurations:** Debug-uat, Release-uat

## Building

### Option 1: Using Build Scripts (Recommended)

#### Development/Ad-hoc Distribution (Direct Installation)
```bash
# Build DEV IPA (~20MB)
./build-dev.sh

# Build UAT IPA (~20MB)
./build-uat.sh

# Build Production IPA (~20MB)
./build-release.sh
```

#### TestFlight/App Store Distribution
```bash
# Build DEV for TestFlight (~32MB)
./build-dev-testflight.sh

# Build UAT for TestFlight (~32MB)
./build-uat-testflight.sh

# Build Production for App Store (~32MB)
./build-appstore.sh
```

**Note:** All IPAs are output to `build/ios/ipa/metafter.ipa`

### Option 2: Using Xcode Directly

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the desired configuration from Product > Scheme > Edit Scheme > Run > Build Configuration
   - Choose `Release-dev` for DEV builds
   - Choose `Release-uat` for UAT builds
   - Choose `Release` for Production builds
3. Product > Archive
4. Distribute App

### Option 3: Manual xcodebuild

```bash
# DEV Build
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release-dev \
  -sdk iphoneos \
  -archivePath build/ios/archive/Runner.xcarchive \
  archive \
  DEVELOPMENT_TEAM=3PD9L8BPP4

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist
```

## Upload to TestFlight

### Method 1: Apple Transporter (Recommended)
1. Open Apple Transporter app (download from Mac App Store if needed)
2. Drag and drop `build/ios/ipa/metafter.ipa` into the app
3. Click "Deliver" to upload to App Store Connect
4. Wait 15-30 minutes for Apple to process the build
5. Go to App Store Connect → TestFlight to add testers

### Method 2: Command Line
4. **Verifying Built IPA** - To check that the IPA has correct bundle ID and display name:

```bash
unzip -p build/ios/ipa/metafter.ipa "Payload/Runner.app/Info.plist" | plutil -p - | grep -E "CFBundleIdentifier|CFBundleDisplayName"
```

Should output for DEV:
```
"CFBundleDisplayName" => "Metafter DEV"
"CFBundleIdentifier" => "com.techinorm.metafter.dev"
```

Should output for UAT:
```
"CFBundleDisplayName" => "Metafter UAT"
"CFBundleIdentifier" => "com.techinorm.metafter.uat"
```bash
cd ios && ./restore-flavor-configs.sh
```

3. **App Store Connect** - Each flavor (DEV, UAT, Production) needs its own app entry in App Store Connect with matching bundle ID for TestFlight distribution.

3. **Verifying Configuration** - To check that settings are correct before building:

```bash
cd ios && xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release-dev \
  -showBuildSettings | grep -E "PRODUCT_BUNDLE_IDENTIFIER|DISPLAY_NAME"
```

Should output:
```
DISPLAY_NAME = Metafter DEV
PRODUCT_BUNDLE_IDENTIFIER = com.techinorm.metafter.dev
```

## Troubleshooting

**Issue:** Build fails with configuration errors  
**Solution:** 
1. Clean build folder: `flutter clean`
2. Update pods: `cd ios && pod install && cd ..`
3. Restore flavor configs: `cd ios && ./restore-flavor-configs.sh && cd ..`
4. Try build again

**Issue:** Wrong bundle ID or display name in IPA  
**Solution:** Verify the standalone xcconfig files exist:
- `ios/Flutter/Release-dev-standalone.xcconfig`
- `ios/Flutter/Release-uat-standalone.xcconfig`

**Issue:** Upload to App Store Connect fails  
**Solution:** 
1. Verify bundle ID is registered in Apple Developer Portal
2. Ensure app entry exists in App Store Connect for that bundle ID
3. Check that provisioning profile includes development team 3PD9L8BPP4

**Issue:** TestFlight build rejected  
**Solution:** Use the TestFlight-specific build scripts (`build-dev-testflight.sh`, `build-uat-testflight.sh`) instead of the development build scripts.
