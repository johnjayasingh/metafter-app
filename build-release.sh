#!/bin/bash

# Digital Will - Release Build Script
# This script builds both APK and AAB for release

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Digital Will - Release Build${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Set Java 17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
echo -e "${GREEN}✓${NC} Using Java 17: $JAVA_HOME"
echo ""

# Clean previous builds
echo -e "${YELLOW}→${NC} Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo -e "${YELLOW}→${NC} Getting dependencies..."
flutter pub get
echo ""

# Build APK
echo -e "${YELLOW}→${NC} Building Release APK..."
flutter build apk --release
APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
echo -e "${GREEN}✓${NC} APK built successfully (${APK_SIZE})"
echo -e "   Location: build/app/outputs/flutter-apk/app-release.apk"
echo ""

# Build App Bundle
echo -e "${YELLOW}→${NC} Building Release App Bundle (AAB)..."
flutter build appbundle --release 2>&1 | grep -v "Failed to find cmdline-tools" | grep -v "failed to strip" || true
AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
echo -e "${GREEN}✓${NC} AAB built successfully (${AAB_SIZE})"
echo -e "   Location: build/app/outputs/bundle/release/app-release.aab"
echo ""

# Verify signing
echo -e "${YELLOW}→${NC} Verifying signing..."
SIGNING_INFO=$(jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab 2>&1 | grep "Signed by" || echo "Unable to verify")
if [[ $SIGNING_INFO == *"Digital Will"* ]]; then
    echo -e "${GREEN}✓${NC} AAB is properly signed with release key"
else
    echo -e "${RED}✗${NC} Warning: Could not verify release signing"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}   Build Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "📦 ${BLUE}APK:${NC} build/app/outputs/flutter-apk/app-release.apk (${APK_SIZE})"
echo -e "📦 ${BLUE}AAB:${NC} build/app/outputs/bundle/release/app-release.aab (${AAB_SIZE})"
echo ""
echo -e "${YELLOW}Note:${NC} The AAB file is ready to upload to Google Play Console"
echo ""

# Open output directory
read -p "Open output directory? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open build/app/outputs/bundle/release/
fi
