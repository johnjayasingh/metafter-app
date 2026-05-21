#!/bin/bash

# Build script for creating UAT and Dev builds for Android and iOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [platform] [environment] [build-type]"
    echo ""
    echo "Arguments:"
    echo "  platform      : android or ios"
    echo "  environment   : dev or uat"
    echo "  build-type    : apk, aab (Android) or ipa (iOS)"
    echo ""
    echo "Examples:"
    echo "  $0 android dev apk       # Build Android DEV APK"
    echo "  $0 android uat aab       # Build Android UAT AAB"
    echo "  $0 ios dev ipa           # Build iOS DEV IPA"
    echo "  $0 ios uat ipa           # Build iOS UAT IPA"
    exit 1
}

# Check arguments
if [ $# -lt 3 ]; then
    show_usage
fi

PLATFORM=$1
ENVIRONMENT=$2
BUILD_TYPE=$3

# Validate platform
if [[ "$PLATFORM" != "android" && "$PLATFORM" != "ios" ]]; then
    print_error "Invalid platform. Must be 'android' or 'ios'"
    show_usage
fi

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "uat" ]]; then
    print_error "Invalid environment. Must be 'dev' or 'uat'"
    show_usage
fi

# Set target file based on environment
if [ "$ENVIRONMENT" == "dev" ]; then
    TARGET_FILE="lib/main_dev.dart"
elif [ "$ENVIRONMENT" == "uat" ]; then
    TARGET_FILE="lib/main_uat.dart"
fi

print_info "Building $PLATFORM $ENVIRONMENT build..."

# Clean previous builds
print_info "Cleaning previous builds..."
flutter clean
flutter pub get

# Build based on platform
if [ "$PLATFORM" == "android" ]; then
    if [ "$BUILD_TYPE" == "apk" ]; then
        print_info "Building Android APK for $ENVIRONMENT..."
        flutter build apk --release --flavor $ENVIRONMENT -t $TARGET_FILE
        
        # Copy APK to builds directory
        mkdir -p builds/android/$ENVIRONMENT
        cp build/app/outputs/flutter-apk/app-$ENVIRONMENT-release.apk \
           builds/android/$ENVIRONMENT/digitalwill-$ENVIRONMENT-$(date +%Y%m%d-%H%M%S).apk
        
        print_info "✅ APK built successfully!"
        print_info "Location: builds/android/$ENVIRONMENT/"
        
    elif [ "$BUILD_TYPE" == "aab" ]; then
        print_info "Building Android App Bundle for $ENVIRONMENT..."
        flutter build appbundle --release --flavor $ENVIRONMENT -t $TARGET_FILE
        
        # Copy AAB to builds directory
        mkdir -p builds/android/$ENVIRONMENT
        cp build/app/outputs/bundle/${ENVIRONMENT}Release/app-$ENVIRONMENT-release.aab \
           builds/android/$ENVIRONMENT/digitalwill-$ENVIRONMENT-$(date +%Y%m%d-%H%M%S).aab
        
        print_info "✅ App Bundle built successfully!"
        print_info "Location: builds/android/$ENVIRONMENT/"
    else
        print_error "Invalid build type for Android. Must be 'apk' or 'aab'"
        exit 1
    fi
    
elif [ "$PLATFORM" == "ios" ]; then
    if [ "$BUILD_TYPE" == "ipa" ]; then
        # Check if running on macOS
        if [[ "$OSTYPE" != "darwin"* ]]; then
            print_error "iOS builds can only be created on macOS"
            exit 1
        fi
        
        print_info "Building iOS IPA for $ENVIRONMENT..."
        
        # Convert environment to scheme name
        if [ "$ENVIRONMENT" == "dev" ]; then
            SCHEME="dev"
        elif [ "$ENVIRONMENT" == "uat" ]; then
            SCHEME="uat"
        fi
        
        flutter build ios --release --flavor $ENVIRONMENT -t $TARGET_FILE
        
        print_info "✅ iOS build completed!"
        print_warning "Note: To create IPA, you need to:"
        print_warning "1. Open Xcode: open ios/Runner.xcworkspace"
        print_warning "2. Select Product > Archive"
        print_warning "3. Choose 'Distribute App' and follow the wizard"
        print_warning "Or use fastlane for automated distribution"
        
    else
        print_error "Invalid build type for iOS. Must be 'ipa'"
        exit 1
    fi
fi

print_info "🎉 Build process completed!"
