#!/bin/bash

echo "🏗️  Building LOCAL flavor APK with debug pre-fill..."

# Build the APK
flutter build apk --release --flavor local -t lib/main_local.dart

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ LOCAL APK built successfully!"
    echo "📦 APK Location: build/app/outputs/flutter-apk/"
    echo ""
    ls -lh build/app/outputs/flutter-apk/app-local-release.apk
    echo ""
    echo "ℹ️  Package ID: com.techinorm.metafter.local"
    echo "ℹ️  App Name: Metafter LOCAL"
    echo "ℹ️  Debug Pre-fill: ENABLED"
    echo "ℹ️  API: http://13.54.59.56:8000 (DEV)"
    echo ""
    echo "📱 To install on device:"
    echo "   adb install build/app/outputs/flutter-apk/app-local-release.apk"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
