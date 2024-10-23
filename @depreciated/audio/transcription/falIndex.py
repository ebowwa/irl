# app/transcription_router.py

import os
import asyncio
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, HttpUrl
from dotenv import load_dotenv
import fal_client

# Load environment variables from .env file
load_dotenv()

# Initialize APIRouter
router = APIRouter()

# Set the API key for fal_client
fal_client.api_key = os.getenv('FAL_KEY') or 'your_api_key'
if fal_client.api_key == 'your_api_key':
    print("Warning: Using default API key. Please set the FAL_KEY environment variable.")

# Define Pydantic models for request and response

class TranscriptionRequest(BaseModel):
    audio_url: HttpUrl
    task: Optional[str] = "transcribe"  # "transcribe" or "translate"
    language: Optional[str] = "en"
    chunk_level: Optional[str] = "segment"  # Currently only "segment" is supported
    version: Optional[str] = "3"  # Version of the model to use

class WhisperChunk(BaseModel):
    text: str
    timestamp: Optional[list]  # Assuming timestamps are lists of floats

class TranscriptionResponse(BaseModel):
    text: str
    chunks: list[WhisperChunk]

# Define custom exception for transcription errors
class TranscriptionError(Exception):
    def __init__(self, message: str):
        self.message = message

# Route to handle transcription
@router.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe(request: TranscriptionRequest):
    """
    Transcribe an audio file using the Whisper model.
    """
    try:
        # Submit the transcription request asynchronously
        handler = await fal_client.submit_async(
            "fal-ai/wizper",
            arguments={
                "audio_url": request.audio_url,
                "task": request.task,
                "language": request.language,
                "chunk_level": request.chunk_level,
                "version": request.version
            },
        )
        request_id = handler.request_id
        if not request_id:
            raise TranscriptionError("Failed to obtain request_id from submission.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error submitting transcription request: {e}")

    # Poll for status
    max_retries = 30
    retry_interval = 5  # seconds

    for attempt in range(max_retries):
        try:
            status_response = await fal_client.status_async("fal-ai/wizper", request_id, with_logs=True)
            status = status_response.status

            if status == "completed":
                break
            elif status in ["failed", "error"]:
                raise TranscriptionError(f"Transcription failed with status: {status}")
            else:
                # Status is still in progress
                print(f"Transcription status: {status}. Retrying in {retry_interval} seconds...")
                await asyncio.sleep(retry_interval)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error checking transcription status: {e}")
    else:
        raise HTTPException(status_code=500, detail="Transcription request timed out.")

    # Fetch the result
    try:
        result = await fal_client.result_async("fal-ai/wizper", request_id)
        if "text" not in result or "chunks" not in result:
            raise TranscriptionError("Transcription result is missing expected fields.")
        
        # Parse chunks
        chunks = [
            WhisperChunk(
                text=chunk.get("text", ""),
                timestamp=chunk.get("timestamp")
            ) for chunk in result.get("chunks", [])
        ]

        return TranscriptionResponse(
            text=result["text"],
            chunks=chunks
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching transcription result: {e}")
