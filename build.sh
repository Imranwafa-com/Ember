#!/bin/bash
# Build Ember and package into a macOS .app bundle
set -euo pipefail

CONFIG="${1:-release}"
echo "Building Ember ($CONFIG)..."

# Clean corrupt caches if they exist
rm -rf ".build/arm64-apple-macosx/$CONFIG/ModuleCache" 2>/dev/null || true
rm -f ".build/build.db" 2>/dev/null || true

swift build -c "$CONFIG" 2>&1 || true

# Verify binary was produced
if [ ! -f ".build/arm64-apple-macosx/$CONFIG/Ember" ]; then
    echo "Build failed — no binary produced."
    exit 1
fi

# Paths
BUILD_DIR=".build/arm64-apple-macosx/$CONFIG"
APP_DIR="build/Ember.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean previous bundle
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary
cp "$BUILD_DIR/Ember" "$MACOS/Ember"

# Copy Info.plist
cp Ember/Info.plist "$CONTENTS/Info.plist"

# Copy bundled resources (SwiftPM puts processed assets in the bundle)
if [ -d "$BUILD_DIR/Ember_Ember.bundle" ]; then
    cp -R "$BUILD_DIR/Ember_Ember.bundle" "$RESOURCES/"
fi

# Copy Assets.xcassets (compiled) if available
if [ -d "$BUILD_DIR/Ember.app" ]; then
    cp -R "$BUILD_DIR/Ember.app/Contents/Resources/"* "$RESOURCES/" 2>/dev/null || true
fi

echo ""
echo "Built: $APP_DIR"
echo "Run:   open build/Ember.app"
