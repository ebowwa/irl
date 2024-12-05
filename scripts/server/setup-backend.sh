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

# Set up base paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." &> /dev/null && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Verify directory structure
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}Error: Backend directory not found at $BACKEND_DIR${NC}"
    echo -e "${YELLOW}Please run this script from the project root or scripts directory${NC}"
    exit 1
fi

echo -e "${BOLD}🔧 Setting up Backend Development Environment...${NC}\n"

# Run dependency checker
echo -e "${BOLD}Checking backend dependencies...${NC}"
bash "$SCRIPT_DIR/check-dependencies.sh"

# Create and activate virtual environment
echo -e "\n${BOLD}Setting up Python virtual environment...${NC}"
cd "$BACKEND_DIR" || exit 1

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

# Install backend dependencies
echo -e "\n${BOLD}Installing backend dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Verify index.py exists
if [ ! -f "$BACKEND_DIR/index.py" ]; then
    echo -e "${RED}Error: index.py not found in backend directory${NC}"
    exit 1
fi

echo -e "\n${GREEN}${BOLD}✓ Backend setup complete!${NC}"
echo -e "\n${YELLOW}Important: You need to manually change to the backend directory:${NC}"
echo -e "\n${BOLD}Copy and paste these commands:${NC}"
echo -e "  cd $BACKEND_DIR"
echo -e "  source venv/bin/activate"
echo -e "  uvicorn index:app --reload --port 9090"

# Create a helper script that can be sourced
cat > "$SCRIPT_DIR/activate-backend.sh" << EOL
#!/bin/bash
cd "$BACKEND_DIR"
source venv/bin/activate
EOL

echo -e "\n${BOLD}Alternative: Source the helper script:${NC}"
echo -e "  source $SCRIPT_DIR/activate-backend.sh"
