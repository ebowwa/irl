#!/bin/bash

# -------------------------------
# Caring iOS Project Setup Script
# -------------------------------

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print messages with colors
print_message() {
    echo -e "${1}${2}${NC}"
}

# Start of the setup
print_message "$GREEN" "Setting up Caring iOS project..."

# Change to the script's directory
cd "$(dirname "$0")" || { print_message "$RED" "Failed to navigate to script directory."; exit 1; }

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_message "$YELLOW" "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        print_message "$RED" "Homebrew installation failed."
        exit 1
    }
    # Add Homebrew to PATH (for non-standard installations)
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null
fi

# Function to check and install a brew package
install_brew_package() {
    local package=$1
    if ! command -v "$package" &> /dev/null; then
        print_message "$YELLOW" "$package is not installed. Installing via brew..."
        brew install "$package" || {
            print_message "$RED" "Failed to install $package."
            exit 1
        }
    fi
}

# Install required packages
install_brew_package "sed"
install_brew_package "xcodegen"

# Look for .env in the current directory
if [ -f "./.env" ]; then
    set -a
    source "./.env"
    set +a
    print_message "$GREEN" ".env file loaded successfully."
else
    print_message "$RED" "Error: .env file not found in the script directory."
    exit 1
fi

# Define the path to project.yml inside the caring directory
PROJECT_YML="caring/project.yml"

if [ ! -f "$PROJECT_YML" ]; then
    print_message "$RED" "Error: $PROJECT_YML not found."
    exit 1
fi

print_message "$YELLOW" "Updating environment variables in $PROJECT_YML..."

# Function to safely replace variables in the YAML file
replace_var() {
    local var_name=$1
    local var_value=$2
    if [ -n "$var_value" ]; then
        # Escape forward slashes and ampersands in var_value to prevent sed issues
        local escaped_value=$(printf '%s\n' "$var_value" | sed 's/[\/&]/\\&/g')
        sed -i '' "s|\${$var_name}|$escaped_value|g" "$PROJECT_YML"
        print_message "$GREEN" "Replaced \${$var_name} with $var_value in $PROJECT_YML."
    else
        print_message "$YELLOW" "Warning: $var_name is not set. Skipping replacement."
    fi
}

replace_var "DEVELOPMENT_TEAM" "$DEVELOPMENT_TEAM"
replace_var "GOOGLE_CLIENT_ID" "$GOOGLE_CLIENT_ID"
replace_var "GOOGLE_URL_SCHEME" "$GOOGLE_URL_SCHEME"

print_message "$GREEN" "Environment variables updated in $PROJECT_YML."

# Clean any existing Xcode project inside the caring directory
print_message "$YELLOW" "Cleaning existing Xcode project..."
rm -rf caring/caring.xcodeproj caring/caring.xcworkspace

# Generate Xcode project using XcodeGen
print_message "$YELLOW" "Generating Xcode project with XcodeGen..."
xcodegen generate --spec "$PROJECT_YML" || {
    print_message "$RED" "XcodeGen failed to generate the project."
    exit 1
}

# Define the project directory
PROJECT_DIR="caring"

if [ -d "$PROJECT_DIR" ]; then
    # Resolve Swift package dependencies
    print_message "$YELLOW" "Resolving Swift package dependencies..."
    xcodebuild -resolvePackageDependencies -project "$PROJECT_DIR/caring.xcodeproj" || {
        print_message "$RED" "Failed to resolve Swift package dependencies."
        exit 1
    }
else
    print_message "$RED" "Project directory $PROJECT_DIR does not exist."
    exit 1
fi

# Open the project in Xcode
print_message "$YELLOW" "Opening project in Xcode..."
open "$PROJECT_DIR/caring.xcodeproj" || {
    print_message "$RED" "Failed to open Xcode project."
    exit 1
}

# Completion message
print_message "$GREEN" "Initial setup complete!"

# Additional instructions
echo -e "\n${YELLOW}Important: Before building, you need to:${NC}"
echo "1. Open the Caring project in Xcode."
echo "2. Select the Caring target."
echo "3. Go to Signing & Capabilities."
echo "4. Check 'Automatically manage signing'."
echo "5. Select your development team."

echo -e "\n${YELLOW}After setting up signing, you can:${NC}"
echo "1. Select your target device/simulator in Xcode."
echo "2. Press Cmd + R or click the Play button to build and run."

echo -e "\n${GREEN}If you want to build from the command line after setting up signing, run:${NC}"
echo "xcodebuild -scheme caring -project caring/caring.xcodeproj build -allowProvisioningUpdates"
