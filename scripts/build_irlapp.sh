#!/bin/bash

# Script to build the IRL App
set -e  # Exit on any error

# Directory containing the Xcode project
PROJECT_DIR="/Users/ebowwa/caringmind/clients/irlapp"
PROJECT_NAME="caringmind"
ORGANIZATION_NAME="caringmind"
BUNDLE_IDENTIFIER="com.caringmind.irlapp"

function create_new_project() {
    echo "🆕 Creating new Xcode project..."
    
    # Backup old project if it exists
    if [ -d "$PROJECT_DIR" ]; then
        BACKUP_DIR="${PROJECT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        echo "📦 Backing up existing project to $BACKUP_DIR"
        mv "$PROJECT_DIR" "$BACKUP_DIR"
    fi

    # Create project directory if it doesn't exist
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"

    # Create new Xcode project using Swift UI template
    xcodegen generate || {
        echo "⚠️ Xcodegen not found. Creating project with xcodebuild..."
        xcodebuild -create \
            -template Swift \
            -bundleIdentifier "$BUNDLE_IDENTIFIER" \
            -organizationName "$ORGANIZATION_NAME" \
            -projectName "$PROJECT_NAME"
    }

    echo "✅ New project created successfully!"
}

function build_project() {
    echo "📱 Building IRL App..."

    # Navigate to project directory
    cd "$PROJECT_DIR"

    # Clean build directory
    echo "🧹 Cleaning build directory..."
    xcodebuild clean -project "${PROJECT_NAME}.xcodeproj"

    # Build for iOS Simulator
    echo "🔨 Building project..."
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,name=iPhone 14" \
        build

    echo "✅ Build completed successfully!"
}

# Show usage menu
echo "IRL App Build Script"
echo "1. Build existing project"
echo "2. Create new project"
echo "Please enter your choice (1 or 2):"
read -r choice

case $choice in
    1)
        build_project
        ;;
    2)
        create_new_project
        build_project
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again and select 1 or 2."
        exit 1
        ;;
esac
