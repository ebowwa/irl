#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Analyzing thread-related issues in the codebase...${NC}\n"

# Function to search for potential thread issues
search_thread_issues() {
    local dir="$1"
    
    echo -e "${YELLOW}Searching for potential thread issues in Swift files...${NC}"
    
    # Search for main thread violations
    echo -e "\n${GREEN}Checking for potential main thread violations:${NC}"
    echo -e "${YELLOW}DispatchQueue.main may indicate direct interaction with the main thread, which could lead to performance issues or UI freezes if not handled properly.${NC}"
    find "$dir" -name "*.swift" -type f -exec grep -l "DispatchQueue.main" {} \;
    
    # Search for @MainActor usage
    echo -e "\n${GREEN}Files using @MainActor:${NC}"
    echo -e "${YELLOW}@MainActor ensures that code is always executed on the main thread, typically required for UI-related tasks. Look for proper usage to avoid race conditions and unintended thread context switches.${NC}"
    find "$dir" -name "*.swift" -type f -exec grep -l "@MainActor" {} \;
    
    # Search for async/await usage
    echo -e "\n${GREEN}Files using async/await:${NC}"
    echo -e "${YELLOW}Async/await usage simplifies concurrency management but requires careful design to avoid deadlocks or unintended background thread usage.${NC}"
    find "$dir" -name "*.swift" -type f -exec grep -l "async" {} \;
    
    # Search for potential thread-unsafe property access
    echo -e "\n${GREEN}Potential thread-unsafe @Published property access:${NC}"
    echo -e "${YELLOW}@Published properties are often accessed in SwiftUI contexts. Ensure they are accessed on the main thread to prevent UI glitches or crashes.${NC}"
    find "$dir" -name "*.swift" -type f -exec grep -l "@Published" {} \;
    
    # Search for potential race conditions with UserDefaults
    echo -e "\n${GREEN}Potential UserDefaults race conditions:${NC}"
    echo -e "${YELLOW}UserDefaults can cause race conditions if accessed simultaneously from multiple threads. Check for synchronized access.${NC}"
    find "$dir" -name "*.swift" -type f -exec grep -l "UserDefaults" {} \;
}

# Main execution
PROJECT_DIR="/Users/ebowwa/caring"

if [ -d "$PROJECT_DIR" ]; then
    search_thread_issues "$PROJECT_DIR"
else
    echo -e "${RED}Error: Project directory not found${NC}"
    exit 1
fi

echo -e "\n${GREEN}Analysis complete!${NC}"
echo -e "${YELLOW}Note: This is a basic analysis. Manual code review is recommended for thorough thread safety verification.${NC}"
echo -e "${YELLOW}@MainActor:${NC} Use for functions or properties interacting with UI elements or shared state that must run on the main thread."
echo -e "${YELLOW}Async/await:${NC} Ensure proper task hierarchy and context switching to avoid unintended thread locking or priority inversions."
echo -e "${YELLOW}@Published:${NC} Monitor for threading issues in SwiftUI. Use Combine schedulers or explicitly run on the main thread if necessary."
echo -e "${YELLOW}UserDefaults:${NC} For thread-safe access, consider wrapping in a DispatchQueue or using synchronize() where appropriate."
