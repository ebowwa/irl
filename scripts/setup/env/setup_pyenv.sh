#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Checking for pyenv...${NC}"

# Check if pyenv is installed
if ! command -v pyenv &> /dev/null; then
    echo -e "${YELLOW}pyenv not found. Installing pyenv...${NC}"
    
    # Install pyenv using Homebrew
    if command -v brew &> /dev/null; then
        brew install pyenv
    else
        echo "Homebrew not found. Please install Homebrew first:"
        echo "Visit: https://brew.sh"
        exit 1
    fi
fi

# Add pyenv init to shell if not already present
if ! grep -q 'eval "$(pyenv init --path)"' ~/.zshrc &> /dev/null; then
    echo -e "${YELLOW}Adding pyenv init to ~/.zshrc...${NC}"
    echo '' >> ~/.zshrc
    echo '# pyenv initialization' >> ~/.zshrc
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
    echo 'eval "$(pyenv init -)"' >> ~/.zshrc
fi

# Get latest stable Python version
LATEST_PYTHON=$(pyenv install --list | grep -v '[a-zA-Z]' | grep -v - | tail -1 | tr -d '[[:space:]]')

# Check if Python version is installed
if ! pyenv versions | grep -q "$LATEST_PYTHON"; then
    echo -e "${YELLOW}Installing Python $LATEST_PYTHON...${NC}"
    pyenv install "$LATEST_PYTHON"
fi

# Set global Python version
echo -e "${YELLOW}Setting Python $LATEST_PYTHON as global version...${NC}"
pyenv global "$LATEST_PYTHON"

# Create or activate virtual environment
VENV_NAME="caringmind-env"
if [ ! -d "$(pyenv root)/versions/$LATEST_PYTHON/envs/$VENV_NAME" ]; then
    echo -e "${YELLOW}Creating virtual environment: $VENV_NAME${NC}"
    pyenv virtualenv "$LATEST_PYTHON" "$VENV_NAME"
fi

# Set local Python version to the virtualenv
echo -e "${YELLOW}Setting local Python version to $VENV_NAME${NC}"
pyenv local "$VENV_NAME"

echo -e "${GREEN}pyenv setup complete!${NC}"
echo -e "${GREEN}Python version: $(python --version)${NC}"
echo -e "${YELLOW}Note: You may need to restart your terminal or run:${NC}"
echo -e "${YELLOW}    source ~/.zshrc${NC}"
echo -e "${YELLOW}To activate the environment in new terminals, run:${NC}"
echo -e "${YELLOW}    pyenv activate $VENV_NAME${NC}"
