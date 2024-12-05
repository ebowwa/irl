#!/bin/bash

# Function to display cleanup progress
echo_step() {
    echo " $1"
}

# Remove .DS_Store files
echo_step "Removing .DS_Store files..."
find . -type f -name '.DS_Store' -delete

# Remove Python cache files
echo_step "Removing Python cache files..."
find . -type d -name "__pycache__" -exec rm -r {} +
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type f -name "*.pyd" -delete

# Remove node_modules only in specified directories
echo_step "Cleaning node_modules..."
if [ -d "./clients/caringmindWeb/node_modules" ]; then
    rm -rf ./clients/caringmindWeb/node_modules
fi

# Clean Python virtual environments
echo_step "Cleaning Python virtual environments..."
if [ -d "./backend/venv" ]; then
    rm -rf ./backend/venv
fi
if [ -d "./venv" ]; then
    rm -rf ./venv
fi

# Check for Python files outside backend directory
echo_step "Checking for misplaced Python files..."
find . -type f -name "*.py" ! -path "./backend/*" ! -path "./tests/*" -exec echo "Warning: Python file found outside backend directory: {}" \;

# Check for Node.js files outside web app directory
echo_step "Checking for misplaced Node.js files..."
find . -type f -name "package.json" ! -path "./clients/caringmindWeb/*" -exec echo "Warning: Node.js file found outside web app directory: {}" \;

# Check for Swift files outside iOS app directory
echo_step "Checking for misplaced Swift files..."
find . -type f -name "*.swift" ! -path "./clients/irlapp/*" -exec echo "Warning: Swift file found outside iOS app directory: {}" \;

# Clean Xcode derived data and build folders
echo_step "Cleaning Xcode build files..."
if [ -d "./clients/irlapp" ]; then
    find ./clients/irlapp -type d -name "DerivedData" -exec rm -rf {} +
    find ./clients/irlapp -type d -name "Build" -exec rm -rf {} +
fi

echo " Cleanup complete!"
echo "Note: Review any warnings above for misplaced files"
