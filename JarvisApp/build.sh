#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Jarvis"
BUNDLE_DIR="${SCRIPT_DIR}/../${APP_NAME}.app"
BUILD_DIR="${SCRIPT_DIR}/.build/release"

echo "==> Building JarvisApp (release)..."
swift build -c release 2>&1

BINARY="${BUILD_DIR}/JarvisApp"
if [ ! -f "$BINARY" ]; then
    echo "ERROR: Binary not found at $BINARY"
    exit 1
fi

echo "==> Creating ${APP_NAME}.app bundle..."

# Clean old bundle
rm -rf "$BUNDLE_DIR"

# Create structure
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

# Copy binary
cp "$BINARY" "${BUNDLE_DIR}/Contents/MacOS/JarvisApp"

# Copy Info.plist
cp "${SCRIPT_DIR}/Resources/Info.plist" "${BUNDLE_DIR}/Contents/"

# Copy icon
cp "${SCRIPT_DIR}/Resources/AppIcon.icns" "${BUNDLE_DIR}/Contents/Resources/"

echo "==> Done: ${BUNDLE_DIR}"
echo "    Run: open ${BUNDLE_DIR}"
