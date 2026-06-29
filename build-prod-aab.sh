#!/bin/bash
set -e

echo "🏗️  Building Production flavor AAB for Google Play Console..."
echo ""

# Build Production AAB
echo "Building App Bundle with Production configuration for Play Store..."
flutter build appbundle --release --flavor prod -t lib/main.dart

echo ""
echo "✅ Production App Bundle built successfully!"
echo "📦 AAB Location: build/app/outputs/bundle/prodRelease/"
ls -lh build/app/outputs/bundle/prodRelease/app-prod-release.aab
echo ""
echo "📤 To upload to Google Play Console:"
echo "  1. Go to https://play.google.com/console"
echo "  2. Select your app"
echo "  3. Navigate to Release > Production"
echo "  4. Upload: build/app/outputs/bundle/prodRelease/app-prod-release.aab"
echo ""
echo "⚠️  Note: The warning about debug symbols is non-fatal and can be ignored"
echo ""
echo "ℹ️  Package ID: com.techinorm.metafter"
echo "ℹ️  App Name: Metafter"
