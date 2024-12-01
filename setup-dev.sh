#!/bin/bash

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Error handling
set -e  # Exit on error
trap 'echo -e "${RED}An error occurred during setup. Please check the error message above.${NC}"' ERR

echo -e "${BLUE}${BOLD}🚀 Setting up CaringMind Development Environment...${NC}\n"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS. For Linux setup, please use scripts/setup-dependencies.sh first.${NC}"
    exit 1
fi

# Run dependency checker first
echo -e "${BOLD}Running dependency checker...${NC}"
if [ -f "scripts/setup-dependencies.sh" ]; then
    bash scripts/setup-dependencies.sh
else
    echo -e "${YELLOW}Warning: dependency checker not found. Proceeding with basic setup...${NC}"
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo -e "${BOLD}📦 Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Python 3.12 if not present
if ! command -v python3.12 &> /dev/null; then
    echo -e "${BOLD}🐍 Installing Python 3.12...${NC}"
    brew install python@3.12
fi

# Install pnpm if not present
if ! command -v pnpm &> /dev/null; then
    echo -e "${BOLD}📦 Installing pnpm...${NC}"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    source ~/.zshrc  # Reload shell configuration
fi

# Install Xcode Command Line Tools if not present
if ! xcode-select -p &> /dev/null; then
    echo -e "${BOLD}📱 Installing Xcode Command Line Tools...${NC}"
    xcode-select --install
    echo -e "${YELLOW}Please wait for Xcode Command Line Tools installation to complete...${NC}"
    read -p "Press Enter once installation is complete..."
fi

# Install VS Code if not present
if ! command -v code &> /dev/null; then
    echo -e "${BOLD}📝 Installing Visual Studio Code...${NC}"
    brew install --cask visual-studio-code
fi

# Install VS Code extensions
if command -v code &> /dev/null; then
    echo -e "${BOLD}🔧 Installing VS Code extensions...${NC}"
    code --install-extension sswg.swift-lang
    code --install-extension ms-python.python
    code --install-extension sourcegraph.cody-ai
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension esbenp.prettier-vscode
fi

# Backend Setup
echo -e "\n${BOLD}🔧 Setting up Backend...${NC}"
cd backend || exit 1

# Set up Python virtual environment
echo -e "${BOLD}📦 Setting up Python virtual environment...${NC}"
python3.12 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo -e "${BOLD}📚 Installing Python dependencies...${NC}"
python -m pip install --upgrade pip
pip install -r requirements.txt

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${BOLD}📝 Creating .env from example...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Please edit .env with your actual configuration values${NC}"
    else
        echo -e "${RED}Error: .env.example not found${NC}"
        exit 1
    fi
fi

# Frontend Setup
echo -e "\n${BOLD}🎨 Setting up Frontend...${NC}"
cd ../clients/caringmindWeb || exit 1

# Install frontend dependencies
echo -e "${BOLD}📚 Installing Node.js dependencies...${NC}"
pnpm install

# Build the frontend
echo -e "${BOLD}🏗️  Building frontend...${NC}"
pnpm build

# iOS App Setup
echo -e "\n${BOLD}📱 Setting up iOS App...${NC}"
cd ../mobile/ios || exit 1

# Verify Xcode installation
if ! /usr/bin/xcodebuild -version &> /dev/null; then
    echo -e "${RED}⚠️  Please install Xcode from the App Store first${NC}"
    echo "   After installing, open Xcode once to complete the installation"
fi

# Return to root directory
cd ../../../

# Final setup verification
echo -e "\n${BOLD}🔍 Verifying setup...${NC}"
echo -e "Python version: $(python3 --version)"
echo -e "Node version: $(node --version)"
echo -e "pnpm version: $(pnpm --version)"
if [ -f "backend/venv/bin/activate" ]; then
    echo -e "Virtual environment: ✓"
fi

echo -e "\n${GREEN}${BOLD}✨ Setup completed! Here's how to start development:${NC}"
echo -e "
${BOLD}Backend:${NC}
1. cd backend
2. source venv/bin/activate  # Activate virtual environment
3. uvicorn index:app --reload --port 9090

${BOLD}Frontend:${NC}
1. cd clients/caringmindWeb
2. pnpm dev

${BOLD}iOS App:${NC}
1. Open VS Code and navigate to the mobile/ios directory
2. Use VS Code for Swift development
3. Alternatively, open the project in Xcode when needed

${BOLD}Note:${NC} 
- Make sure to configure your .env files with the correct values before starting the services
- For iOS development:
  * VS Code is set up for Swift development
  * Xcode is available when needed for specific iOS tasks
  * Make sure to open Xcode at least once to complete its setup

${BOLD}Development URLs:${NC}
- Backend: http://localhost:9090
- Frontend: http://localhost:3000
- API Documentation: http://localhost:9090/docs

${BOLD}Need help?${NC}
- Check docs/DEPENDENCIES.md for detailed system requirements
- Run scripts/setup-dependencies.sh to verify system dependencies
- Visit docs/TROUBLESHOOTING.md for common issues and solutions
"