#!/bin/bash

# Configuration
VENV_DIR="../backend/venv"
REQUIREMENTS_FILE="../backend/requirements.txt"
BACKEND_DIR="../backend"

# Function to display steps
echo_step() {
    echo "→ $1"
}

# Change to script directory
cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo_step "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
echo_step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Install or upgrade pip
echo_step "Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo_step "Installing requirements..."
if [ -f "$REQUIREMENTS_FILE" ]; then
    pip install -r "$REQUIREMENTS_FILE"
else
    echo "Error: requirements.txt not found at $REQUIREMENTS_FILE"
    exit 1
fi

# Change to backend directory
echo_step "Changing to backend directory..."
cd "$BACKEND_DIR" || exit 1

# Run the FastAPI application
echo_step "Starting FastAPI application..."
uvicorn index:app --reload --port 9090

# Note: The virtual environment will remain active until you close the terminal
# To deactivate manually, run: deactivate
