#!/bin/bash
set -e

echo "🏗️  Building DEV flavor AAB for Google Play Console..."
echo ""

# Build DEV AAB
echo "Building App Bundle with DEV configuration for Play Store..."
flutter build appbundle --release --flavor dev -t lib/main_dev.dart

echo ""
echo "✅ DEV App Bundle built successfully!"
echo "📦 AAB Location: build/app/outputs/bundle/devRelease/"
ls -lh build/app/outputs/bundle/devRelease/app-dev-release.aab
echo ""
echo "📤 To upload to Google Play Console:"
echo "  1. Go to https://play.google.com/console"
echo "  2. Select your app (or create new app for DEV track)"
echo "  3. Navigate to Release > Production/Testing"
echo "  4. Upload: build/app/outputs/bundle/devRelease/app-dev-release.aab"
echo ""
echo "⚠️  Note: The warning about debug symbols is non-fatal and can be ignored"
echo ""
echo "ℹ️  Package ID: com.techinorm.metafter.dev"
echo "ℹ️  App Name: Metafter DEV"
