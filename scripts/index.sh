#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make all scripts executable
make_executable() {
    local script="$1"
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}Made executable:${NC} $(basename "$script")"
    fi
}

# Function to display script information
display_script_info() {
    local script="$1"
    local description="$2"
    echo -e "${BLUE}$(basename "$script"):${NC}"
    echo -e "  ${YELLOW}Description:${NC} $description"
    echo -e "  ${YELLOW}Usage:${NC} ./${script#"$SCRIPT_DIR/"}"
    echo ""
}

echo -e "${GREEN}=== CaringMind Scripts Index ===${NC}\n"

# Make all .sh files executable
find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;

# Index of scripts and their descriptions
# To add a new script, simply add a new display_script_info line below

display_script_info "$SCRIPT_DIR/clean_pycache.sh" \
    "Removes all Python cache files (__pycache__ directories and .pyc files) recursively"

display_script_info "$SCRIPT_DIR/setup_pyenv.sh" \
    "Sets up pyenv, installs latest Python version, and creates a virtual environment"

display_script_info "$SCRIPT_DIR/setup-dependencies.sh" \
    "Installs and sets up project dependencies"

display_script_info "$SCRIPT_DIR/index.sh" \
    "This script - Lists and describes all available scripts and makes them executable"

echo -e "${YELLOW}Note:${NC} All scripts have been made executable automatically."
echo -e "${YELLOW}To run a script, use:${NC} ./scripts/<script_name>"
