#!/bin/bash

echo "🏗️  Building LOCAL flavor AAB with debug pre-fill..."

# Build the AAB
flutter build appbundle --release --flavor local -t lib/main_local.dart

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ LOCAL AAB built successfully!"
    echo "📦 AAB Location: build/app/outputs/bundle/localRelease/"
    echo ""
    ls -lh build/app/outputs/bundle/localRelease/app-local-release.aab
    echo ""
    echo "ℹ️  Package ID: com.nydsystems.digitalwill.local"
    echo "ℹ️  App Name: Will Cloud LOCAL"
    echo "ℹ️  Debug Pre-fill: ENABLED"
    echo "ℹ️  API: http://13.54.59.56:8000 (DEV)"
    echo ""
    echo "📤 To upload to Play Console:"
    echo "   1. Go to play.google.com/console"
    echo "   2. Select your app"
    echo "   3. Internal testing → Create release"
    echo "   4. Upload: build/app/outputs/bundle/localRelease/app-local-release.aab"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
