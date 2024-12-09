#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Check if websocat is installed
if ! command -v websocat &> /dev/null; then
    echo -e "${RED}websocat is not installed. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install websocat
    else
        echo -e "${RED}Please install websocat manually:${NC}"
        echo "Visit: https://github.com/vi/websocat/releases"
        exit 1
    fi
fi

echo -e "${BOLD}Testing WebSocket Ping endpoint...${NC}"

# Test the WebSocket connection
echo -e "\n${BOLD}Connecting to WebSocket...${NC}"
(echo "PING"; sleep 1; echo "Hello World"; sleep 1) | \
    websocat ws://localhost:9090/ws/ping | \
    while IFS= read -r line; do
        if [ "$line" = "PONG" ]; then
            echo -e "${GREEN}✓ Received PONG response${NC}"
        else
            echo -e "Received: $line"
        fi
    done

echo -e "\n${BOLD}Test completed${NC}"
