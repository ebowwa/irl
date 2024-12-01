#!/bin/bash

# Function to display steps
echo_step() {
    echo "🔄 $1"
}

# Function to get user choice
get_user_choice() {
    local prompt=$1
    local max=$2
    while true; do
        read -p "$prompt" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$max" ]; then
            echo "$choice"
            return
        fi
        echo "Please enter a number between 1 and $max"
    done
}

# Function to analyze changes and generate commit message
analyze_changes() {
    local changes=""
    
    # Check for package changes
    if git diff --cached | grep -q "requirements.txt\|package.json"; then
        changes+="📦 Updated dependencies. "
    fi
    
    # Check for configuration changes
    if git diff --cached | grep -q "\.env\|\.config\|\.yml\|\.json"; then
        changes+="⚙️ Modified configuration. "
    fi
    
    # Check for documentation changes
    if git diff --cached | grep -q "\.md\|docs/"; then
        changes+="📚 Updated documentation. "
    fi
    
    # Check for test changes
    if git diff --cached | grep -q "test_\|spec\|_test"; then
        changes+="🧪 Modified tests. "
    fi
    
    # Check for specific directory changes
    if git diff --cached | grep -q "^diff.*backend/"; then
        changes+="🔧 Backend changes: "
        # Get summary of Python file changes
        local backend_changes=$(git diff --cached --stat backend/ | grep "\.py" | awk '{print $1}' | xargs -n1 basename 2>/dev/null)
        if [ ! -z "$backend_changes" ]; then
            changes+="Modified $(echo $backend_changes | tr '\n' ',' | sed 's/,/, /g'). "
        fi
    fi
    
    if git diff --cached | grep -q "^diff.*clients/caringmindWeb/"; then
        changes+="🌐 Web app changes. "
    fi
    
    if git diff --cached | grep -q "^diff.*clients/irlapp/"; then
        changes+="📱 iOS app changes. "
    fi
    
    # If no specific changes detected, analyze diff stats
    if [ -z "$changes" ]; then
        local files_changed=$(git diff --cached --stat | tail -n1)
        changes+="🔄 General updates: $files_changed"
    fi
    
    echo "$changes"
}

# Function to ensure we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "❌ Error: Not a git repository"
        exit 1
    fi
}

# Function to handle unstaged changes
handle_unstaged_changes() {
    if [ -n "$(git status --porcelain)" ]; then
        echo_step "Unstaged changes detected. Would you like to:"
        echo "  1) Stage and commit changes"
        echo "  2) Stash changes"
        echo "  3) View changes"
        echo "  4) Cancel"
        
        choice=$(get_user_choice "Choose (1-4): " 4)
        
        case $choice in
            1)
                echo_step "Staging changes..."
                git add .
                commit_changes
                ;;
            2)
                echo_step "Stashing changes..."
                git stash
                ;;
            3)
                git status
                git diff
                handle_unstaged_changes
                ;;
            4)
                echo "Operation cancelled"
                exit 0
                ;;
        esac
    fi
}

# Function to commit changes
commit_changes() {
    # Generate commit message
    echo_step "Analyzing changes..."
    commit_msg=$(analyze_changes)
    
    echo "📝 Commit message: $commit_msg"
    echo_step "Would you like to:"
    echo "  1) Use this commit message"
    echo "  2) Modify the message"
    echo "  3) Cancel commit"
    choice=$(get_user_choice "Choose (1-3): " 3)
    
    case $choice in
        1)
            git commit -m "$commit_msg"
            ;;
        2)
            read -p "Enter your commit message: " custom_msg
            git commit -m "$custom_msg"
            ;;
        3)
            echo "Commit cancelled"
            exit 0
            ;;
    esac
    
    echo_step "Pushing changes..."
    if ! git push; then
        echo "❌ Error: Failed to push changes. Please pull latest changes and try again."
        exit 1
    fi
    
    echo "✨ Changes successfully pushed!"
}

# Main execution
check_git_repo

# Handle any unstaged changes first
handle_unstaged_changes

# Fetch and pull changes
echo_step "Fetching latest changes..."
git fetch --all

echo_step "Pulling latest changes..."
if ! git pull; then
    echo "❌ Error: Failed to pull changes. Please resolve conflicts manually."
    exit 1
fi

# Stage changes if there are any
if [ -n "$(git status --porcelain)" ]; then
    echo_step "Staging changes..."
    git add .
    
    # Commit changes
    commit_changes
else
    echo "✨ Nothing to commit. Working tree clean."
fi
