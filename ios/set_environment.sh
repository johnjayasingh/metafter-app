#!/bin/sh

ENVIRONMENT=$1

case "$ENVIRONMENT" in
    "dev")
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Will Cloud DEV'" "${INFOPLIST_FILE}"
        echo "✅ Environment set to: DEV"
        ;;
    "uat")
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Will Cloud UAT'" "${INFOPLIST_FILE}"
        echo "✅ Environment set to: UAT"
        ;;
    *)
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Will Cloud'" "${INFOPLIST_FILE}"
        echo "✅ Environment set to: PRODUCTION"
        ;;
esac
