#!/bin/bash
set -e

echo "🏗️  Building UAT flavor IPA for TestFlight..."
echo ""

# Temporarily modify Release configuration to use UAT bundle ID  
echo "Temporarily setting UAT bundle ID in Release configuration..."
cd ios/Flutter

# Backup original Release.xcconfig
cp Release.xcconfig Release.xcconfig.backup

# Copy standalone UAT configuration (doesn't include Release.xcconfig to avoid cycle)
cp Release-uat-standalone.xcconfig Release.xcconfig

cd ../..

# Build with standard flutter build ipa command for App Store/TestFlight
echo ""
echo "Building IPA with UAT configuration for TestFlight..."
flutter build ipa --release -t lib/main_uat.dart --export-options-plist=ios/ExportOptions-uat-testflight.plist

# Restore original Release.xcconfig
echo ""
echo "Restoring original Release configuration..."
cd ios/Flutter
mv Release.xcconfig.backup Release.xcconfig
cd ../..

echo ""
echo "✅ UAT TestFlight IPA built successfully!"
echo "📦 IPA Location: build/ios/ipa/"
ls -lh build/ios/ipa/*.ipa
echo ""
echo "📤 To upload to TestFlight:"
echo "  1. Open Apple Transporter app"
echo "  2. Drag and drop: build/ios/ipa/metafter.ipa"
echo "  3. Or use command: xcrun altool --upload-app --type ios -f build/ios/ipa/metafter.ipa --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
echo ""
echo "⚠️  Make sure you have created an app entry in App Store Connect for bundle ID: com.techinorm.metafter.uat"
