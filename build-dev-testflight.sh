#!/bin/bash
set -e

echo "🏗️  Building DEV flavor for TestFlight..."
echo ""

# Temporarily modify Release configuration to use DEV bundle ID  
echo "Setting DEV bundle ID in Release configuration..."
cd ios/Flutter

# Backup original Release.xcconfig
cp Release.xcconfig Release.xcconfig.backup

# Copy standalone DEV configuration
cp Release-dev-standalone.xcconfig Release.xcconfig

cd ../..

# Build with standard flutter build ipa command for App Store/TestFlight
echo ""
echo "Building IPA for TestFlight distribution..."
flutter build ipa --release -t lib/main_dev.dart --export-options-plist=ios/ExportOptions-dev-testflight.plist

# Restore original Release.xcconfig
echo ""
echo "Restoring original Release configuration..."
cd ios/Flutter
mv Release.xcconfig.backup Release.xcconfig
cd ../..

echo ""
echo "✅ DEV TestFlight IPA built successfully!"
echo "📦 IPA Location: build/ios/ipa/"
ls -lh build/ios/ipa/*.ipa
echo ""
echo "📋 Upload to TestFlight:"
echo "  1. Open Apple Transporter app"
echo "  2. Sign in with your Apple ID"
echo "  3. Select build/ios/ipa/metafter.ipa"
echo "  4. Click 'Deliver' to upload"
echo ""
echo "After upload:"
echo "  • Processing takes 15-30 minutes"
echo "  • Build appears in TestFlight automatically"
echo "  • Add internal/external testers in App Store Connect"
echo ""
echo "⚠️  Note: This is the DEV flavor with bundle ID: com.techinorm.metafter.dev"
echo "    Make sure you have this App ID registered in Apple Developer Portal"
