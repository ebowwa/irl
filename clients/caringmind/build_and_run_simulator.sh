#!/bin/bash

# Exit on error
set -e

# Configuration
SCHEME_NAME="caringmind"
CONFIGURATION="Debug"

echo "🧹 Cleaning build directory..."
xcodebuild clean -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -quiet

echo "🏗️  Building and installing app..."
xcodebuild \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -configuration "$CONFIGURATION" \
    -allowProvisioningUpdates \
    build install

echo "🚀 Opening Simulator and launching app..."
open -a Simulator

# Wait for simulator to start
sleep 5

# Launch the app
xcrun simctl launch booted ebowwa.caringmind

echo "✅ Done! App should now be running in the simulator."
