#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="KSwitch"
APP_BUNDLE="$ROOT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_DIR="$ROOT_DIR/Resources"
ICONSET_DIR="$ICON_DIR/AppIcon.iconset"
ICNS_PATH="$ICON_DIR/AppIcon.icns"

echo "[1/4] Checking AppIcon.icns..."
mkdir -p "$ICON_DIR"
if [ ! -f "$ICNS_PATH" ]; then
  swift -swift-version 5 "$ROOT_DIR/Sources/generate_icon.swift" "$ICONSET_DIR"
  iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
  rm -rf "$ICONSET_DIR"
fi
rm -rf "$ICONSET_DIR"

echo "[2/4] Preparing bundle directories..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$ROOT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ICNS_PATH" "$RESOURCES_DIR/AppIcon.icns"
if [ -f "$ICON_DIR/donation_qr.png" ]; then
  cp "$ICON_DIR/donation_qr.png" "$RESOURCES_DIR/donation_qr.png"
fi

echo "[3/4] Compiling Swift source (arm64 / Swift 5 mode)..."
swiftc \
  -swift-version 5 \
  -O \
  -target arm64-apple-macosx13.0 \
  -framework Cocoa \
  -framework Carbon \
  -o "$MACOS_DIR/$APP_NAME" \
  "$ROOT_DIR/Sources/main.swift"

echo "[4/4] Signing application bundle (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Build succeeded: $APP_BUNDLE"
