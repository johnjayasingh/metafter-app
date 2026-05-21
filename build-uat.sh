#!/bin/bash
set -e

echo "🏗️  Building UAT flavor IPA..."
echo ""

# Temporarily modify Release configuration to use UAT bundle ID  
echo "Temporarily setting UAT bundle ID in Release configuration..."
cd ios/Flutter

# Backup original Release.xcconfig
cp Release.xcconfig Release.xcconfig.backup

# Copy standalone UAT configuration (doesn't include Release.xcconfig to avoid cycle)
cp Release-uat-standalone.xcconfig Release.xcconfig

cd ../..

# Build with standard flutter build ipa command
echo ""
echo "Building IPA with UAT configuration..."
flutter build ipa --release -t lib/main_uat.dart --export-options-plist=ios/ExportOptions-uat.plist

# Restore original Release.xcconfig
echo ""
echo "Restoring original Release configuration..."
cd ios/Flutter
mv Release.xcconfig.backup Release.xcconfig
cd ../..

echo ""
echo "✅ UAT IPA built successfully!"
echo "📦 IPA Location: build/ios/ipa/"
ls -lh build/ios/ipa/*.ipa
echo ""
echo "You can now distribute this IPA using:"
echo "  - Apple Transporter app"
echo "  - TestFlight"
echo "  - Direct installation on registered devices"

