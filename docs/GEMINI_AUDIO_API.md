# Gemini Audio API Documentation

## Base URL
```
http://localhost:9090/production/v1
```

## Endpoints

### 1. Process Audio File (Direct Upload)
Process an audio file by directly uploading it to the server.

**Endpoint:** `/process-audio`  
**Method:** POST  
**Content-Type:** multipart/form-data

#### Parameters
- `files` (required): Audio file(s) to process (supports multiple formats)
- `prompt_type` (optional): Type of prompt to use (default: "transcription_v1")
- `model_name` (optional): Gemini model to use (default: "gemini-1.5-flash")
- `temperature` (optional): Temperature parameter (default: 1.0)
- `top_p` (optional): Top-p parameter (default: 0.95)
- `top_k` (optional): Top-k parameter (default: 40)
- `max_output_tokens` (optional): Maximum output tokens (default: 8192)

#### Supported File Types
- audio/wav
- audio/mp3
- audio/aiff
- audio/aac
- audio/ogg
- audio/flac

#### Size Limits
- Maximum file size: 100MB

#### Example Request
```bash
curl -X POST "http://localhost:9090/production/v1/process-audio" \
  -F "files=@/path/to/audio.ogg;type=audio/ogg" \
  -F "prompt_type=transcription_v1"
```

#### Example Response
```json
{
  "results": [{
    "status": "success",
    "filename": "audio.ogg",
    "result": {
      "conversation_analysis": [
        {
          "speaker": "Speaker 1",
          "text": "...",
          "tone_analysis": {
            "tone": "Informative",
            "indicators": [...]
          },
          "confidence": 95,
          "red_flags": [],
          "summary": "..."
        }
      ]
    }
  }]
}
```

### 2. Process Audio URI
Process an audio file using its file URI.

**Endpoint:** `/process-audio-uri`  
**Method:** POST  
**Content-Type:** application/json

#### Request Body
```json
{
  "file_uri": "file:///path/to/audio.ogg"
}
```

#### Optional Query Parameters
- `prompt_type` (default: "transcription_v1")
- `model_name` (default: "gemini-1.5-flash")
- `temperature` (default: 1.0)
- `top_p` (default: 0.95)
- `top_k` (default: 40)
- `max_output_tokens` (default: 8192)

#### Example Request
```bash
curl -X POST "http://localhost:9090/production/v1/process-audio-uri" \
  -H "Content-Type: application/json" \
  -d '{"file_uri": "file:///path/to/audio.ogg"}'
```

#### Example Response
```json
{
  "results": [{
    "status": "success",
    "uri": "file:///path/to/audio.ogg",
    "analysis": [{
      "status": "success",
      "filename": "file:///path/to/audio.ogg",
      "result": "..."
    }]
  }]
}
```

## Error Handling

### HTTP Status Codes
- 200: Success
- 400: Bad Request
  - Invalid input parameters
  - Unsupported file type
- 404: Not Found
  - Audio file not found
- 413: Payload Too Large
  - File size exceeds 100MB limit
- 500: Internal Server Error
  - Processing failed
  - Gemini API error

### Error Response Format
```json
{
  "detail": "Error message describing the issue"
}
```

### Example Error Responses

#### File Not Found (404)
```json
{
  "detail": "Audio file not found: file:///nonexistent/file.ogg"
}
```

#### Invalid File Type (400)
```json
{
  "detail": "Unsupported file type: .txt"
}
```

#### File Too Large (413)
```json
{
  "detail": "File size exceeds maximum limit of 100MB"
}
```

## Notes
- Currently supports various audio formats (wav, mp3, aiff, aac, ogg, flac)
- Maximum file size: 100MB
- No authentication required (preview version)
- All responses are in JSON format
- Error messages are descriptive and include specific details about the issue
