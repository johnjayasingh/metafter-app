#!/bin/bash
set -e

echo "🏗️  Building Production IPA for App Store..."
echo ""

# Build with standard flutter build ipa command
echo "Building IPA for App Store distribution..."
flutter build ipa --release --export-options-plist=ios/ExportOptions-appstore.plist

echo ""
echo "✅ App Store IPA built successfully!"
echo "📦 IPA Location: build/ios/ipa/"
ls -lh build/ios/ipa/*.ipa
echo ""
echo "📋 Next Steps:"
echo "  1. Open Apple Transporter app"
echo "  2. Sign in with your Apple ID"
echo "  3. Click '+' and select build/ios/ipa/digitalwill.ipa"
echo "  4. Click 'Deliver' to upload to App Store Connect"
echo ""
echo "Alternative upload methods:"
echo "  • Xcode: Window → Organizer → Archives → Distribute App"
echo "  • Command line: xcrun altool --upload-app --type ios -f build/ios/ipa/digitalwill.ipa --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
