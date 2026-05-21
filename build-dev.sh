#!/bin/bash
set -e

echo "🏗️  Building DEV flavor IPA..."
echo ""

# Temporarily modify Release configuration to use DEV bundle ID  
echo "Temporarily setting DEV bundle ID in Release configuration..."
cd ios/Flutter

# Backup original Release.xcconfig
cp Release.xcconfig Release.xcconfig.backup

# Copy standalone DEV configuration (doesn't include Release.xcconfig to avoid cycle)
cp Release-dev-standalone.xcconfig Release.xcconfig

cd ../..

# Build with standard flutter build ipa command
echo ""
echo "Building IPA with DEV configuration..."
flutter build ipa --release -t lib/main_dev.dart --export-options-plist=ios/ExportOptions-dev.plist

# Restore original Release.xcconfig
echo ""
echo "Restoring original Release configuration..."
cd ios/Flutter
mv Release.xcconfig.backup Release.xcconfig
cd ../..

echo ""
echo "✅ DEV IPA built successfully!"
echo "📦 IPA Location: build/ios/ipa/"
ls -lh build/ios/ipa/*.ipa
echo ""
echo "You can now distribute this IPA using:"
echo "  - Apple Transporter app"
echo "  - TestFlight"
echo "  - Direct installation on registered devices"


echo ""
echo "✅ DEV IPA built successfully!"
echo "📦 Location: build/ios/ipa/"
echo "🆔 Bundle ID: com.nydco.digitalwill.dev"
echo "📱 Display Name: Will Cloud DEV"
