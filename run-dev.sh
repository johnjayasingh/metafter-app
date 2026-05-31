#!/bin/bash
set -e

# Optional: pass a device ID as the first argument
DEVICE_ARG=""
if [[ -n "$1" ]]; then
    DEVICE_ARG="-d $1"
fi

echo "🚀 Running DEV environment..."
echo "   Flavor : dev"
echo "   Target : lib/main_dev.dart"
[[ -n "$1" ]] && echo "   Device : $1"
echo ""

flutter run --flavor dev -t lib/main_dev.dart $DEVICE_ARG
