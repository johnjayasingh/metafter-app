# Build Quick Reference

## Available Build Scripts

| Flavor | Distribution | Command | Output Size | Bundle ID |
|--------|-------------|---------|-------------|-----------|
| DEV | Development | `./build-dev.sh` | 20MB | com.techinorm.metafter.dev |
| DEV | TestFlight | `./build-dev-testflight.sh` | 32MB | com.techinorm.metafter.dev |
| UAT | Development | `./build-uat.sh` | 20MB | com.techinorm.metafter.uat |
| UAT | TestFlight | `./build-uat-testflight.sh` | 32MB | com.techinorm.metafter.uat |
| Production | App Store | `./build-appstore.sh` | 32MB | com.techinorm.metafter |

## Output Location
All builds output to: `build/ios/ipa/metafter.ipa`

## Verify Built IPA
```bash
unzip -p build/ios/ipa/metafter.ipa "Payload/Runner.app/Info.plist" | plutil -p - | grep -E "CFBundleIdentifier|CFBundleDisplayName"
```

## Upload to TestFlight
### Option 1: Apple Transporter (GUI)
1. Open Apple Transporter app
2. Drag and drop `build/ios/ipa/metafter.ipa`
3. Click "Deliver"

### Option 2: Command Line
```bash
xcrun altool --upload-app --type ios -f build/ios/ipa/metafter.ipa --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER
```

## Clean Build (if issues occur)
```bash
flutter clean
cd ios && pod install && ./restore-flavor-configs.sh && cd ..
```

## Build Verification Results

### DEV Build ✅
- Bundle ID: `com.techinorm.metafter.dev`
- Display Name: "Metafter DEV"
- Version: 1.0.3 (21)
- Status: Tested and working

### UAT Build ✅
- Bundle ID: `com.techinorm.metafter.uat`
- Display Name: "Metafter UAT"
- Version: 1.0.3 (21)
- Status: Tested and working

### Production Build
- Bundle ID: `com.techinorm.metafter`
- Display Name: "Metafter"
- Version: 1.0.3 (21)
- Status: Ready (not yet tested)
