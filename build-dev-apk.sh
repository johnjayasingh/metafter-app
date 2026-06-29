#!/bin/bash
set -e

echo "🏗️  Building DEV flavor APK for testing..."
echo ""

# Build DEV APK
echo "Building APK with DEV configuration..."
flutter build apk --release --flavor dev -t lib/main_dev.dart

echo ""
echo "✅ DEV APK built successfully!"
echo "📦 APK Location: build/app/outputs/flutter-apk/"
ls -lh build/app/outputs/flutter-apk/app-dev-release.apk
echo ""
echo "📱 To install on device:"
echo "  1. Connect your Android device via USB"
echo "  2. Enable USB debugging on your device"
echo "  3. Run: adb install build/app/outputs/flutter-apk/app-dev-release.apk"
echo ""
echo "📤 Or transfer the APK file to your device and install manually"
echo ""
echo "ℹ️  Package ID: com.techinorm.metafter.dev"
echo "ℹ️  App Name: Metafter DEV"
