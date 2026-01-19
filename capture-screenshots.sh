#!/bin/bash

# AppShot Screenshot Capture Script
# This script automatically captures all screens from the iOS app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPSHOT_DIR="$SCRIPT_DIR/.appshot/screens"
PROJECT_DIR="$SCRIPT_DIR"
SCHEME="sling-test-app-2"
SIMULATOR_NAME="iPhone 17"

echo "📸 AppShot Screenshot Capture"
echo "=============================="

# Create output directory
mkdir -p "$APPSHOT_DIR"

# Find the booted simulator
DEVICE_ID=$(xcrun simctl list devices | grep -E "iPhone.*Booted" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

if [ -z "$DEVICE_ID" ]; then
    echo "⚠️  No booted simulator found. Starting $SIMULATOR_NAME..."
    xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
    sleep 3
    DEVICE_ID=$(xcrun simctl list devices | grep -E "$SIMULATOR_NAME.*Booted" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
fi

echo "📱 Using simulator: $DEVICE_ID"

# Build and install the app
echo "🔨 Building app..."
cd "$PROJECT_DIR"
xcodebuild -scheme "$SCHEME" -destination "id=$DEVICE_ID" -quiet build 2>/dev/null || {
    echo "Build failed, trying with Simulator SDK..."
    xcodebuild -scheme "$SCHEME" -sdk iphonesimulator -quiet build 2>/dev/null
}

# Find and install the app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "sling-test-app-2.app" -type d | head -1)
if [ -n "$APP_PATH" ]; then
    echo "📦 Installing app..."
    xcrun simctl install booted "$APP_PATH"
fi

# Launch app in screenshot mode
echo "🚀 Launching app in screenshot mode..."
BUNDLE_ID="net.avianlabs.prototype"
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
sleep 1
xcrun simctl launch booted "$BUNDLE_ID" --screenshot-mode &

# Screen definitions (must match ScreenshotMode.swift)
SCREENS=(
    "01_home:Home"
    "02_invest:Invest"
    "03_spend:Spend"
    "04_activity:Activity"
    "05_settings:Settings"
    "06_search:Search"
    "07_chat:Chat"
    "08_pending:Pending Requests"
    "09_send:Send Money"
    "10_withdraw:Withdraw"
    "11_splitbill:Split Bill"
    "12_addmoney:Add Money"
    "13_stockdetail:Stock Detail"
    "14_transaction:Transaction Detail"
    "15_onboarding:Onboarding"
    "16_qrscanner:QR Scanner"
)

# Wait for app to start
echo "⏳ Waiting for app to initialize..."
sleep 3

# Capture each screen
echo ""
echo "📸 Starting capture sequence..."
echo ""

for i in "${!SCREENS[@]}"; do
    SCREEN="${SCREENS[$i]}"
    FILENAME="${SCREEN%%:*}"
    SCREEN_NAME="${SCREEN##*:}"
    
    SCREEN_NUM=$((i + 1))
    TOTAL=${#SCREENS[@]}
    
    echo "[$SCREEN_NUM/$TOTAL] Capturing: $SCREEN_NAME"
    
    # Wait for screen to render (2.5 seconds per screen as per ScreenshotMode.swift timing)
    sleep 2.5
    
    # Take screenshot
    xcrun simctl io booted screenshot "$APPSHOT_DIR/${FILENAME}.png" 2>/dev/null
    
    if [ -f "$APPSHOT_DIR/${FILENAME}.png" ]; then
        echo "  ✅ Saved: ${FILENAME}.png"
    else
        echo "  ❌ Failed to capture ${FILENAME}.png"
    fi
done

echo ""
echo "=============================="
echo "✅ Capture complete!"
echo ""
echo "Screenshots saved to: $APPSHOT_DIR"
echo ""
echo "Next steps:"
echo "  1. Review the screenshots in $APPSHOT_DIR"
echo "  2. Push to GitHub: cd $PROJECT_DIR && git add .appshot && git commit -m 'Update screenshots' && git push"
echo ""
