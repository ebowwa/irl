#!/bin/bash

# Exit on error
set -e

# Configuration
SCHEME_NAME="caringmind"
CONFIGURATION="Debug"
SIMULATOR_DEVICE="iPhone 16"
BUNDLE_ID="ebowwa.caringmind"
PROJECT_PATH="caringmind.xcodeproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[BUILD] ${GREEN}$1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Function to clean build directory
clean_build() {
    log "🧹 Cleaning build directory..."
    if [ -d "DerivedData" ]; then
        rm -rf DerivedData
    fi
    if [ -d ".build" ]; then
        rm -rf .build
    fi
    xcodebuild clean \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -quiet || error "Failed to clean build directory"
}

# Function to build the app
build_app() {
    log "🏗️  Building app..."
    
    # First try building with Swift Package Manager
    if [ -f "Package.swift" ]; then
        log "Building with Swift Package Manager..."
        swift build || error "Failed to build with SPM"
    else
        # Fall back to Xcode build
        log "Building with Xcode..."
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME_NAME" \
            -configuration "$CONFIGURATION" \
            -destination "platform=iOS Simulator,name=$SIMULATOR_DEVICE" \
            -allowProvisioningUpdates \
            build || error "Failed to build app"
    fi
}

# Function to install the app
install_app() {
    log "📲 Installing app..."
    
    if [ -f "Package.swift" ]; then
        log "Installing from Swift Package Manager build..."
        # Add SPM-specific installation steps here if needed
        swift run || error "Failed to install SPM package"
    else
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME_NAME" \
            -configuration "$CONFIGURATION" \
            -destination "platform=iOS Simulator,name=$SIMULATOR_DEVICE" \
            -allowProvisioningUpdates \
            install || error "Failed to install app"
    fi
}

# Function to launch simulator
launch_simulator() {
    log "🚀 Opening Simulator and launching app..."
    
    # Kill existing Simulator
    killall "Simulator" &> /dev/null || true
    
    # Boot simulator
    xcrun simctl boot "$SIMULATOR_DEVICE" 2>/dev/null || true
    
    # Open Simulator app
    open -a Simulator
    
    log "⏳ Waiting for simulator to start..."
    sleep 8  # Give simulator more time to start
    
    # Try launching the app
    xcrun simctl launch booted "$BUNDLE_ID" || error "Failed to launch app"
    
    log "✅ App launched successfully"
}

# Main execution
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --clean          Clean build directory"
    echo "  --build          Build the app"
    echo "  --install        Install the app"
    echo "  --launch         Launch the simulator"
    echo "  --all           Perform all actions (clean, build, install, launch)"
    echo "  --help          Show this help message"
}

# Process command line arguments
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

# Process all arguments
while [ "$1" != "" ]; do
    case $1 in
        --clean )        clean_build
                        ;;
        --build )       build_app
                        ;;
        --install )     install_app
                        ;;
        --launch )      launch_simulator
                        ;;
        --all )         clean_build
                        build_app
                        install_app
                        launch_simulator
                        ;;
        --help )        usage
                        exit
                        ;;
        * )             usage
                        exit 1
    esac
    shift
done
