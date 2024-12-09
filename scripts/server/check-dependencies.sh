#!/bin/bash

# Source the colors utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/colors.sh"

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
        print_success "$name is installed"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        INSTALLED_ITEMS+=("$name")
    else
        print_error "$name is not installed"
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
        # Use awk for version comparison to handle floating point
        if awk -v ver="$version" 'BEGIN { exit !(ver >= 18.0) }'; then
            print_status "Node.js ($version)" true
        else
            print_status "Node.js 18+" false
        fi
    else
        print_status "Node.js 18+" false
    fi
}

# Main script
print_header "Development Dependencies Check"

print_info "Checking development tools..."
echo

# Check basic development tools
command_exists git && print_status "Git" true || print_status "Git" false
command_exists make && print_status "Make" true || print_status "Make" false
check_python_version
check_node_version
command_exists pnpm && print_status "pnpm" true || print_status "pnpm" false

# Summary
echo
print_header "Summary"

if [ $INSTALLED_COUNT -gt 0 ]; then
    echo -e "${GREEN}${BOLD}✓ Installed Tools (${INSTALLED_COUNT}):${NC}"
    printf "${BLUE}  • %s${NC}\n" "${INSTALLED_ITEMS[@]}"
fi

if [ $MISSING_COUNT -gt 0 ]; then
    echo
    echo -e "${RED}${BOLD}✗ Missing Tools (${MISSING_COUNT}):${NC}"
    printf "${RED}  • %s${NC}\n" "${MISSING_ITEMS[@]}"
    echo
    print_warning "Please install the missing tools before proceeding"
fi
