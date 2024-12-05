#!/bin/bash
# NOTE: OUR CODE BASE IS LARGE, it encompases a swift mobile app, a nextjs frontend client and a python backend
# Function to display steps
echo_step() {
    echo " $1"
}

# Function to detect branch type
detect_branch_type() {
    local branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $branch == "feature/"* ]]; then
        echo "feature"
    elif [[ $branch == "bugfix/"* ]]; then
        echo "bugfix"
    elif [[ $branch == "hotfix/"* ]]; then
        echo "hotfix"
    elif [[ $branch == "release/"* ]]; then
        echo "release"
    else
        echo "main"
    fi
}

# Function to auto-create branch based on changes
auto_create_branch() {
    local changes=$(git status --porcelain)
    local branch_name=""
    
    # Check if we're already on a feature/bugfix branch
    if [[ $(git rev-parse --abbrev-ref HEAD) != "main" ]]; then
        return
    fi
    
    # Analyze changes to determine branch type
    if echo "$changes" | grep -q "test_"; then
        branch_name="feature/add-tests-$(date +%Y%m%d)"
    elif echo "$changes" | grep -q "fix\|bug\|error"; then
        branch_name="bugfix/fix-$(date +%Y%m%d)"
    elif echo "$changes" | grep -q "requirements.txt\|package.json"; then
        branch_name="feature/update-deps-$(date +%Y%m%d)"
    elif echo "$changes" | grep -q "\.md$"; then
        branch_name="feature/update-docs-$(date +%Y%m%d)"
    fi
    
    if [ ! -z "$branch_name" ]; then
        echo_step "Creating branch $branch_name based on changes..."
        git checkout -b "$branch_name"
    fi
}

# Enhanced change analysis with AI-like categorization
analyze_changes() {
    local changes=""
    local impact_level="minor"
    local is_breaking_change=false
    local files_changed=$(git diff --cached --name-only)
    
    # Detect breaking changes
    if git diff --cached | grep -q "^- \|^+.*BREAKING"; then
        is_breaking_change=true
        impact_level="major"
    fi
    
    # Smart categorization based on patterns
    if git diff --cached | grep -q "requirements.txt\|package.json"; then
        changes+=" Dependencies: "
        local deps=$(git diff --cached requirements.txt | grep "^+" | cut -d= -f1 | tr '\n' ',' | sed 's/,$//')
        [ ! -z "$deps" ] && changes+="Updated $deps. "
    fi
    
    if git diff --cached | grep -q "\.env\|\.config\|\.yml\|\.json"; then
        changes+=" Config: "
        local configs=$(git diff --cached --name-only | grep "\.env\|\.config\|\.yml\|\.json" | tr '\n' ',' | sed 's/,$//')
        [ ! -z "$configs" ] && changes+="Modified $configs. "
    fi
    
    # Auto-detect test coverage changes
    local test_files=$(echo "$files_changed" | grep "_test\|test_\|spec")
    if [ ! -z "$test_files" ]; then
        changes+=" Tests: "
        local test_count=$(echo "$test_files" | wc -l)
        changes+="Modified $test_count test files. "
    fi
    
    # Smart backend change detection
    if echo "$files_changed" | grep -q "\.py$\|\.js$\|\.go$"; then
        changes+=" Code: "
        local backend_files=$(echo "$files_changed" | grep "\.py$\|\.js$\|\.go$" | tr '\n' ',' | sed 's/,$//')
        [ ! -z "$backend_files" ] && changes+="Modified $backend_files. "
    fi
    
    # Auto-detect security improvements
    if git diff --cached | grep -q "security\|auth\|encrypt\|password\|token"; then
        changes+=" Security: Enhanced security measures. "
        impact_level="major"
    fi
    
    # Add impact level prefix
    if [ "$is_breaking_change" = true ]; then
        changes=" BREAKING CHANGE! $changes"
    elif [ "$impact_level" = "major" ]; then
        changes=" Major: $changes"
    fi
    
    echo "$changes"
}

# Function to auto-commit with smart messages
auto_commit() {
    local commit_msg=$(analyze_changes)
    local branch_type=$(detect_branch_type)
    
    # Add conventional commit prefix based on branch type
    case $branch_type in
        "feature")
            commit_msg="feat: $commit_msg"
            ;;
        "bugfix")
            commit_msg="fix: $commit_msg"
            ;;
        "hotfix")
            commit_msg="hotfix: $commit_msg"
            ;;
        "release")
            commit_msg="release: $commit_msg"
            ;;
    esac
    
    echo_step "Auto-committing changes..."
    git commit -m "$commit_msg"
}

# Function to ensure we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo " Error: Not a git repository"
        exit 1
    fi
}

# Function to handle untracked files
handle_untracked_files() {
    local untracked=$(git ls-files --others --exclude-standard)
    if [ ! -z "$untracked" ]; then
        echo_step "Found untracked files, adding them..."
        echo "$untracked" | while read -r file; do
            if [ -f "$file" ]; then
                git add "$file"
                echo "Added: $file"
            fi
        done
        return 0
    fi
    return 1
}

# Main execution
check_git_repo

echo_step "Fetching latest changes..."
git fetch

echo_step "Pulling latest changes..."
git pull

# Handle untracked files before staging
handle_untracked_files

echo_step "Staging changes..."
git add -A

echo_step "Auto-committing changes..."
auto_commit

echo_step "Pushing changes..."
git push

echo_step "Changes successfully pushed!"
