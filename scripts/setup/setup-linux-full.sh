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

echo -e "${BOLD}🚀 Setting up Complete CaringMind Development Environment for Linux...${NC}\n"

# Check if running on Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${RED}This script is designed for Linux. For macOS setup, please use setup-macos-full.sh${NC}"
    exit 1
fi

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    INSTALL_CMD="apt-get install -y"
    # Update package lists
    sudo apt-get update
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="dnf install -y"
    # Update package lists
    sudo dnf check-update
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="pacman -S --noconfirm"
    # Update package lists
    sudo pacman -Sy
else
    echo -e "${RED}Unsupported package manager. Please install dependencies manually.${NC}"
    exit 1
fi

# Install system dependencies
echo -e "\n${BOLD}Installing system dependencies...${NC}"
sudo $INSTALL_CMD git make curl

# Install Python 3.12 if not present
if ! command -v python3.12 &> /dev/null; then
    echo -e "\n${BOLD}🐍 Installing Python 3.12...${NC}"
    case $PKG_MANAGER in
        "apt-get")
            sudo add-apt-repository ppa:deadsnakes/ppa -y
            sudo apt-get update
            sudo apt-get install -y python3.12 python3.12-venv
            ;;
        "dnf")
            sudo dnf install -y python3.12 python3.12-devel
            ;;
        "pacman")
            sudo pacman -S --noconfirm python
            ;;
    esac
fi

# Install Node.js and npm if not present
if ! command -v node &> /dev/null; then
    echo -e "\n${BOLD}📦 Installing Node.js...${NC}"
    case $PKG_MANAGER in
        "apt-get")
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "dnf")
            sudo dnf module install -y nodejs:18/common
            ;;
        "pacman")
            sudo pacman -S --noconfirm nodejs npm
            ;;
    esac
fi

# Install pnpm if not present
if ! command -v pnpm &> /dev/null; then
    echo -e "\n${BOLD}📦 Installing pnpm...${NC}"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    # Add pnpm to PATH for the current session
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
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

# Additional notes for Linux users
echo -e "\n${YELLOW}Additional Notes for Linux Users:${NC}"
echo -e "• If you encounter permission issues, you may need to run some commands with sudo"
echo -e "• Make sure your firewall allows the development ports (typically 3000 for frontend, 8000 for backend)"
echo -e "• For production deployment, consider setting up ufw or iptables"
