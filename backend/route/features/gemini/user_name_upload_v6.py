# backend/route/features/upload_endpoint.py
# Updated to support both one-shot and large batch processing with concurrent handling
import os
import tempfile
import asyncio
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from fastapi.responses import JSONResponse
from typing import List
from dotenv import load_dotenv
import google.generativeai as genai
import logging
import traceback

from .gemini_process_webhook_v2 import process_with_gemini_webhook

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

async def save_temp_file(upload_file: UploadFile) -> str:
    """
    Asynchronously saves an uploaded file to a temporary location.

    Args:
        upload_file (UploadFile): The uploaded file.

    Returns:
        str: The path to the saved temporary file.
    """
    try:
        suffix = os.path.splitext(upload_file.filename)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            content = await upload_file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name
        return temp_file_path
    except Exception as e:
        logger.error(f"Error saving temporary file {upload_file.filename}: {e}")
        raise

@router.post("/process-audio")
async def process_audio(
    files: List[UploadFile] = File(...),
    prompt_type: str = Query("default", description="Type of prompt and schema to use")
):
    supported_mime_types = [
        "audio/wav",
        "audio/mp3",
        "audio/aiff",
        "audio/aac",
        "audio/ogg",
        "audio/flac",
    ]

    if not files:
        raise HTTPException(
            status_code=400,
            detail="No files uploaded."
        )

    # Validate all files
    for file in files:
        if file.content_type not in supported_mime_types:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}",
            )

    try:
        # Save all files concurrently
        temp_file_paths = await asyncio.gather(*[save_temp_file(file) for file in files])

        # Upload all files concurrently
        loop = asyncio.get_event_loop()
        uploaded_files = await asyncio.gather(*[
            loop.run_in_executor(None, upload_to_gemini, path, file.content_type)
            for path, file in zip(temp_file_paths, files)
        ])

        # Remove temporary files
        for path in temp_file_paths:
            try:
                os.remove(path)
            except Exception as e:
                logger.warning(f"Failed to delete temp file {path}: {e}")

        # Process all uploaded files concurrently
        processing_tasks = [
            process_with_gemini_webhook(uploaded_file, prompt_type=prompt_type)
            for uploaded_file in uploaded_files
        ]

        loop = asyncio.get_event_loop()
        # Use asyncio.gather to process concurrently
        processing_results = await asyncio.gather(
            *[loop.run_in_executor(None, lambda p=task: p) for task in processing_tasks],
            return_exceptions=True
        )

        results = []
        for uploaded_file, result in zip(uploaded_files, processing_results):
            if isinstance(result, Exception):
                logger.error(f"Error processing file {uploaded_file.display_name}: {result}")
                results.append({
                    "file": uploaded_file.display_name,
                    "status": "failed",
                    "error": str(result)
                })
            else:
                results.append({
                    "file": uploaded_file.display_name,
                    "status": "processed",
                    "data": result
                })

        return JSONResponse(content={"results": results})

    except Exception as e:
        logger.error(f"Error processing audio: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Server Error. Please check the server logs.")
