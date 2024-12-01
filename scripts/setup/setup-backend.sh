#!/bin/bash

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Error handling
set -e
trap 'echo -e "${RED}An error occurred during backend setup. Please check the error message above.${NC}"' ERR

echo -e "${BOLD}🔧 Setting up Backend Development Environment...${NC}\n"

# Run dependency checker
echo -e "${BOLD}Checking backend dependencies...${NC}"
bash "$(dirname "$0")/check-dependencies.sh"

# Create and activate virtual environment
echo -e "\n${BOLD}Setting up Python virtual environment...${NC}"
cd "$(dirname "$0")/../../backend" || exit 1

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

# Install backend dependencies
echo -e "\n${BOLD}Installing backend dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

echo -e "\n${GREEN}${BOLD}✓ Backend setup complete!${NC}"
echo -e "\nTo activate the virtual environment:"
echo -e "  cd backend"
echo -e "  source venv/bin/activate"
echo -e "\nTo start the backend server:"
echo -e "  uvicorn index:app --reload --port 9090"
