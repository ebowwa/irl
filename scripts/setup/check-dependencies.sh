#!/bin/bash

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Initialize counters
INSTALLED_COUNT=0
MISSING_COUNT=0
INSTALLED_ITEMS=()
MISSING_ITEMS=()

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    local name=$1
    local exists=$2
    if [ "$exists" = true ]; then
        echo -e "${GREEN}✓${NC} $name is installed"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        INSTALLED_ITEMS+=("$name")
    else
        echo -e "${RED}✗${NC} $name is not installed"
        MISSING_COUNT=$((MISSING_COUNT + 1))
        MISSING_ITEMS+=("$name")
    fi
}

# Function to check Python version
check_python_version() {
    if command_exists python3; then
        local version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        if [ "$(echo "$version >= 3.12" | bc)" -eq 1 ]; then
            print_status "Python ($version)" true
        else
            print_status "Python 3.12+" false
        fi
    else
        print_status "Python 3.12+" false
    fi
}

# Function to check Node.js version
check_node_version() {
    if command_exists node; then
        local version=$(node -v | cut -d'v' -f2)
        if [ "$(echo "$version >= 18.0.0" | bc)" -eq 1 ]; then
            print_status "Node.js ($version)" true
        else
            print_status "Node.js 18+" false
        fi
    else
        print_status "Node.js 18+" false
    fi
}

# Main script
echo -e "${BOLD}Checking development dependencies...${NC}\n"

# Check basic development tools
command_exists git && print_status "Git" true || print_status "Git" false
command_exists make && print_status "Make" true || print_status "Make" false
check_python_version
check_node_version
command_exists pnpm && print_status "pnpm" true || print_status "pnpm" false

# Summary
echo -e "\n${BOLD}Summary:${NC}"
echo -e "${GREEN}✓ $INSTALLED_COUNT tools installed${NC}"
if [ $MISSING_COUNT -gt 0 ]; then
    echo -e "${RED}✗ $MISSING_COUNT tools missing${NC}"
    echo -e "\nMissing tools:"
    printf '%s\n' "${MISSING_ITEMS[@]/#/  - }"
fi
