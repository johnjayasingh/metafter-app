#!/bin/bash
set -e

# Optional: pass a device ID as the first argument
DEVICE_ARG=""
if [[ -n "$1" ]]; then
    DEVICE_ARG="-d $1"
fi

echo "🚀 Running Production environment..."
echo "   Target : lib/main.dart"
[[ -n "$1" ]] && echo "   Device : $1"
echo ""

flutter run -t lib/main.dart $DEVICE_ARG
