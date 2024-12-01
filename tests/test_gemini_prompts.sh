#!/bin/bash

echo "Running Prompt Schema Tests..."
echo "============================="
echo

# Function to format JSON response
format_response() {
    if [ -z "$1" ]; then
        echo "Empty response"
        return
    fi
    
    # Try to parse as JSON, if it fails, show raw response
    if echo "$1" | jq '.' >/dev/null 2>&1; then
        echo "$1" | jq '.'
    else
        echo "$1"
    fi
}

# Test 1: Default Prompt Type
echo "1. Testing Default Prompt Type"
response=$(curl -s -X POST http://localhost:9090/production/v1/process-audio \
  -H "Content-Type: multipart/form-data" \
  -H "Accept: application/json" \
  --form-string 'audio_processing_request={"model_config":{"protected_namespaces":[],"from_attributes":true,"json_schema_extra":{"example":{"prompt_type":"transcription_v1","model_name":"gemini-1.5-flash","temperature":0.7}}},"prompt_type":"transcription_v1","model_name":"gemini-1.5-flash","temperature":0.7,"top_p":0.95,"top_k":40,"max_output_tokens":8192}' \
  -F "files=@/Users/ebowwa/caringmind/public/audio_file.ogg")
echo "Response:"
format_response "$response"

# Test 2: Create Custom Prompt Schema
echo -e "\n2. Testing Create Custom Prompt Schema"
response=$(curl -v -X POST http://localhost:9090/production/v1/prompt-schema \
  -H "Content-Type: application/json" \
  -d '{
    "prompt_type": "test_custom_prompt",
    "prompt_text": "Analyze this audio and provide: 1) Main topics discussed 2) Speaker emotions 3) Key insights",
    "response_schema": {
      "type": "object",
      "properties": {
        "main_topics": {
          "type": "array",
          "items": {"type": "string"}
        },
        "emotions": {
          "type": "object"
        },
        "key_insights": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    }
  }')
echo "Response:"
format_response "$response"

# Test 3: Create Default Prompt Type (Should Fail)
echo -e "\n3. Testing Create Default Prompt Type (Should Fail)"
response=$(curl -v -X POST http://localhost:9090/production/v1/prompt-schema \
  -H "Content-Type: application/json" \
  -d '{
    "prompt_type": "transcription_v1",
    "prompt_text": "This should fail",
    "response_schema": {}
  }')
echo "Response:"
format_response "$response"

# Test 4: Get Custom Prompt Schema
echo -e "\n4. Testing Get Custom Prompt Schema"
response=$(curl -v -X GET http://localhost:9090/production/v1/prompt-schema/test_custom_prompt)
echo "Response:"
format_response "$response"

# Test 5: Get Non-existent Prompt Schema
echo -e "\n5. Testing Get Non-existent Prompt Schema"
response=$(curl -v -X GET http://localhost:9090/production/v1/prompt-schema/nonexistent_prompt)
echo "Response:"
format_response "$response"

# Test 6: Update Custom Prompt Schema
echo -e "\n6. Testing Update Custom Prompt Schema"
response=$(curl -v -X PUT http://localhost:9090/production/v1/prompt-schema/test_custom_prompt \
  -H "Content-Type: application/json" \
  -d '{
    "prompt_text": "Updated prompt text for audio analysis",
    "response_schema": {
      "type": "object",
      "properties": {
        "main_topics": {
          "type": "array",
          "items": {"type": "string"}
        },
        "emotions": {
          "type": "object"
        },
        "key_insights": {
          "type": "array",
          "items": {"type": "string"}
        },
        "additional_notes": {
          "type": "string"
        }
      }
    }
  }')
echo "Response:"
format_response "$response"

# Test 7: Update Default Prompt Type (Should Fail)
echo -e "\n7. Testing Update Default Prompt Type (Should Fail)"
response=$(curl -v -X PUT http://localhost:9090/production/v1/prompt-schema/transcription_v1 \
  -H "Content-Type: application/json" \
  -d '{
    "prompt_text": "This should fail",
    "response_schema": {}
  }')
echo "Response:"
format_response "$response"

# Test 8: Process Audio with Custom Prompt
echo -e "\n8. Testing Process Audio with Custom Prompt"
echo "Response:"
response=$(curl -s -X POST http://localhost:9090/production/v1/process-audio \
  -H "Content-Type: multipart/form-data" \
  -H "Accept: application/json" \
  --form-string 'audio_processing_request={"prompt_type":"test_custom_prompt","model_name":"gemini-1.5-flash","temperature":0.7,"top_p":0.95,"top_k":40,"max_output_tokens":8192}' \
  -F "files=@/Users/ebowwa/caringmind/public/audio_file.ogg")
echo "Response:"
format_response "$response"

# Test 9: Process Audio with Invalid Prompt Type
echo -e "\n9. Testing Process Audio with Invalid Prompt Type"
echo "Response:"
response=$(curl -s -X POST http://localhost:9090/production/v1/process-audio \
  -H "Content-Type: multipart/form-data" \
  -H "Accept: application/json" \
  --form-string 'audio_processing_request={"prompt_type":"nonexistent_prompt","model_name":"gemini-1.5-flash","temperature":0.7,"top_p":0.95,"top_k":40,"max_output_tokens":8192}' \
  -F "files=@/Users/ebowwa/caringmind/public/audio_file.ogg")
echo "Response:"
format_response "$response"

# Test 10: Delete Custom Prompt Schema
echo -e "\n10. Testing Delete Custom Prompt Schema"
response=$(curl -v -X DELETE http://localhost:9090/production/v1/prompt-schema/test_custom_prompt)
echo "Response:"
format_response "$response"

# Test 11: Delete Default Prompt Type (Should Fail)
echo -e "\n11. Testing Delete Default Prompt Type (Should Fail)"
response=$(curl -v -X DELETE http://localhost:9090/production/v1/prompt-schema/transcription_v1)
echo "Response:"
format_response "$response"

echo -e "\nTests completed!"
echo -e "\nTest Summary:"
echo "=============="
echo " Default prompt type handling"
echo " Custom prompt schema creation"
echo " Protection of default prompt type"
echo " Prompt schema retrieval"
echo " Invalid prompt type handling"
echo " Prompt schema updates"
echo " Audio processing with different prompt types"
echo " Prompt schema deletion"
