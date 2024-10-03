# Testing the HUME Post API

This submodule provides examples and guidelines for testing the HUME (Human Understanding Machine Emotions) Post API. HUME API allows for emotion analysis from various input types including text, audio, and video.

## Prerequisites

- curl (for HTTP requests)
- websocat (for WebSocket connections)
- A valid HUME API key
- Local server running on `http://localhost:8000`

## API Endpoints

### 1. Check Job Status

Verify the status of a submitted job.

```bash
curl -X POST "http://localhost:8000/api/v1/hume/check-job-status" \
     -H "Content-Type: application/json" \
     -d '{"job_id": "YOUR_JOB_ID"}'
```

Expected response:
```json
{
  "status": "completed",
  "progress": 100
}
```

### 2. Get Job Predictions

Retrieve results for a completed job.

```bash
curl -X POST "http://localhost:8000/api/v1/hume/get-job-predictions" \
     -H "Content-Type: application/json" \
     -d '{"job_id": "YOUR_JOB_ID"}'
```

Expected response:
```json
{
  "results": [
    {
      "emotion": "joy",
      "score": 0.85
    },
    // ... other emotions
  ]
}
```

### 3. Start Inference Job

Submit a new job with file upload.

```bash
curl -X POST "http://localhost:8000/api/v1/hume/start-inference-job" \
     -H "Content-Type: multipart/form-data" \
     -F "file=@path/to/your/file.mp3"
```

Expected response:
```json
{
  "job_id": "NEW_JOB_ID",
  "status": "processing"
}
```

### 4. WebSocket Streaming Inference

For real-time analysis, use WebSocket connection.

```bash
websocat "ws://localhost:8000/api/v1/hume/ws/streaming-inference"
```

## Error Handling

- Always check HTTP status codes (200 for success, 4xx for client errors, 5xx for server errors)
- Invalid job IDs will return a 404 error
- Malformed requests may result in 400 Bad Request responses

## Troubleshooting

1. Ensure your API key is valid and properly set
2. Check your network connection if requests fail
3. Verify the file format for inference jobs (supported formats: .mp3, .wav, .mp4, .txt)
4. For WebSocket issues, confirm your client supports the WebSocket protocol

## Notes

- Replace `YOUR_JOB_ID` with actual job IDs in the examples
- The local server (`http://localhost:8000`) is assumed for testing. Update URLs for production use
- Responses may vary based on the specific HUME API version and configuration

For more detailed information, refer to the official HUME API documentation.