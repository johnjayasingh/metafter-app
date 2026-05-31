#!/bin/bash
set -e

# Optional: pass a device ID as the first argument
DEVICE_ARG=""
if [[ -n "$1" ]]; then
    DEVICE_ARG="-d $1"
fi

echo "🚀 Running UAT environment..."
echo "   Flavor : uat"
echo "   Target : lib/main_uat.dart"
[[ -n "$1" ]] && echo "   Device : $1"
echo ""

flutter run --flavor uat -t lib/main_uat.dart $DEVICE_ARG
