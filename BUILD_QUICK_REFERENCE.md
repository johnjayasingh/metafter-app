# Build Quick Reference

## Available Build Scripts

| Flavor | Distribution | Command | Output Size | Bundle ID |
|--------|-------------|---------|-------------|-----------|
| DEV | Development | `./build-dev.sh` | 20MB | com.nydco.digitalwill.dev |
| DEV | TestFlight | `./build-dev-testflight.sh` | 32MB | com.nydco.digitalwill.dev |
| UAT | Development | `./build-uat.sh` | 20MB | com.nydco.digitalwill.uat |
| UAT | TestFlight | `./build-uat-testflight.sh` | 32MB | com.nydco.digitalwill.uat |
| Production | App Store | `./build-appstore.sh` | 32MB | com.nydco.digitalwill |

## Output Location
All builds output to: `build/ios/ipa/digitalwill.ipa`

## Verify Built IPA
```bash
unzip -p build/ios/ipa/digitalwill.ipa "Payload/Runner.app/Info.plist" | plutil -p - | grep -E "CFBundleIdentifier|CFBundleDisplayName"
```

## Upload to TestFlight
### Option 1: Apple Transporter (GUI)
1. Open Apple Transporter app
2. Drag and drop `build/ios/ipa/digitalwill.ipa`
3. Click "Deliver"

### Option 2: Command Line
```bash
xcrun altool --upload-app --type ios -f build/ios/ipa/digitalwill.ipa --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER
```

## Clean Build (if issues occur)
```bash
flutter clean
cd ios && pod install && ./restore-flavor-configs.sh && cd ..
```

## Build Verification Results

### DEV Build ✅
- Bundle ID: `com.nydco.digitalwill.dev`
- Display Name: "Will Cloud DEV"
- Version: 1.0.3 (21)
- Status: Tested and working

### UAT Build ✅
- Bundle ID: `com.nydco.digitalwill.uat`
- Display Name: "Will Cloud UAT"
- Version: 1.0.3 (21)
- Status: Tested and working

### Production Build
- Bundle ID: `com.nydco.digitalwill`
- Display Name: "Will Cloud"
- Version: 1.0.3 (21)
- Status: Ready (not yet tested)
