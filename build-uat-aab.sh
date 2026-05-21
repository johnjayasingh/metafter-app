#!/bin/bash
set -e

echo "🏗️  Building UAT flavor AAB for Google Play Console..."
echo ""

# Build UAT AAB
echo "Building App Bundle with UAT configuration for Play Store..."
flutter build appbundle --release --flavor uat -t lib/main_uat.dart

echo ""
echo "✅ UAT App Bundle built successfully!"
echo "📦 AAB Location: build/app/outputs/bundle/uatRelease/"
ls -lh build/app/outputs/bundle/uatRelease/app-uat-release.aab
echo ""
echo "📤 To upload to Google Play Console:"
echo "  1. Go to https://play.google.com/console"
echo "  2. Select your app (or create new app for UAT track)"
echo "  3. Navigate to Release > Production/Testing"
echo "  4. Upload: build/app/outputs/bundle/uatRelease/app-uat-release.aab"
echo ""
echo "⚠️  Note: The warning about debug symbols is non-fatal and can be ignored"
echo ""
echo "ℹ️  Package ID: com.nydsystems.digitalwill.uat"
echo "ℹ️  App Name: Will Cloud UAT"
