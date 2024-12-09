#!/bin/bash

# Text Colors
export BLACK='\033[0;30m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'
export GRAY='\033[0;90m'

# Bright Text Colors
export BRIGHT_BLACK='\033[1;30m'
export BRIGHT_RED='\033[1;31m'
export BRIGHT_GREEN='\033[1;32m'
export BRIGHT_YELLOW='\033[1;33m'
export BRIGHT_BLUE='\033[1;34m'
export BRIGHT_PURPLE='\033[1;35m'
export BRIGHT_CYAN='\033[1;36m'
export BRIGHT_WHITE='\033[1;37m'

# Background Colors
export BG_BLACK='\033[40m'
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'
export BG_PURPLE='\033[45m'
export BG_CYAN='\033[46m'
export BG_WHITE='\033[47m'

# Text Styles
export BOLD='\033[1m'
export DIM='\033[2m'
export ITALIC='\033[3m'
export UNDERLINE='\033[4m'
export BLINK='\033[5m'
export REVERSE='\033[7m'
export HIDDEN='\033[8m'
export STRIKE='\033[9m'

# Reset
export NC='\033[0m' # No Color
export RESET_ALL='\033[0m'
export RESET_BOLD='\033[21m'
export RESET_DIM='\033[22m'
export RESET_ITALIC='\033[23m'
export RESET_UNDERLINE='\033[24m'
export RESET_BLINK='\033[25m'
export RESET_REVERSE='\033[27m'
export RESET_HIDDEN='\033[28m'
export RESET_STRIKE='\033[29m'

# Basic print functions
print_black() { echo -e "${BLACK}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }
print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_blue() { echo -e "${BLUE}$1${NC}"; }
print_purple() { echo -e "${PURPLE}$1${NC}"; }
print_cyan() { echo -e "${CYAN}$1${NC}"; }
print_white() { echo -e "${WHITE}$1${NC}"; }
print_gray() { echo -e "${GRAY}$1${NC}"; }

# Style functions
print_bold() { echo -e "${BOLD}$1${NC}"; }
print_dim() { echo -e "${DIM}$1${NC}"; }
print_italic() { echo -e "${ITALIC}$1${NC}"; }
print_underline() { echo -e "${UNDERLINE}$1${NC}"; }

# Advanced formatting functions
print_header() {
    local text="$1"
    local padding=$(printf '%*s' $(((50-${#text})/2)))
    echo -e "\n${BOLD}${BLUE}$padding$text$padding${NC}\n"
}

print_success() {
    echo -e "${GREEN}${BOLD}✓ Success:${NC} $1"
}

print_error() {
    echo -e "${RED}${BOLD}✗ Error:${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}${BOLD}⚠ Warning:${NC} $1"
}

print_info() {
    echo -e "${CYAN}${BOLD}ℹ Info:${NC} $1"
}

print_debug() {
    echo -e "${GRAY}${BOLD}🔍 Debug:${NC} $1"
}

# Progress indicator
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${BLUE}["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' ' '
    printf "] ${percentage}%%${NC}"
}

# Example usage:
# source ./utils/colors.sh
# print_header "Welcome to My Script"
# print_success "Task completed successfully"
# print_error "Something went wrong"
# print_warning "Disk space is running low"
# print_info "Processing files..."
# print_debug "Variable x = 42"
#
# # Progress bar example:
# for i in {1..100}; do
#     progress_bar $i 100
#     sleep 0.1
# done
#
# # Spinner example:
# (sleep 5) &
# show_spinner $!
