#!/bin/bash

# Function to display cleanup progress
echo_step() {
    echo "🔄 $1"
}

# Function to kill process by port
kill_port() {
    local port=$1
    local pid=$(lsof -ti ":$port" 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo_step "Killing process on port $port (PID: $pid)..."
        kill -9 $pid 2>/dev/null
    fi
}

# Function to clean Python cache in specific directory
clean_python_cache() {
    local dir=$1
    echo_step "Cleaning Python cache in $dir..."
    find "$dir" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find "$dir" -type f -name "*.pyc" -delete 2>/dev/null
    find "$dir" -type f -name "*.pyo" -delete 2>/dev/null
    find "$dir" -type f -name "*.pyd" -delete 2>/dev/null
}

# Change to script directory
cd "$(dirname "$0")"

echo "🧹 Starting server cleanup..."

# Kill any running server processes
echo_step "Cleaning up server processes..."
kill_port 9090  # FastAPI server
pkill -f "uvicorn" 2>/dev/null
pkill -f "gunicorn" 2>/dev/null

# Clean backend-specific directories
echo_step "Cleaning backend artifacts..."
clean_python_cache "../backend"

# Clean temporary files
echo_step "Cleaning temporary files..."
find "../backend" -type f -name "*.log" -delete 2>/dev/null
find "../backend" -type f -name "*.tmp" -delete 2>/dev/null
find "../backend" -type f -name ".coverage" -delete 2>/dev/null
find "../backend" -type f -name ".pytest_cache" -delete 2>/dev/null

# Clean database files if they're temporary
echo_step "Checking for temporary database files..."
find "../backend" -type f -name "*.db-journal" -delete 2>/dev/null
find "../backend" -type f -name "test_*.db" -delete 2>/dev/null

# Optional: Clean virtual environment (uncomment if needed)
# echo_step "Cleaning virtual environment..."
# rm -rf "../backend/venv"

echo "✨ Server cleanup complete!"
echo "Note: Run './run_backend.sh' to start the server again"
