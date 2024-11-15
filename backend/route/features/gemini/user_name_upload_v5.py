# backend/route/features/upload_endpoint.py
# FastAPI router for uploading audio and initiating Gemini processing

import os
import tempfile
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import google.generativeai as genai
import logging
import traceback
import os

from .gemini_process_webhook import process_with_gemini_webhook

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Initialize FastAPI router
router = APIRouter()

# Retrieve and configure the Gemini API key
google_api_key = os.getenv("GOOGLE_API_KEY")
if not google_api_key:
    raise EnvironmentError("GOOGLE_API_KEY not found in environment variables.")

genai.configure(api_key=google_api_key)

def upload_to_gemini(file_path: str, mime_type: str = None):
    """
    Uploads the given file to Gemini.

    Args:
        file_path (str): Path to the file to upload.
        mime_type (str, optional): MIME type of the file. Defaults to None.

    Returns:
        Uploaded file object.
    """
    try:
        uploaded_file = genai.upload_file(file_path, mime_type=mime_type)
        logger.info(f"Uploaded file '{uploaded_file.display_name}' as: {uploaded_file.uri}")
        return uploaded_file  # Return the file object directly
    except Exception as e:
        logger.error(f"Error uploading file: {e}")
        raise

@router.post("/process-audio")
async def process_audio(file: UploadFile = File(...)):
    """
    Endpoint to upload an audio file and send it to the internal Gemini webhook for processing.

    Args:
        file (UploadFile): The audio file to process.

    Returns:
        JSONResponse: The analysis result from Gemini.
    """
    supported_mime_types = [
        "audio/wav",
        "audio/mp3",
        "audio/aiff",
        "audio/aac",
        "audio/ogg",
        "audio/flac",
    ]
    if file.content_type not in supported_mime_types:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}",
        )

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            temp_file.write(await file.read())
            temp_file_path = temp_file.name

        uploaded_file = upload_to_gemini(temp_file_path, mime_type=file.content_type)
        
        # Call the internal webhook for Gemini processing
        gemini_result = process_with_gemini_webhook(uploaded_file)

        os.remove(temp_file_path)

        return JSONResponse(content=gemini_result)

    except Exception as e:
        logger.error(f"Error processing audio: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Server Error. Please check the server logs.")
