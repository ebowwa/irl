#!/bin/bash

echo "🚀 Setting up CaringMind Development Environment..."

# Check if Poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "📦 Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
fi

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "📦 Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Check if Xcode Command Line Tools are installed (needed for iOS development)
if ! xcode-select -p &> /dev/null; then
    echo "📱 Installing Xcode Command Line Tools..."
    xcode-select --install
fi

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
    echo "📝 Installing Visual Studio Code..."
    brew install --cask visual-studio-code
fi

# Install VS Code Swift extension
if command -v code &> /dev/null; then
    echo "🔧 Installing VS Code Swift extension..."
    code --install-extension sswg.swift-lang
fi

# Backend Setup
echo "🔧 Setting up Backend..."
cd backend

# Initialize Poetry and install dependencies
echo "📚 Installing Python dependencies..."
poetry install

# Setup pre-commit hooks
echo "🔨 Setting up pre-commit hooks..."
poetry run pre-commit install

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env from example..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your actual configuration values"
fi

# Frontend Setup
echo "🎨 Setting up Frontend..."
cd ../clients/caringmindWeb

# Install frontend dependencies
echo "📚 Installing Node.js dependencies..."
pnpm install

# Build the frontend
echo "🏗️  Building frontend..."
pnpm build

# iOS App Setup
echo "📱 Setting up iOS App..."
cd ../mobile/ios

# Verify Xcode installation
if ! /usr/bin/xcodebuild -version &> /dev/null; then
    echo "⚠️  Please install Xcode from the App Store first"
    echo "   After installing, open Xcode once to complete the installation"
fi

# Return to root directory
cd ../../../

echo "✨ Setup completed! Here's how to start development:"
echo "
Backend:
1. cd backend
2. poetry shell
3. uvicorn index:app --reload

Frontend:
1. cd clients/caringmindWeb
2. pnpm dev

iOS App:
1. Open VS Code and navigate to the mobile/ios directory
2. Use VS Code for Swift development
3. Alternatively, open the project in Xcode when needed

Note: 
- Make sure to configure your .env files with the correct values before starting the services
- For iOS development:
  * VS Code is set up for Swift development
  * Xcode is available when needed for specific iOS tasks
  * Make sure to open Xcode at least once to complete its setup
"