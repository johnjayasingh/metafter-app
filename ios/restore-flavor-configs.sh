#!/bin/bash
# Restore flavor-specific configurations to Pods xcconfig files
# Run this after `pod install` to ensure flavor settings are preserved

echo "Restoring flavor configurations to Pods xcconfig files..."

# Add DEV settings to debug-dev xcconfig
echo "
// Flavor-specific overrides  
DISPLAY_NAME = Metafter DEV
PRODUCT_BUNDLE_IDENTIFIER = com.techinorm.metafter.dev" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug-dev.xcconfig"

# Add DEV settings to release-dev xcconfig
echo "
// Flavor-specific overrides
DISPLAY_NAME = Metafter DEV
PRODUCT_BUNDLE_IDENTIFIER = com.techinorm.metafter.dev" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.release-dev.xcconfig"

# Add UAT settings to debug-uat xcconfig
echo "
// Flavor-specific overrides
DISPLAY_NAME = Metafter UAT
PRODUCT_BUNDLE_IDENTIFIER = com.techinorm.metafter.uat" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug-uat.xcconfig"

# Add UAT settings to release-uat xcconfig
echo "
// Flavor-specific overrides
DISPLAY_NAME = Metafter UAT
PRODUCT_BUNDLE_IDENTIFIER = com.techinorm.metafter.uat" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.release-uat.xcconfig"

echo "✓ Flavor configurations restored!"
