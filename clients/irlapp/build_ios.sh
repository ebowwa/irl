#!/bin/bash

# Get default simulator
DEFAULT_DEVICE=$(xcrun simctl list devices available | grep -m 1 "iPhone" | grep -E -o -i "([0-9a-f-]{36})")
if [ -z "$DEFAULT_DEVICE" ]; then
    echo "No available simulator found"
    exit 1
fi

echo "Building for simulator: $DEFAULT_DEVICE"

# Build the app
xcodebuild \
    -scheme mahdi \
    -destination "platform=iOS Simulator,id=$DEFAULT_DEVICE" \
    -configuration Debug \
    build

echo "Build complete!"
