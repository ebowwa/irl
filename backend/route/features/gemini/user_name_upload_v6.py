import os
import asyncio
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from fastapi.responses import JSONResponse
from typing import List, Optional
from dotenv import load_dotenv
import google.generativeai as genai
import logging
import traceback
from tenacity import retry, stop_after_attempt, wait_exponential
from .gemini_process_webhook_v2 import process_with_gemini_webhook

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Initialize FastAPI router
router = APIRouter()

# Configure Gemini
google_api_key = os.getenv("GOOGLE_API_KEY")
if not google_api_key:
    raise EnvironmentError("GOOGLE_API_KEY not found in environment variables.")

genai.configure(api_key=google_api_key)

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def upload_to_gemini(file_content: bytes, mime_type: Optional[str] = None) -> object:
    """
    Uploads the given file content directly to Gemini with retry logic.
    Note: This is NOT an async function since genai.upload_file is synchronous.

    Args:
        file_content (bytes): The file content to upload.
        mime_type (str, optional): MIME type of the file.

    Returns:
        object: Uploaded file object.

    Raises:
        Exception: If upload fails after retries.
    """
    try:
        # Create a temporary in-memory file-like object
        import io
        file_obj = io.BytesIO(file_content)
        
        # Upload directly to Gemini using the file-like object
        uploaded_file = genai.upload_file(file_obj, mime_type=mime_type)
        logger.info(f"Successfully uploaded file as: {uploaded_file.uri}")
        return uploaded_file
    except Exception as e:
        logger.error(f"Error uploading file: {e}")
        raise

async def process_single_file(file: UploadFile) -> object:
    """
    Process a single file asynchronously.

    Args:
        file (UploadFile): The file to process.

    Returns:
        object: Uploaded file object

    Raises:
        HTTPException: If file processing fails.
    """
    try:
        content = await file.read()
        
        # Upload to Gemini (run in thread pool to avoid blocking)
        loop = asyncio.get_running_loop()
        uploaded_file = await loop.run_in_executor(
            None,
            lambda: upload_to_gemini(content, file.content_type)
        )
        
        return uploaded_file
    except Exception as e:
        logger.error(f"Error processing file {file.filename}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process file {file.filename}: {str(e)}"
        )

@router.post("/process-audio")
async def process_audio(
    files: List[UploadFile] = File(...),
    prompt_type: str = Query("default", description="Type of prompt and schema to use")
):
    """
    Process multiple audio files concurrently with improved error handling.
    """
    supported_mime_types = {
        "audio/wav", "audio/mp3", "audio/aiff",
        "audio/aac", "audio/ogg", "audio/flac"
    }

    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded.")

    # Validate all files
    for file in files:
        if file.content_type not in supported_mime_types:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}"
            )

    results = []
    try:
        # Process files concurrently
        processing_tasks = [process_single_file(file) for file in files]
        uploaded_files = await asyncio.gather(*processing_tasks, return_exceptions=True)

        # Process results and handle Gemini API calls
        for file, uploaded_file in zip(files, uploaded_files):
            if isinstance(uploaded_file, Exception):
                logger.error(f"Error processing file {file.filename}: {uploaded_file}")
                results.append({
                    "file": file.filename,
                    "status": "failed",
                    "error": str(uploaded_file)
                })
                continue

            try:
                # Process with Gemini webhook
                gemini_result = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: process_with_gemini_webhook(uploaded_file, prompt_type=prompt_type)
                )
                
                results.append({
                    "file": file.filename,
                    "status": "processed",
                    "data": gemini_result
                })
            except Exception as e:
                logger.error(f"Error in Gemini processing for {file.filename}: {e}")
                results.append({
                    "file": file.filename,
                    "status": "failed",
                    "error": str(e)
                })

        return JSONResponse(content={"results": results})

    except Exception as e:
        logger.error(f"Unexpected error in process_audio: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail="Internal Server Error. Please check the server logs."
        )