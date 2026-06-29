#!/bin/bash
set -e

echo "🏗️  Building UAT flavor APK for testing..."
echo ""

# Build UAT APK
echo "Building APK with UAT configuration..."
flutter build apk --release --flavor uat -t lib/main_uat.dart

echo ""
echo "✅ UAT APK built successfully!"
echo "📦 APK Location: build/app/outputs/flutter-apk/"
ls -lh build/app/outputs/flutter-apk/app-uat-release.apk
echo ""
echo "📱 To install on device:"
echo "  1. Connect your Android device via USB"
echo "  2. Enable USB debugging on your device"
echo "  3. Run: adb install build/app/outputs/flutter-apk/app-uat-release.apk"
echo ""
echo "📤 Or transfer the APK file to your device and install manually"
echo ""
echo "ℹ️  Package ID: com.techinorm.metafter.uat"
echo "ℹ️  App Name: Metafter UAT"
