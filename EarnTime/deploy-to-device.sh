#!/bin/bash

# Script to build and deploy EarnTime app to connected iPhone
# Usage: ./deploy-to-device.sh

set -e

PROJECT_PATH="EarnTime.xcodeproj"
SCHEME="EarnTime"
BUNDLE_ID="com.opensource.EarnTime"

echo "🔍 Checking for connected iOS device..."
DEVICE_ID=$(xcrun xctrace list devices 2>/dev/null | grep -i "iphone" | grep -v "Simulator" | head -1 | sed 's/.*\[\(.*\)\].*/\1/' || echo "")

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No iPhone detected. Please:"
    echo "   1. Connect your iPhone via USB"
    echo "   2. Unlock your iPhone"
    echo "   3. Trust this computer if prompted"
    echo ""
    echo "Available devices:"
    xcrun xctrace list devices 2>/dev/null || xcrun simctl list devices
    exit 1
fi

echo "✅ Found device: $DEVICE_ID"
echo ""

echo "🔨 Building app for device..."
xcodebuild clean build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$DEVICE_ID" \
    CODE_SIGN_IDENTITY="Apple Development" \
    DEVELOPMENT_TEAM="" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Make sure:"
    echo "   1. Your Apple ID is configured in Xcode"
    echo "   2. Automatic signing is enabled"
    echo "   3. Your device is trusted"
    exit 1
fi

echo ""
echo "📦 Locating built app..."
APP_PATH=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration Debug -showBuildSettings 2>/dev/null | grep -m 1 "BUILT_PRODUCTS_DIR" | sed 's/.*= *//')/EarnTime.app

if [ ! -d "$APP_PATH" ]; then
    # Try alternative path
    APP_PATH="build/Debug-iphoneos/EarnTime.app"
fi

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Could not find built app. Build may have failed."
    exit 1
fi

echo "✅ Found app at: $APP_PATH"
echo ""

echo "📱 Installing app on device..."
if command -v ios-deploy &> /dev/null; then
    ios-deploy --bundle "$APP_PATH" --device "$DEVICE_ID"
elif command -v xcrun devicectl &> /dev/null; then
    # iOS 17+ method
    xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
else
    # Fallback: use xcodebuild to install
    echo "Using xcodebuild to install..."
    xcodebuild -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "id=$DEVICE_ID" \
        -configuration Debug \
        install
fi

echo ""
echo "✅ App installed successfully!"
echo "📱 Check your iPhone - the EarnTime app should now be installed."
echo ""
echo "Note: On first launch, you may need to:"
echo "   Settings → General → VPN & Device Management → Trust your developer certificate"
