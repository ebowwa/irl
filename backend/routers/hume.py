# backend/routers/hume.py
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from dotenv import load_dotenv

from routers.hume.check_job_status import check_job_status
from routers.hume.get_job_prediction import get_job_predictions
from routers.hume.local_inference import start_inference_job
from routers.websocket.HumeStreaming import websocket_endpoint

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Load environment variables
load_dotenv()

class JobRequest(BaseModel):
    job_id: str

class InferenceRequest(BaseModel):
    url: str = None

@app.get("/")
async def root():
    return {"message": "Welcome to the Hume AI Integration API"}

@app.post("/check-job-status")
async def api_check_job_status(job_request: JobRequest):
    status = check_job_status(job_request.job_id)
    if status is None:
        raise HTTPException(status_code=404, detail="Job not found or error occurred")
    return {"job_id": job_request.job_id, "status": status}

@app.post("/get-job-predictions")
async def api_get_job_predictions(job_request: JobRequest):
    predictions = get_job_predictions(job_request.job_id)
    if predictions is None:
        raise HTTPException(status_code=404, detail="Predictions not found or error occurred")
    return {"job_id": job_request.job_id, "predictions": predictions}

@app.post("/start-inference-job")
async def api_start_inference_job(inference_request: InferenceRequest = None, file: UploadFile = File(None)):
    if inference_request and inference_request.url:
        job_id = start_inference_job(url=inference_request.url)
    elif file:
        # Save the uploaded file temporarily
        with open(file.filename, "wb") as buffer:
            buffer.write(await file.read())
        job_id = start_inference_job(file_path=file.filename)
        # Remove the temporary file
        os.remove(file.filename)
    else:
        raise HTTPException(status_code=400, detail="Please provide either a URL or a file")
    
    if job_id is None:
        raise HTTPException(status_code=500, detail="Failed to start inference job")
    return {"job_id": job_id}

# Include the WebSocket endpoint
app.add_api_websocket_route("/ws/streaming-inference", websocket_endpoint)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)