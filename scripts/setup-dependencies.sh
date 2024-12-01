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

# Function to check Python package
check_python_package() {
    local package=$1
    if python3 -c "import $package" 2>/dev/null; then
        print_status "Python package: $package" true
    else
        print_status "Python package: $package" false
    fi
}

# Function to install package manager
install_package_manager() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command_exists brew; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt-get; then
            sudo apt-get update
        elif command_exists dnf; then
            sudo dnf check-update
        elif command_exists yum; then
            sudo yum check-update
        fi
    fi
}

# Function to install a package
install_package() {
    local package=$1
    local brew_name=${2:-$1}
    local apt_name=${3:-$1}
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ $brew_name == *"--cask"* ]]; then
            brew install --cask ${brew_name#"--cask "}
        else
            brew install $brew_name
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt-get; then
            sudo apt-get install -y $apt_name
        elif command_exists dnf; then
            sudo dnf install -y $apt_name
        elif command_exists yum; then
            sudo yum install -y $apt_name
        fi
    fi
}

# Main script
echo -e "${BOLD}Checking development environment...${NC}\n"

# Check OS
echo -e "${BOLD}Operating System:${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macOS detected"
    # Check for Homebrew
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Linux detected"
    # Check for package manager
    if command_exists apt-get; then
        echo "Using apt package manager"
    elif command_exists dnf; then
        echo "Using dnf package manager"
    elif command_exists yum; then
        echo "Using yum package manager"
    else
        echo "No supported package manager found"
        exit 1
    fi
else
    echo "Unsupported operating system"
    exit 1
fi
echo

# Check core development tools
echo -e "${BOLD}Checking core development tools:${NC}"
check_python_version
print_status "git" $(command_exists git)
print_status "node" $(command_exists node)
print_status "npm" $(command_exists npm)
print_status "pnpm" $(command_exists pnpm)
print_status "poetry" $(command_exists poetry)
echo

# Check media processing tools
echo -e "${BOLD}Checking media processing tools:${NC}"
print_status "sox" $(command_exists sox)
print_status "ffmpeg" $(command_exists ffmpeg)
print_status "convert" $(command_exists convert) # ImageMagick
print_status "cwebp" $(command_exists cwebp)
echo

# Check network tools
echo -e "${BOLD}Checking network tools:${NC}"
print_status "curl" $(command_exists curl)
print_status "wget" $(command_exists wget)
print_status "ngrok" $(command_exists ngrok)
print_status "jq" $(command_exists jq)
print_status "http" $(command_exists http) # HTTPie
echo

# Check database tools
echo -e "${BOLD}Checking database tools:${NC}"
print_status "sqlite3" $(command_exists sqlite3)
echo

# Check Python database packages
echo -e "\n${BOLD}Checking Python database packages...${NC}"
check_python_package "sqlalchemy"
check_python_package "asyncpg"
check_python_package "aiosqlite"
check_python_package "greenlet"
check_python_package "databases"

# Check security tools
echo -e "${BOLD}Checking security tools:${NC}"
print_status "openssl" $(command_exists openssl)
print_status "mkcert" $(command_exists mkcert)
echo

# Print summary
echo -e "${BOLD}Summary:${NC}"
echo -e "${GREEN}$INSTALLED_COUNT installed dependencies${NC}"
echo -e "${RED}$MISSING_COUNT missing dependencies${NC}"
echo

# Ask to install missing dependencies
if [ $MISSING_COUNT -gt 0 ]; then
    echo -e "${YELLOW}Would you like to install missing dependencies? (y/n)${NC}"
    read -r install_missing
    if [[ $install_missing =~ ^[Yy]$ ]]; then
        echo "Installing missing dependencies..."
        install_package_manager
        
        for item in "${MISSING_ITEMS[@]}"; do
            echo "Installing $item..."
            case $item in
                "Python 3.12+")
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        install_package python python@3.12
                    else
                        # For Linux, we might need to use a PPA or pyenv
                        echo "Please install Python 3.12+ manually"
                    fi
                    ;;
                "poetry")
                    curl -sSL https://install.python-poetry.org | python3 -
                    ;;
                "pnpm")
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        install_package pnpm
                    else
                        curl -fsSL https://get.pnpm.io/install.sh | sh -
                    fi
                    ;;
                "ngrok")
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        install_package ngrok "--cask ngrok"
                    else
                        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
                            sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
                            echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
                            sudo tee /etc/apt/sources.list.d/ngrok.list && \
                            sudo apt update && sudo apt install ngrok
                    fi
                    ;;
                "convert")
                    install_package imagemagick imagemagick imagemagick
                    ;;
                "http")
                    install_package httpie httpie python3-httpie
                    ;;
                *)
                    install_package "$item"
                    ;;
            esac
        done
        
        echo -e "\n${GREEN}Installation complete! Please restart your terminal.${NC}"
    fi
fi

# Verify development environment
echo -e "\n${BOLD}Verifying development environment:${NC}"
if command_exists python3; then
    echo "Python version: $(python3 --version)"
fi
if command_exists node; then
    echo "Node.js version: $(node --version)"
fi
if command_exists npm; then
    echo "npm version: $(npm --version)"
fi
if command_exists pnpm; then
    echo "pnpm version: $(pnpm --version)"
fi
if command_exists poetry; then
    echo "Poetry version: $(poetry --version)"
fi

echo -e "\n${BOLD}Setup complete!${NC}"
