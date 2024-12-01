#!/bin/bash

# Source development aliases and environment variables
source "$(dirname "$0")/../dev_aliases.sh"

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Error handling
set -e
trap 'echo -e "${RED}An error occurred during setup. Please check the error message above.${NC}"' ERR

echo -e "${BOLD}🚀 Setting up Complete CaringMind Development Environment...${NC}\n"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is designed for macOS. For Linux setup, please use setup-linux-full.sh${NC}"
    exit 1
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

# Set up frontend
echo -e "\n${BOLD}Setting up Frontend...${NC}"
bash "$(dirname "$0")/setup-frontend.sh"

# Set up backend
echo -e "\n${BOLD}Setting up Backend...${NC}"
bash "$(dirname "$0")/setup-backend.sh"

echo -e "\n${GREEN}${BOLD}✓ Full-stack setup complete!${NC}"
echo -e "\nYou can now:"
echo -e "1. Start the frontend: cd frontend && pnpm dev"
echo -e "2. Start the backend: cd backend && source venv/bin/activate && uvicorn index:app --reload --port 9090"
