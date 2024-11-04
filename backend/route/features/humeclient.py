from fastapi import APIRouter, HTTPException, UploadFile, File, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
import os
from dotenv import load_dotenv
import asyncio
import websockets
import json
import base64

from utils.HumeSpeechProsody.check_job_status import check_job_status
from utils.HumeSpeechProsody.get_job_prediction import get_job_predictions
from utils.HumeSpeechProsody.local_inference import start_inference_job

router = APIRouter()

# Load environment variables
load_dotenv()

API_KEY = os.getenv('HUME_API_KEY')

class JobRequest(BaseModel):
    job_id: str

class InferenceRequest(BaseModel):
    url: str = None

@router.get("/")
async def root():
    return {"message": "Welcome to the Hume AI Integration API"}

@router.post("/check-job-status")
async def api_check_job_status(job_request: JobRequest):
    status = check_job_status(job_request.job_id)
    if status is None:
        raise HTTPException(status_code=404, detail="Job not found or error occurred")
    return {"job_id": job_request.job_id, "status": status}

@router.post("/get-job-predictions")
async def api_get_job_predictions(job_request: JobRequest):
    predictions = get_job_predictions(job_request.job_id)
    if predictions is None:
        raise HTTPException(status_code=404, detail="Predictions not found or error occurred")
    return {"job_id": job_request.job_id, "predictions": predictions}

@router.post("/start-inference-job")
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

class HumeStreamingClient:
    def __init__(self):
        self.websocket = None

    async def connect(self):
        uri = "wss://api.hume.ai/v0/stream/models"
        headers = {"X-Hume-Api-Key": API_KEY}
        try:
            self.websocket = await websockets.connect(uri, extra_headers=headers)
            print("Connection opened")
            return True
        except Exception as e:
            print(f"Error connecting: {e}")
            return False

    async def receive_messages(self):
        try:
            while True:
                message = await self.websocket.recv()
                print(f"Received: {message}")
                yield json.loads(message)
        except websockets.exceptions.ConnectionClosed:
            print("Connection closed")

    async def send_data(self, file_data):
        if not self.websocket:
            print("WebSocket connection not established. Call connect() first.")
            return

        base64_data = base64.b64encode(file_data).decode('utf-8')

        payload = {
            "data": base64_data,
            "models": {
                "prosody": {}
            }
        }

        try:
            await self.websocket.send(json.dumps(payload))
            print("Data sent")
        except Exception as e:
            print(f"Error sending data: {e}")

# ========== 
@router.websocket("/ws/streaming-inference")
# TODO: working but buggy, sometimes fails
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    client = HumeStreamingClient()
    connected = await client.connect()
    
    if not connected:
        await websocket.close(code=1011, reason="Failed to connect to Hume AI")
        return

    try:
        # Receive the file from the client
        file_data = await websocket.receive_bytes()
        
        # Send the file data to Hume AI
        await client.send_data(file_data)

        # Start receiving messages and forward them to the client
        async for message in client.receive_messages():
            await websocket.send_text(json.dumps(message))
    
    except WebSocketDisconnect:
        print("WebSocket connection closed")
    finally:
        if client.websocket:
            await client.websocket.close()