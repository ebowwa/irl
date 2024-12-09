#!/bin/bash

<<<<<<< HEAD
# Find and remove all __pycache__ directories
find . -type d -name "__pycache__" -exec rm -rf {} +

# Find and remove all .pyc files
find . -type f -name "*.pyc" -exec rm -f {} +

echo "Python cache files have been cleaned!"
=======
# Source the colors utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/colors.sh"

print_header "Python Cache Cleaning"

# Initialize counters
pycache_count=0
pyc_count=0

print_info "Scanning for Python cache files..."

# Find and count __pycache__ directories
print_info "Looking for __pycache__ directories..."
while IFS= read -r dir; do
    ((pycache_count++))
    rm -rf "$dir"
    printf "\r${CYAN}Found and removed ${pycache_count} __pycache__ directories${NC}"
done < <(find . -type d -name "__pycache__" 2>/dev/null)
echo # New line after progress

# Find and count .pyc files
print_info "Looking for .pyc files..."
while IFS= read -r file; do
    ((pyc_count++))
    rm -f "$file"
    printf "\r${CYAN}Found and removed ${pyc_count} .pyc files${NC}"
done < <(find . -type f -name "*.pyc" 2>/dev/null)
echo # New line after progress

# Summary
echo
if [ $pycache_count -eq 0 ] && [ $pyc_count -eq 0 ]; then
    print_info "No Python cache files found."
else
    print_success "Clean-up completed!"
    print_info "Removed:"
    [ $pycache_count -gt 0 ] && echo -e "${BLUE}  • ${pycache_count} __pycache__ directories${NC}"
    [ $pyc_count -gt 0 ] && echo -e "${BLUE}  • ${pyc_count} .pyc files${NC}"
fi
echo
>>>>>>> a4553c2 (app client new iteration replacement)
