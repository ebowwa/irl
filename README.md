# irl
uvicorn index:app --reload

# 1. Check job status
curl -X POST "http://localhost:8000/api/v1/hume/check-job-status" \
     -H "Content-Type: application/json" \
     -d '{"job_id": "4de0d3e3-4a6c-40f6-b8b5-2df46aac9dcf"}'

# 2. Get job predictions
curl -X POST "http://localhost:8000/api/v1/hume/get-job-predictions" \
     -H "Content-Type: application/json" \
     -d '{"job_id": "4de0d3e3-4a6c-40f6-b8b5-2df46aac9dcf"}'

# 3. Start inference job with file upload
curl -X POST "http://localhost:8000/api/v1/hume/start-inference-job" \
     -H "Content-Type: multipart/form-data" \
     -F "file=@/Users/ebowwa/Downloads/nice-enthusiastic-male-dan-barracuda-1-00-02.mp3"

# 4. WebSocket connection (Note: curl doesn't support WebSocket directly)
# For WebSocket, you might want to use a tool like websocat:
# websocat "ws://localhost:8000/api/v1/hume/ws/streaming-inference"

