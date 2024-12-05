#!/bin/bash

# Configuration
BASE_URL="http://localhost:9090/production/v1"
TEST_AUDIO_FILE="/Users/ebowwa/caringmind/public/audio_file.ogg"
INVALID_AUDIO_FILE="/nonexistent/file.ogg"
LARGE_FILE="/tmp/large_audio.ogg"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2 passed${NC}"
    else
        echo -e "${RED}✗ $2 failed${NC}"
        echo "Error response:"
        echo "$3"
    fi
}

echo "Running Gemini Audio API Tests..."
echo "================================"

# Test 1: Process Audio URI with valid file
echo -e "\n1. Testing Process Audio URI endpoint with valid file"
URI_RESPONSE=$(curl -s -X POST "${BASE_URL}/process-audio-uri" \
    -H "Content-Type: application/json" \
    -d "{\"file_uri\": \"file://${TEST_AUDIO_FILE}\"}")

if echo "$URI_RESPONSE" | grep -q "success"; then
    print_result 0 "Process Audio URI (Valid File)" "$URI_RESPONSE"
else
    print_result 1 "Process Audio URI (Valid File)" "$URI_RESPONSE"
fi

# Test 2: Process Audio File Upload
echo -e "\n2. Testing Process Audio File Upload endpoint"
UPLOAD_RESPONSE=$(curl -s -X POST "${BASE_URL}/process-audio" \
    -F "files=@${TEST_AUDIO_FILE};type=audio/ogg" \
    -F "prompt_type=transcription_v1")

if echo "$UPLOAD_RESPONSE" | grep -q "success"; then
    print_result 0 "Process Audio File Upload" "$UPLOAD_RESPONSE"
else
    print_result 1 "Process Audio File Upload" "$UPLOAD_RESPONSE"
fi

# Test 3: Invalid URI Test (404 Error Expected)
echo -e "\n3. Testing Invalid URI (Should return 404)"
INVALID_URI_RESPONSE=$(curl -s -w "%{http_code}" -X POST "${BASE_URL}/process-audio-uri" \
    -H "Content-Type: application/json" \
    -d "{\"file_uri\": \"file://${INVALID_AUDIO_FILE}\"}")

HTTP_CODE=${INVALID_URI_RESPONSE: -3}
RESPONSE_BODY=${INVALID_URI_RESPONSE:0:(-3)}

if [ "$HTTP_CODE" -eq 404 ]; then
    print_result 0 "Invalid URI Test (404 Expected)" "$RESPONSE_BODY"
else
    print_result 1 "Invalid URI Test (404 Expected)" "Got HTTP $HTTP_CODE instead of 404. Response: $RESPONSE_BODY"
fi

# Test 4: Invalid File Type Test (400 Error Expected)
echo -e "\n4. Testing Invalid File Type (Should return 400)"
touch /tmp/test.txt
INVALID_TYPE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "${BASE_URL}/process-audio-uri" \
    -H "Content-Type: application/json" \
    -d "{\"file_uri\": \"file:///tmp/test.txt\"}")

HTTP_CODE=${INVALID_TYPE_RESPONSE: -3}
RESPONSE_BODY=${INVALID_TYPE_RESPONSE:0:(-3)}

if [ "$HTTP_CODE" -eq 400 ]; then
    print_result 0 "Invalid File Type Test (400 Expected)" "$RESPONSE_BODY"
else
    print_result 1 "Invalid File Type Test (400 Expected)" "Got HTTP $HTTP_CODE instead of 400. Response: $RESPONSE_BODY"
fi
rm /tmp/test.txt

# Test 5: Large File Test (413 Error Expected)
echo -e "\n5. Testing Large File (Should return 413)"
dd if=/dev/zero of=$LARGE_FILE bs=1M count=101 2>/dev/null
LARGE_FILE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "${BASE_URL}/process-audio-uri" \
    -H "Content-Type: application/json" \
    -d "{\"file_uri\": \"file://${LARGE_FILE}\"}")

HTTP_CODE=${LARGE_FILE_RESPONSE: -3}
RESPONSE_BODY=${LARGE_FILE_RESPONSE:0:(-3)}

if [ "$HTTP_CODE" -eq 413 ]; then
    print_result 0 "Large File Test (413 Expected)" "$RESPONSE_BODY"
else
    print_result 1 "Large File Test (413 Expected)" "Got HTTP $HTTP_CODE instead of 413. Response: $RESPONSE_BODY"
fi
rm $LARGE_FILE

echo -e "\nTests completed!"
