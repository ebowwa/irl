#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test configuration
API_PORT=9090
BASE_URL="http://localhost:${API_PORT}"
TEST_AUDIO_FILE="./test_files/test_audio.wav"

# Function to check if the server is running on the specified port
check_server() {
    if nc -z localhost $API_PORT 2>/dev/null; then
        echo -e "${GREEN}✓ Server is running on port $API_PORT${NC}"
        return 0
    else
        echo -e "${RED}✗ Server is not running on port $API_PORT${NC}"
        return 1
    fi
}

# Function to test an endpoint
test_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local expected_status=${3:-200}
    
    echo "Testing $method $endpoint..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$BASE_URL$endpoint")
    
    if [ "$response" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ $method $endpoint returned $response (expected $expected_status)${NC}"
        return 0
    else
        echo -e "${RED}✗ $method $endpoint returned $response (expected $expected_status)${NC}"
        return 1
    fi
}

# Function to test prompt schema endpoints
test_prompt_schemas() {
    # Test getting default prompt schema
    echo "Testing prompt schema endpoints..."
    
    # Test GET prompt schema
    response=$(curl -s -X GET "$BASE_URL/production/v1/prompt-schema/transcription_v1")
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        echo -e "${GREEN}✓ GET prompt schema successful${NC}"
    else
        echo -e "${RED}✗ GET prompt schema failed${NC}"
        return 1
    fi
    
    # Test POST prompt schema (should return 405 for default schema)
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d '{"prompt_text": "test"}' \
        "$BASE_URL/production/v1/prompt-schema/transcription_v1")
    
    if [ "$status_code" -eq 405 ]; then
        echo -e "${GREEN}✓ POST prompt schema protection working (got 405 as expected)${NC}"
    else
        echo -e "${RED}✗ POST prompt schema protection failed (got $status_code, expected 405)${NC}"
        return 1
    fi
}

# Function to test audio processing endpoint
test_audio_processing() {
    echo "Testing audio processing endpoint..."
    
    # Create test audio file if it doesn't exist
    mkdir -p ./test_files
    if [ ! -f "$TEST_AUDIO_FILE" ]; then
        # Generate a simple test WAV file using sox
        which sox > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            sox -n "$TEST_AUDIO_FILE" synth 3 sine 440
            echo -e "${GREEN}✓ Created test audio file${NC}"
        else
            echo -e "${RED}✗ Sox not installed, skipping audio test file generation${NC}"
            return 1
        fi
    fi
    
    # Test audio processing endpoint with proper form data
    if [ -f "$TEST_AUDIO_FILE" ]; then
        response=$(curl -s -w "%{http_code}" -X POST \
            -H "Content-Type: multipart/form-data" \
            -F "files=@$TEST_AUDIO_FILE" \
            -F 'audio_processing_request={"prompt_type":"transcription_v1","model_name":"gemini-1.5-flash","temperature":0.7,"top_p":0.95,"top_k":40,"max_output_tokens":8192}' \
            "$BASE_URL/production/v1/process-audio")
        
        http_code=${response: -3}
        if [ "$http_code" -eq 200 ]; then
            echo -e "${GREEN}✓ Audio processing endpoint working${NC}"
            return 0
        else
            echo -e "${RED}✗ Audio processing endpoint failed (status: $http_code)${NC}"
            # Print response body for debugging
            echo "Response: ${response%???}"
            return 1
        fi
    else
        echo -e "${RED}✗ Test audio file not found${NC}"
        return 1
    fi
}

# Main test execution
echo "Starting API tests on port $API_PORT..."

# Check if server is running
if ! check_server; then
    echo "Please ensure the server is running on port $API_PORT"
    exit 1
fi

# Run tests
failures=0

# Test basic endpoints
test_endpoint "/health" || ((failures++))
test_endpoint "/production/v1/prompt-schema/transcription_v1" || ((failures++))

# Test prompt schema endpoints
test_prompt_schemas || ((failures++))

# Test audio processing
test_audio_processing || ((failures++))

# Report results
echo
if [ $failures -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$failures test(s) failed${NC}"
    exit 1
fi
