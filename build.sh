#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Sesh"
APP_BUNDLE="$APP_NAME.app"
SOURCE_FILE="$PROJECT_DIR/${APP_NAME}App.swift"

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Compiling $APP_NAME..."
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/Resources"

swiftc \
    -o "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "$SOURCE_FILE" \
    -framework SwiftUI \
    -framework Foundation \
    -parse-as-library

echo "==> Copying Info.plist..."
cp "$PROJECT_DIR/$APP_BUNDLE/Contents/Info.plist" "$BUILD_DIR/$APP_BUNDLE/Contents/Info.plist"

echo "==> Copying icon..."
if [ -f "$PROJECT_DIR/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/AppIcon.icns" "$BUILD_DIR/$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "==> Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r -q "$APP_NAME.zip" "$APP_BUNDLE"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)

echo ""
echo "==> Build complete!"
echo "    App: $BUILD_DIR/$APP_BUNDLE"
echo "    ZIP: $ZIP_PATH ($ZIP_SIZE)"
