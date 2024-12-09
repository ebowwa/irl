#!/bin/bash

# Source the colors utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/colors.sh"

# Function to display cleanup progress
echo_step() {
    print_info "$1"
}

# Function to display success message
echo_success() {
    print_success "$1"
}

# Function to display warning message
echo_warning() {
    print_warning "$1"
}

# Function to kill process by port
kill_port() {
    local port=$1
    local pid=$(lsof -ti ":$port" 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo_step "Killing process on port $port (PID: $pid)..."
        if kill -9 $pid 2>/dev/null; then
            echo_success "Successfully killed process on port $port"
        else
            echo_warning "Failed to kill process on port $port"
        fi
    fi
}

# Function to clean Python cache in specific directory
clean_python_cache() {
    local dir=$1
    echo_step "Cleaning Python cache in $dir..."
    
    local pycache_count=0
    local pyc_count=0
    local pyo_count=0
    local pyd_count=0
    
    # Count and remove __pycache__ directories
    while IFS= read -r cache_dir; do
        ((pycache_count++))
        rm -rf "$cache_dir"
    done < <(find "$dir" -type d -name "__pycache__" 2>/dev/null)
    
    # Count and remove .pyc files
    while IFS= read -r pyc_file; do
        ((pyc_count++))
        rm -f "$pyc_file"
    done < <(find "$dir" -type f -name "*.pyc" 2>/dev/null)
    
    # Count and remove .pyo files
    while IFS= read -r pyo_file; do
        ((pyo_count++))
        rm -f "$pyo_file"
    done < <(find "$dir" -type f -name "*.pyo" 2>/dev/null)
    
    # Count and remove .pyd files
    while IFS= read -r pyd_file; do
        ((pyd_count++))
        rm -f "$pyd_file"
    done < <(find "$dir" -type f -name "*.pyd" 2>/dev/null)
    
    # Report results
    if [ $pycache_count -gt 0 ] || [ $pyc_count -gt 0 ] || [ $pyo_count -gt 0 ] || [ $pyd_count -gt 0 ]; then
        echo_success "Cleaned:"
        [ $pycache_count -gt 0 ] && echo -e "${BLUE}  • ${pycache_count} __pycache__ directories${NC}"
        [ $pyc_count -gt 0 ] && echo -e "${BLUE}  • ${pyc_count} .pyc files${NC}"
        [ $pyo_count -gt 0 ] && echo -e "${BLUE}  • ${pyo_count} .pyo files${NC}"
        [ $pyd_count -gt 0 ] && echo -e "${BLUE}  • ${pyd_count} .pyd files${NC}"
    else
        print_info "No Python cache files found in $dir"
    fi
}

# Change to script directory
cd "$(dirname "$0")"

print_header "Server Cleanup"

# Kill any running server processes
echo_step "Cleaning up server processes..."
kill_port 9090  # FastAPI server
if pkill -f "uvicorn" 2>/dev/null; then
    echo_success "Stopped uvicorn processes"
fi
if pkill -f "gunicorn" 2>/dev/null; then
    echo_success "Stopped gunicorn processes"
fi

# Clean backend-specific directories
echo_step "Cleaning backend artifacts..."
clean_python_cache "../backend"

# Clean temporary files
echo_step "Cleaning temporary files..."
temp_files_count=0
while IFS= read -r temp_file; do
    ((temp_files_count++))
    rm -f "$temp_file"
done < <(find "../backend" \( -name "*.log" -o -name "*.tmp" -o -name ".coverage" -o -name ".pytest_cache" \) 2>/dev/null)

if [ $temp_files_count -gt 0 ]; then
    echo_success "Removed $temp_files_count temporary files"
fi

# Clean database files if they're temporary
echo_step "Checking for temporary database files..."
db_files_count=0
while IFS= read -r db_file; do
    ((db_files_count++))
    rm -f "$db_file"
done < <(find "../backend" \( -name "*.db-journal" -o -name "test_*.db" \) 2>/dev/null)

if [ $db_files_count -gt 0 ]; then
    echo_success "Removed $db_files_count temporary database files"
fi

# Optional: Clean virtual environment (uncomment if needed)
# echo_step "Cleaning virtual environment..."
# if rm -rf "../backend/venv"; then
#     echo_success "Removed virtual environment"
# fi

print_header "Cleanup Complete"
echo_success "Server cleanup finished successfully!"
print_info "Run './run_backend.sh' to start the server again"
