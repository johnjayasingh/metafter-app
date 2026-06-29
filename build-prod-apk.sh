#!/bin/bash
set -e

echo "🏗️  Building Production flavor APK for testing..."
echo ""

# Build Production APK
echo "Building APK with Production configuration..."
flutter build apk --release --flavor prod -t lib/main.dart

echo ""
echo "✅ Production APK built successfully!"
echo "📦 APK Location: build/app/outputs/flutter-apk/"
ls -lh build/app/outputs/flutter-apk/app-prod-release.apk
echo ""
echo "📱 To install on device:"
echo "  1. Connect your Android device via USB"
echo "  2. Enable USB debugging on your device"
echo "  3. Run: adb install build/app/outputs/flutter-apk/app-prod-release.apk"
echo ""
echo "📤 Or transfer the APK file to your device and install manually"
echo ""
echo "ℹ️  Package ID: com.techinorm.metafter"
echo "ℹ️  App Name: Metafter"
