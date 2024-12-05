#!/bin/bash

# Script to build the IRL App
set -e  # Exit on any error

# Directory containing the Xcode project
PROJECT_DIR="/Users/ebowwa/caringmind/clients/irlapp"
PROJECT_NAME="mahdi"
SCHEME_NAME="mahdi"  # Using the default scheme name

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function check_dependencies() {
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Please install Xcode command line tools."
        exit 1
    fi

    # Check for package manager configuration
    if [ -f "$PROJECT_DIR/Package.swift" ]; then
        log_info "Swift Package Manager configuration found"
        if ! command -v swift &> /dev/null; then
            log_error "Swift compiler not found. Please install Xcode command line tools."
            exit 1
        fi
    elif [ -f "$PROJECT_DIR/Podfile" ]; then
        log_info "CocoaPods configuration found"
        if ! command -v pod &> /dev/null; then
            log_error "CocoaPods not found. Please install CocoaPods using: gem install cocoapods"
            exit 1
        fi
    else
        log_warning "No package manager configuration found. Proceeding with build..."
    fi

    log_info "Dependencies check passed"
}

function setup_dependencies() {
    if [ -f "$PROJECT_DIR/Package.swift" ]; then
        log_info "Resolving Swift Package Manager dependencies..."
        if ! (cd "$PROJECT_DIR" && swift package resolve); then
            log_error "Failed to resolve Swift Package Manager dependencies"
            exit 1
        fi
    elif [ -f "$PROJECT_DIR/Podfile" ]; then
        log_info "Installing CocoaPods dependencies..."
        if ! (cd "$PROJECT_DIR" && pod install); then
            log_error "Failed to install CocoaPods dependencies"
            exit 1
        fi
    fi
}

function validate_project() {
    if [ ! -d "$PROJECT_DIR" ]; then
        log_error "Project directory not found at $PROJECT_DIR"
        exit 1
    fi

    if [ ! -d "$PROJECT_DIR/${PROJECT_NAME}.xcodeproj" ]; then
        log_error "Xcode project not found at $PROJECT_DIR/${PROJECT_NAME}.xcodeproj"
        exit 1
    fi

    # Validate scheme exists
    if ! xcodebuild -project "$PROJECT_DIR/${PROJECT_NAME}.xcodeproj" -list | grep -q "$SCHEME_NAME"; then
        log_error "Scheme '$SCHEME_NAME' not found in project"
        echo "Available schemes:"
        xcodebuild -project "$PROJECT_DIR/${PROJECT_NAME}.xcodeproj" -list | grep -A 100 "Schemes:"
        exit 1
    fi
    
    log_info "Project validation passed"
}

function clean_build_dir() {
    log_info "Cleaning build directory..."
    if ! xcodebuild clean \
        -project "$PROJECT_DIR/${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug; then
        log_error "Failed to clean project"
        exit 1
    fi
}

function build_project() {
    log_info "Starting build process..."
    cd "$PROJECT_DIR" || {
        log_error "Failed to change to project directory"
        exit 1
    }

    # Clean build directory
    clean_build_dir

    # Build for iOS Simulator
    log_info "Building project..."
    if ! xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,name=iPhone 16,OS=18.1" \
        build; then
        log_error "Build failed"
        exit 1
    fi

    log_info "Build completed successfully! 🎉"
}

# Main execution
log_info "IRL App Build Script"
log_info "Running pre-build checks..."

# Run checks
check_dependencies
setup_dependencies
validate_project

# Start build
log_info "Starting build process..."
build_project
