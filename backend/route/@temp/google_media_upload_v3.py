# File: backend/route/features/gemini_media_upload.py

import os
import tempfile
import logging
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, UploadFile, File, HTTPException, Form, status, Request
from pydantic import BaseModel
from dotenv import load_dotenv
import httpx
import databases
import sqlalchemy
from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    ForeignKey,
    Table,
    func,
)
from sqlalchemy.exc import IntegrityError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# === Load Environment Variables ===
load_dotenv()

# === Database Configuration ===

BASE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../data")
DATABASE_NAME = "app_user_identification.db"
DATABASE_PATH = os.path.join(BASE_DIR, DATABASE_NAME)

# Ensure the directory exists
os.makedirs(BASE_DIR, exist_ok=True)
logger.info(f"Database directory ensured at: {BASE_DIR}")

DATABASE_URL = f"sqlite+aiosqlite:///{DATABASE_PATH}"

# Initialize the database
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

# === Define the Device Registration Table ===

device_registration_table = Table(
    "device_registration",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("google_account_id", String, unique=True, index=True, nullable=False),
    Column("device_uuid", String, unique=True, index=True, nullable=False),
    Column("id_token", String, nullable=False),
    Column("access_token", String, nullable=False),
    Column("created_at", DateTime, default=func.now(), nullable=False),
)

# === Define the Media Uploads Table ===

media_uploads_table = Table(
    "media_uploads",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("device_id", Integer, ForeignKey("device_registration.id"), nullable=False),
    Column("file_uri", String, nullable=False),
    Column("display_name", String, nullable=False),
    Column("mime_type", String, nullable=False),
    Column("created_at", DateTime, default=func.now(), nullable=False),
    # Add any additional fields you may need, like file size, etc.
)

# Create the database engine
engine = sqlalchemy.create_engine(
    DATABASE_URL.replace("+aiosqlite", ""),
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
)

# Create the table(s)
metadata.create_all(engine)
logger.info("Media uploads table created or already exists.")

# === Initialize the FastAPI Router ===

router = APIRouter()

# === Configure Gemini API ===

GEMINI_UPLOAD_ENDPOINT = "https://generativelanguage.googleapis.com/upload/v1beta/files"
GEMINI_GENERATE_ENDPOINT_TEMPLATE = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    logger.error("GOOGLE_API_KEY not found in environment variables.")
    raise EnvironmentError("GOOGLE_API_KEY not found in environment variables.")

# === Pydantic Models ===

class MediaUploadEntry(BaseModel):
    id: int
    device_id: int
    file_uri: str
    display_name: str
    mime_type: str
    created_at: datetime

class MediaUploadResponse(BaseModel):
    media_upload: MediaUploadEntry
    generated_content: str

# === Helper Functions ===

async def upload_to_gemini(file_path: str, display_name: str, mime_type: str) -> dict:
    """
    Uploads the given file to Gemini using the File API.

    Args:
        file_path (str): Path to the file to upload.
        display_name (str): Display name for the uploaded file.
        mime_type (str): MIME type of the file.

    Returns:
        dict: Uploaded file object containing 'uri' and other metadata.
    """
    # Append the API key as a query parameter
    upload_url = f"{GEMINI_UPLOAD_ENDPOINT}?key={GOOGLE_API_KEY}"

    async with httpx.AsyncClient() as client:
        try:
            logger.info(f"Uploading file to Gemini: {display_name}")
            with open(file_path, "rb") as f:
                files = {
                    "file": (display_name, f, mime_type)
                }
                response = await client.post(
                    upload_url,
                    files=files
                )
            response.raise_for_status()
            uploaded_file = response.json()
            logger.info(f"Uploaded file '{display_name}' as: {uploaded_file.get('uri')}")
            return uploaded_file
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error during file upload: {e.response.status_code} - {e.response.text}")
            raise HTTPException(status_code=e.response.status_code, detail=f"File upload failed: {e.response.text}")
        except Exception as e:
            logger.error(f"Unexpected error during file upload: {e}")
            raise HTTPException(status_code=500, detail="Failed to upload file to Gemini.")

async def generate_content(
    model: str,
    contents: dict,
    temperature: float,
    top_p: float,
    max_output_tokens: int,
    candidate_count: int,
    response_mime_type: str,
    safety_settings: dict
) -> dict:
    """
    Generates content using the Gemini API.

    Args:
        model (str): Model variant to use.
        contents (dict): Content dictionary including text and media references.
        temperature (float): Sampling temperature.
        top_p (float): Nucleus sampling parameter.
        max_output_tokens (int): Maximum number of tokens in the output.
        candidate_count (int): Number of candidate responses.
        response_mime_type (str): MIME type of the response.
        safety_settings (dict): Safety settings for content generation.

    Returns:
        dict: Response from Gemini API containing generated content.
    """
    url = GEMINI_GENERATE_ENDPOINT_TEMPLATE.format(model=model)
    # Append the API key as a query parameter
    generate_url = f"{url}?key={GOOGLE_API_KEY}"

    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "contents": contents,
        "temperature": temperature,
        "top_p": top_p,
        "max_output_tokens": max_output_tokens,
        "candidate_count": candidate_count,
        "response_mime_type": response_mime_type,
        "safety_settings": safety_settings
    }

    async with httpx.AsyncClient() as client:
        try:
            logger.info(f"Generating content using model: {model}")
            response = await client.post(
                generate_url,
                headers=headers,
                json=payload
            )
            response.raise_for_status()
            content_response = response.json()
            logger.info("Received response from Gemini API.")
            return content_response
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error during content generation: {e.response.status_code} - {e.response.text}")
            raise HTTPException(status_code=e.response.status_code, detail=f"Content generation failed: {e.response.text}")
        except Exception as e:
            logger.error(f"Unexpected error during content generation: {e}")
            raise HTTPException(status_code=500, detail="Failed to generate content with Gemini.")

# === Upload and Generate Content Endpoint ===

@router.post(
    "/upload-and-generate",
    response_model=MediaUploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a file to Gemini, generate content, and record the upload",
)
async def upload_and_generate_content(
    request: Request,
    file: UploadFile = File(..., description="The media file to upload."),
    device_uuid: str = Form(..., description="Device UUID to associate the upload with", example="B45F6CC3-6EB0-4AF1-9F9E-5E51D112314C"),
    text_input: Optional[str] = Form(None, description="Text input for content generation"),
    model: str = Form(..., description="Model variant to use", example="gemini-1.5-flash-8b"),
    language: Optional[str] = Form("en", description="Language code", example="en"),
    candidate_count: int = Form(1, description="Number of candidate responses", ge=1, le=5),
    max_output_tokens: int = Form(1000, description="Maximum number of tokens in the output", ge=1, le=8192),
    temperature: float = Form(0.7, description="Sampling temperature", ge=0.0, le=2.0),
    top_p: float = Form(0.9, description="Nucleus sampling parameter", ge=0.0, le=1.0),
    response_mime_type: str = Form("application/json", description="Response MIME type", example="application/json"),
):
    """
    Endpoint to upload a file to Gemini, generate content, and record the upload.

    Args:
        file (UploadFile): The media file to upload.
        device_uuid (str): The device UUID to associate the upload with.
        text_input (Optional[str]): Text input for content generation.
        model (str): Model variant to use.
        language (Optional[str]): Language code.
        candidate_count (int): Number of candidate responses.
        max_output_tokens (int): Maximum number of tokens in the output.
        temperature (float): Sampling temperature.
        top_p (float): Nucleus sampling parameter.
        response_mime_type (str): Response MIME type.

    Returns:
        MediaUploadResponse: The recorded media upload entry and generated content.
    """
    # Validate the device_uuid against device_registration_table
    logger.info(f"Validating device_uuid: {device_uuid}")
    query = device_registration_table.select().where(device_registration_table.c.device_uuid == device_uuid)
    device_entry = await database.fetch_one(query)
    if device_entry is None:
        logger.warning(f"Device with UUID {device_uuid} not found.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid device UUID. Device not registered."
        )
    device_id = device_entry['id']
    logger.info(f"Device validated with ID: {device_id}")

    # Define supported MIME types for different modalities
    supported_mime_types = [
        "audio/wav", "audio/mp3", "audio/aiff", "audio/aac", "audio/ogg", "audio/flac",
        "image/jpeg", "image/png", "image/gif",
        "video/mp4", "video/quicktime",
        "application/octet-stream"  # Optional: Remove if not needed
    ]

    # Check if the file's MIME type is supported
    if file.content_type not in supported_mime_types:
        logger.warning(f"Unsupported file type: {file.content_type}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}",
        )

    try:
        # Save the uploaded file temporarily on the server
        logger.info(f"Saving uploaded file: {file.filename}")
        suffix = os.path.splitext(file.filename)[1] if '.' in file.filename else ''
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            contents = await file.read()
            temp_file.write(contents)
            temp_file_path = temp_file.name
        logger.info(f"File saved temporarily at: {temp_file_path}")

        # Upload the file to Gemini and retrieve the file object
        uploaded_file = await upload_to_gemini(
            file_path=temp_file_path,
            display_name=file.filename,
            mime_type=file.content_type
        )

        # Remove the temporary file after upload
        os.remove(temp_file_path)
        logger.info(f"Temporary file removed: {temp_file_path}")

        # Prepare contents for content generation
        contents_payload = {}

        if text_input:
            contents_payload["text"] = text_input

        # Determine media type and append accordingly
        media_field = None
        if file.content_type.startswith("audio"):
            media_field = "audio"
        elif file.content_type.startswith("image"):
            media_field = "image"
        elif file.content_type.startswith("video"):
            media_field = "video"
        else:
            media_field = "file"  # Default case

        if media_field:
            contents_payload[media_field] = {"file": uploaded_file.get("uri", "")}

        # Define safety settings (adjust as needed)
        safety_settings = {
            'HATE_SPEECH': 'BLOCK_NONE',
            'HARASSMENT': 'BLOCK_NONE',
            'SEXUAL': 'BLOCK_NONE',
            'DANGEROUS': 'BLOCK_NONE'
        }

        # Call the generate content function
        logger.info("Initiating content generation with Gemini API.")
        content_response = await generate_content(
            model=model,
            contents=contents_payload,
            temperature=temperature,
            top_p=top_p,
            max_output_tokens=max_output_tokens,
            candidate_count=candidate_count,
            response_mime_type=response_mime_type,
            safety_settings=safety_settings
        )

        # Handle the response
        if "candidates" in content_response and len(content_response["candidates"]) > 0:
            candidate = content_response["candidates"][0]
            generated_content = candidate.get("content", {}).get("text", "")
            logger.info("Content generation successful.")
        else:
            generated_content = ""
            logger.warning("No content generated by Gemini API.")

        # Record the media upload in the media_uploads table
        insert_query = media_uploads_table.insert().values(
            device_id=device_id,
            file_uri=uploaded_file.get("uri", ""),
            display_name=uploaded_file.get("display_name", file.filename),
            mime_type=file.content_type,
            # created_at will default to now()
        )
        last_record_id = await database.execute(insert_query)
        logger.info(f"Media upload recorded with ID: {last_record_id}")

        # Retrieve the created media upload entry
        select_query = media_uploads_table.select().where(media_uploads_table.c.id == last_record_id)
        media_upload_entry = await database.fetch_one(select_query)
        logger.info(f"Media upload entry retrieved: {media_upload_entry}")

        # Return the media upload entry along with the generated content
        return MediaUploadResponse(
            media_upload=media_upload_entry,
            generated_content=generated_content
        )

    except HTTPException as e:
        logger.error(f"HTTPException: {e.detail}")
        raise

    except Exception as e:
        logger.error(f"Unexpected error during file upload and content generation: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error during file upload and content generation.")

# === CRUD Endpoints for Media Uploads ===

@router.get(
    "/media-uploads/{entry_id}",
    response_model=MediaUploadEntry,
    summary="Retrieve a media upload entry by ID",
)
async def get_media_upload(entry_id: int):
    logger.info(f"Retrieving media upload entry with ID: {entry_id}")
    query = media_uploads_table.select().where(media_uploads_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        logger.warning(f"Media upload entry with ID {entry_id} not found.")
        raise HTTPException(status_code=404, detail="Media upload not found")
    logger.info(f"Media upload entry found: {entry}")
    return entry

@router.get(
    "/media-uploads",
    response_model=List[MediaUploadEntry],
    summary="List all media uploads"
)
async def list_media_uploads():
    logger.info("Listing all media uploads.")
    query = media_uploads_table.select().order_by(media_uploads_table.c.created_at.desc())
    entries = await database.fetch_all(query)
    logger.info(f"Number of media uploads retrieved: {len(entries)}")
    return entries

@router.delete(
    "/media-uploads/{entry_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a media upload entry by ID",
)
async def delete_media_upload(entry_id: int):
    logger.info(f"Deleting media upload entry with ID: {entry_id}")

    # Check if the media upload entry exists
    query = media_uploads_table.select().where(media_uploads_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        logger.warning(f"Media upload entry with ID {entry_id} not found for deletion.")
        raise HTTPException(status_code=404, detail="Media upload not found")

    # Perform the deletion
    delete_query = media_uploads_table.delete().where(media_uploads_table.c.id == entry_id)
    try:
        await database.execute(delete_query)
        logger.info(f"Media upload entry ID {entry_id} deleted successfully.")
    except Exception as e:
        logger.error(f"Unexpected error during deletion: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred during deletion.",
        )
    return {"message": "Media upload deleted successfully", "entry_id": entry_id}

# === Event Handlers ===

@router.on_event("startup")
async def startup():
    logger.info("Starting up and connecting to the database.")
    try:
        await database.connect()
        logger.info("Database connected successfully.")
    except Exception as e:
        logger.error(f"Error connecting to the database: {e}")
        raise

@router.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down and disconnecting from the database.")
    try:
        await database.disconnect()
        logger.info("Database disconnected successfully.")
    except Exception as e:
        logger.error(f"Error disconnecting from the database: {e}")
