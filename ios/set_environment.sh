#!/bin/sh

ENVIRONMENT=$1

case "$ENVIRONMENT" in
    "dev")
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Metafter DEV'" "${INFOPLIST_FILE}"
        echo "✅ Environment set to: DEV"
        ;;
    "uat")
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Metafter UAT'" "${INFOPLIST_FILE}"
        echo "✅ Environment set to: UAT"
        ;;
    *)
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Metafter'" "${INFOPLIST_FILE}"
        echo "✅ Environment set to: PRODUCTION"
        ;;
esac
