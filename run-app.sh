#!/bin/bash

# Script to run Flutter app with different environments
# Usage: ./run-app.sh [local|dev|uat|prod] [device-id]

ENVIRONMENT=${1:-local}
DEVICE_ID=$2

# Function to display usage
usage() {
    echo "Usage: ./run-app.sh [local|dev|uat|prod] [device-id]"
    echo ""
    echo "Environments:"
    echo "  local - LOCAL (Debug Pre-fill)"
    echo "  dev   - DEV environment"
    echo "  uat   - UAT environment"
    echo "  prod  - Production environment"
    echo ""
    echo "Examples:"
    echo "  ./run-app.sh local"
    echo "  ./run-app.sh dev"
    echo "  ./run-app.sh uat"
    echo "  ./run-app.sh dev iPhone-15-Pro"
    exit 1
}

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

# Device selection
DEVICE_ARG=""
if [[ -n "$DEVICE_ID" ]]; then
    DEVICE_ARG="-d $DEVICE_ID"
fi

case $ENVIRONMENT in
    local)
        echo "🚀 Running LOCAL environment (Debug Pre-fill)..."
        flutter run -t lib/main_local.dart $DEVICE_ARG
        ;;
    dev)
        echo "🚀 Running DEV environment..."
        flutter run -t lib/main_dev.dart --flavor dev $DEVICE_ARG
        ;;
    uat)
        echo "🚀 Running UAT environment..."
        flutter run -t lib/main_uat.dart --flavor uat $DEVICE_ARG
        ;;
    prod)
        echo "🚀 Running Production environment..."
        flutter run -t lib/main.dart $DEVICE_ARG
        ;;
    *)
        echo "❌ Error: Invalid environment '$ENVIRONMENT'"
        echo ""
        usage
        ;;
esac
