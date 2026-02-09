#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=== Scribe Build ==="
echo ""

# Step 1: Build release binary
echo "[1/3] Building release binary..."
swift build -c release 2>&1

BINARY=".build/release/Scribe"
if [[ ! -f "$BINARY" ]]; then
    echo "ERROR: Build failed - binary not found at $BINARY"
    exit 1
fi
echo "      Binary built successfully."

# Step 2: Create .app bundle
echo "[2/3] Creating app bundle..."

APP_DIR="build/Scribe.app/Contents"
rm -rf build/Scribe.app
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy binary
cp "$BINARY" "$APP_DIR/MacOS/Scribe"
chmod +x "$APP_DIR/MacOS/Scribe"

# Copy Info.plist
if [[ -f "Resources/Info.plist" ]]; then
    cp Resources/Info.plist "$APP_DIR/Info.plist"
else
    echo "WARNING: Resources/Info.plist not found - app bundle may not work correctly."
fi

echo "      App bundle created at build/Scribe.app"

# Step 3: Report
echo "[3/3] Done!"
echo ""

# Print app size
APP_SIZE=$(du -sh build/Scribe.app | cut -f1)
BINARY_SIZE=$(du -sh "$APP_DIR/MacOS/Scribe" | cut -f1)
echo "      App bundle size: $APP_SIZE"
echo "      Binary size:     $BINARY_SIZE"
echo ""
echo "=== Build complete ==="
echo "Run with: open build/Scribe.app"
