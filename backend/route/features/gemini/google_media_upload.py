# backend/route/features/upload_to_gemini.py
# FastAPI router for uploading files (audio, video, image) to Google Gemini
# audio works tbd about any other modalities 
# TODO: the server responds with a url to the file, i would like to save each entry with a timestamp, googlesign:userdevice, and media type and full crud to use this data later on with the user experience
# - we will likely modify/scale this db later with transcriptions, inferences ran on media, embedding, &OR otherwise
# - will need the crud for the upload references the references will likely autodelete by googles genai server's within 48 hours and can have a max uploaded capacity of 20gbs(with scale this may grow so we should be able to redefine this)
import os
import tempfile
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import google.generativeai as genai
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 1. Load environment variables from .env
load_dotenv()

# 2. Initialize the FastAPI router
router = APIRouter()

# 3. Retrieve and configure the Gemini API key
google_api_key = os.getenv("GOOGLE_API_KEY")
if not google_api_key:
    raise EnvironmentError("GEMINI_API_KEY not found in environment variables.")

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
        raise HTTPException(status_code=500, detail="Failed to upload file to Gemini.")

@router.post("/upload-to-gemini")
async def upload_file_to_gemini(file: UploadFile = File(...)):
    """
    Endpoint to upload a file to Gemini, handling various file modalities.

    Args:
        file (UploadFile): The file to upload.

    Returns:
        JSONResponse: The result from the upload to Gemini.
    """
    # Define supported MIME types for different modalities
    supported_mime_types = [
    "audio/wav", "audio/mp3", "audio/aiff", "audio/aac", "audio/ogg", "audio/flac",
    "image/jpeg", "image/png", "image/gif",
    "video/mp4", "video/quicktime",
    "application/octet-stream" ] # maybe remove

    # Check if the file's MIME type is supported
    if file.content_type not in supported_mime_types:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}",
        )

    try:
        # Save the uploaded file temporarily on the server
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            temp_file.write(await file.read())
            temp_file_path = temp_file.name

        # Upload the file to Gemini and retrieve the file object
        uploaded_file = upload_to_gemini(temp_file_path, mime_type=file.content_type)

        # Remove the temporary file after upload
        os.remove(temp_file_path)

        # Return response with the uploaded file's URI and display name
        return JSONResponse(content={
            "message": "File uploaded successfully to Gemini.",
            "file_uri": uploaded_file.uri,
            "display_name": uploaded_file.display_name
        })

    except HTTPException as e:
        logger.error(f"Error in file upload: {e.detail}")
        raise

    except Exception as e:
        logger.error(f"Unexpected error during file upload: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error during file upload.")
