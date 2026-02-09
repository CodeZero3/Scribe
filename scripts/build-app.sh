#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Building Scribe (release)..."
swift build -c release

echo "Creating app bundle..."

APP_DIR="build/Scribe.app/Contents"
rm -rf build/Scribe.app
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy binary
cp .build/release/Scribe "$APP_DIR/MacOS/Scribe"
chmod +x "$APP_DIR/MacOS/Scribe"

# Copy Info.plist
cp Resources/Info.plist "$APP_DIR/Info.plist"

echo "Build complete: build/Scribe.app"
