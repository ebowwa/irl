# backend/route/features/gemini_media_upload.py
# FastAPI router for uploading files (audio, video, image) to Google Gemini
# Audio works tbd about any other modalities
# TODO:
# - The server responds with a URL to the file. I would like to save each entry with a timestamp, google_sign:user_device, media type, and full CRUD to use this data later on with the user experience.
# - We will likely modify/scale this DB later with transcriptions, inferences ran on media, embedding, & OR otherwise
# - Will need the CRUD for the upload references. The references will likely auto-delete by Google's GenAI servers within 48 hours and can have a max uploaded capacity of 20GB (with scale this may grow so we should be able to redefine this)
# - Modularize so that db isnt created by both and intiialized by both + scalablility https://chatgpt.com/share/67350cef-7334-800f-9bd9-a2c2b633bd6d

import os
import tempfile
import logging
from datetime import datetime
from typing import List, Optional
from pathlib import Path

from fastapi import APIRouter, UploadFile, File, HTTPException, Form, status, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import google.generativeai as genai
import databases
import sqlalchemy
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Table, func
from sqlalchemy.exc import IntegrityError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# === Database Configuration ===

# 1. Load environment variables from .env
load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent / "data"
DATABASE_NAME = "app_user_identification.db"
DATABASE_PATH = BASE_DIR / DATABASE_NAME
# Ensure the directory exists
BASE_DIR.mkdir(parents=True, exist_ok=True)
logger.info(f"Database directory ensured at: {BASE_DIR.as_posix()}")
DATABASE_URL = f"sqlite+aiosqlite:///{DATABASE_PATH.as_posix()}"

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
logger.info("Media uploads table created or already exist.")

# 2. Initialize the FastAPI router
router = APIRouter()

# 3. Retrieve and configure the Gemini API key
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
        raise HTTPException(status_code=500, detail="Failed to upload file to Gemini.")

# === Pydantic Models ===

class MediaUploadEntry(BaseModel):
    id: int
    device_id: int
    file_uri: str
    display_name: str
    mime_type: str
    created_at: datetime

    class Config:
        orm_mode = True

class MediaUploadCreate(BaseModel):
    device_uuid: str = Field(..., example="550e8400-e29b-41d4-a716-446655440000")
    # Assuming the file is being uploaded via endpoint, so file itself is not part of the model
    # Any additional fields can be added here if needed

class MediaUploadUpdate(BaseModel):
    # Fields that can be updated
    # For simplicity, assuming uploads cannot be updated
    pass

# === CRUD Endpoints for Media Uploads ===

@router.post(
    "/upload-to-gemini",
    response_model=MediaUploadEntry,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a file to Gemini and record the upload",
)
async def upload_file_to_gemini(
    request: Request,
    file: UploadFile = File(...),
    device_uuid: str = Form(..., example="550e8400-e29b-41d4-a716-446655440000")
):
    """
    Endpoint to upload a file to Gemini, handling various file modalities.

    Args:
        file (UploadFile): The file to upload.
        device_uuid (str): The device UUID to associate the upload with.

    Returns:
        MediaUploadEntry: The recorded media upload entry.
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
        "application/octet-stream" # maybe remove
    ]

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

        # Record the upload in the media_uploads table
        insert_query = media_uploads_table.insert().values(
            device_id=device_id,
            file_uri=uploaded_file.uri,
            display_name=uploaded_file.display_name,
            mime_type=file.content_type,
            # created_at will default to now()
        )
        last_record_id = await database.execute(insert_query)
        logger.info(f"Media upload recorded with ID: {last_record_id}")

        # Retrieve the created media upload entry
        select_query = media_uploads_table.select().where(media_uploads_table.c.id == last_record_id)
        media_upload_entry = await database.fetch_one(select_query)
        logger.info(f"Media upload entry retrieved: {media_upload_entry}")

        return media_upload_entry

    except HTTPException as e:
        logger.error(f"Error in file upload: {e.detail}")
        raise

    except Exception as e:
        logger.error(f"Unexpected error during file upload: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error during file upload.")

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

# Note: Updating media uploads is not typically needed as the media itself cannot be changed after upload
# But if needed, you can implement a PUT endpoint similar to device_registration.py

# === Constraints Handling ===

# You can add any constraints or checks here, for example:
# - Check the total number of uploads per device
# - Enforce maximum upload capacity per device
# - Implement auto-deletion policies

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
