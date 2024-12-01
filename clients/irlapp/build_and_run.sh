#!/bin/bash

# Exit on error
set -e

echo "Building and installing mahdi app..."

# Build for iOS simulator
xcodebuild \
    -scheme mahdi \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -configuration Debug \
    build install

echo "Build and install complete! You can now open the app in the simulator."
