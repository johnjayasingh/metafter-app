#!/bin/bash
set -e

# Optional: pass a device ID as the first argument
DEVICE_ARG=""
if [[ -n "$1" ]]; then
    DEVICE_ARG="-d $1"
fi

echo "🚀 Running LOCAL environment (debug pre-fill enabled)..."
echo "   Target : lib/main_local.dart"
[[ -n "$1" ]] && echo "   Device : $1"
echo ""

flutter run -t lib/main_local.dart $DEVICE_ARG
