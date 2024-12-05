#!/bin/bash

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Error handling
set -e
trap 'echo -e "${RED}An error occurred during frontend setup. Please check the error message above.${NC}"' ERR

echo -e "${BOLD}🎨 Setting up Frontend Development Environment...${NC}\n"

# Run dependency checker
echo -e "${BOLD}Checking frontend dependencies...${NC}"
bash "$(dirname "$0")/check-dependencies.sh"

# Install pnpm if not present
if ! command -v pnpm &> /dev/null; then
    echo -e "${BOLD}📦 Installing pnpm...${NC}"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    source ~/.zshrc
fi

# Install frontend dependencies
echo -e "\n${BOLD}Installing frontend dependencies...${NC}"
cd "$(dirname "$0")/../../frontend" || exit 1
pnpm install

echo -e "\n${GREEN}${BOLD}✓ Frontend setup complete!${NC}"
echo -e "\nTo start the frontend development server:"
echo -e "  cd frontend"
echo -e "  pnpm dev"
