#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Create virtual environment if it doesn't exist
if [ ! -d "$REPO_ROOT/venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$REPO_ROOT/venv"
fi

# Activate virtual environment
source "$REPO_ROOT/venv/bin/activate"

# Install pre-commit
pip install pre-commit

# Copy hooks
echo "Installing git hooks..."
cp "$SCRIPT_DIR/pre-commit" "$REPO_ROOT/.git/hooks/"
chmod +x "$REPO_ROOT/.git/hooks/pre-commit"

# Copy pre-commit config if it exists
if [ -f "$SCRIPT_DIR/.pre-commit-config.yaml" ]; then
    cp "$SCRIPT_DIR/.pre-commit-config.yaml" "$REPO_ROOT/"
fi

echo "Git hooks installed successfully!"
