from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from typing import List, Optional
from pydantic import BaseModel
import aiofiles
import os
import asyncio
import logging
from datetime import datetime, timedelta
import hashlib
import mimetypes
import magic  # python-magic for better MIME type detection

router = APIRouter()

# Configuration
UPLOAD_DIR = "/tmp/uploads"  # Temporary storage
MAX_FILE_SIZE = {
    "audio": 2_147_483_648,  # 2GB for audio
    "image": 104_857_600,    # 100MB for images
    "video": 2_147_483_648,  # 2GB for video
    "document": 524_288_000  # 500MB for documents
}
SUPPORTED_MIME_TYPES = {
    # Audio
    'audio/wav': 'audio',
    'audio/mp3': 'audio', 
    'audio/aiff': 'audio',
    'audio/aac': 'audio',
    'audio/ogg': 'audio',
    'audio/flac': 'audio',

    # Images
    'image/jpeg': 'image',
    'image/png': 'image',
    'image/gif': 'image',
    'image/webp': 'image',

    # Video 
    'video/mp4': 'video',
    'video/webm': 'video',

    # Documents
    'application/pdf': 'document',
    'text/plain': 'document',
    'text/html': 'document'
}

# Response Models
class FileMetadata(BaseModel):
    file_id: str
    original_name: str
    mime_type: str
    size: int
    upload_time: datetime
    expiry_time: datetime
    category: str

class UploadResponse(BaseModel):
    success: bool
    message: str
    file_info: Optional[FileMetadata] = None

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Ensure upload directory exists
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Utility Functions
def get_file_hash(file_content: bytes) -> str:
    """Generate a unique hash for the file content"""
    return hashlib.sha256(file_content).hexdigest()

async def cleanup_expired_files(background_tasks: BackgroundTasks):
    """Remove files that are older than 48 hours"""
    try:
        current_time = datetime.now()
        for filename in os.listdir(UPLOAD_DIR):
            file_path = os.path.join(UPLOAD_DIR, filename)
            file_modified = datetime.fromtimestamp(os.path.getmtime(file_path))
            if current_time - file_modified > timedelta(hours=48):
                os.remove(file_path)
                logger.info(f"Cleaned up expired file: {filename}")
    except Exception as e:
        logger.error(f"Error during cleanup: {str(e)}")

async def validate_file(file: UploadFile) -> tuple[bool, str, str]:
    """
    Validate the uploaded file
    Returns: (is_valid, error_message, category)
    """
    try:
        # Read first 2048 bytes for MIME detection
        header = await file.read(2048)
        await file.seek(0)  # Reset file position

        # Use python-magic for accurate MIME type detection
        mime_type = magic.from_buffer(header, mime=True)

        if mime_type not in SUPPORTED_MIME_TYPES:
            return False, f"Unsupported file type: {mime_type}", ""

        category = SUPPORTED_MIME_TYPES[mime_type]

        # Check file size
        file_size = 0
        async for chunk in file.stream():
            file_size += len(chunk)
            if file_size > MAX_FILE_SIZE[category]:
                return False, f"File too large for {category}. Maximum size: {MAX_FILE_SIZE[category] / (1024*1024)}MB", ""

        await file.seek(0)  # Reset file position again
        return True, "", category

    except Exception as e:
        return False, f"Error validating file: {str(e)}", ""

# Routes
@router.post("/upload/", response_model=UploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = BackgroundTasks()
):
    """
    Upload a media file for processing with Gemini API
    - Supports audio, image, video, and document files
    - Files are stored for 48 hours
    - Returns a file ID that can be used with the Gemini API
    """
    try:
        # Validate file
        is_valid, error_message, category = await validate_file(file)
        if not is_valid:
            raise HTTPException(status_code=400, detail=error_message)

        # Read file content
        content = await file.read()
        file_hash = get_file_hash(content)

        # Create filename with category prefix
        extension = mimetypes.guess_extension(file.content_type) or ''
        filename = f"{category}_{file_hash}{extension}"
        file_path = os.path.join(UPLOAD_DIR, filename)

        # Save file
        async with aiofiles.open(file_path, 'wb') as out_file:
            await out_file.write(content)

        # Record metadata
        upload_time = datetime.now()
        expiry_time = upload_time + timedelta(hours=48)

        file_info = FileMetadata(
            file_id=file_hash,
            original_name=file.filename,
            mime_type=file.content_type,
            size=len(content),
            upload_time=upload_time,
            expiry_time=expiry_time,
            category=category
        )

        # Schedule cleanup
        background_tasks.add_task(cleanup_expired_files, background_tasks)

        return UploadResponse(
            success=True,
            message="File uploaded successfully",
            file_info=file_info
        )

    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Error uploading file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error uploading file: {str(e)}")

@router.get("/files/{file_id}", response_model=FileMetadata)
async def get_file_info(file_id: str):
    """Get metadata for an uploaded file"""
    try:
        # Search for file in upload directory
        for filename in os.listdir(UPLOAD_DIR):
            if file_id in filename:
                file_path = os.path.join(UPLOAD_DIR, filename)
                category = filename.split('_')[0]

                # Get file stats
                stats = os.stat(file_path)
                upload_time = datetime.fromtimestamp(stats.st_mtime)
                expiry_time = upload_time + timedelta(hours=48)

                # Detect MIME type
                mime_type = magic.from_file(file_path, mime=True)

                return FileMetadata(
                    file_id=file_id,
                    original_name=filename,
                    mime_type=mime_type,
                    size=stats.st_size,
                    upload_time=upload_time,
                    expiry_time=expiry_time,
                    category=category
                )

        raise HTTPException(status_code=404, detail="File not found")

    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Error retrieving file info: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error retrieving file info: {str(e)}")

@router.delete("/files/{file_id}")
async def delete_file(file_id: str):
    """Delete an uploaded file"""
    try:
        # Search for file in upload directory
        for filename in os.listdir(UPLOAD_DIR):
            if file_id in filename:
                file_path = os.path.join(UPLOAD_DIR, filename)
                os.remove(file_path)
                return JSONResponse(content={
                    "success": True,
                    "message": f"File {file_id} deleted successfully"
                })

        raise HTTPException(status_code=404, detail="File not found")

    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Error deleting file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error deleting file: {str(e)}")

@router.get("/files/", response_model=List[FileMetadata])
async def list_files():
    """List all uploaded files"""
    try:
        files = []
        for filename in os.listdir(UPLOAD_DIR):
            file_path = os.path.join(UPLOAD_DIR, filename)
            category = filename.split('_')[0]
            file_id = filename.split('_')[1].split('.')[0]

            # Get file stats
            stats = os.stat(file_path)
            upload_time = datetime.fromtimestamp(stats.st_mtime)
            expiry_time = upload_time + timedelta(hours=48)

            # Detect MIME type
            mime_type = magic.from_file(file_path, mime=True)

            files.append(FileMetadata(
                file_id=file_id,
                original_name=filename,
                mime_type=mime_type,
                size=stats.st_size,
                upload_time=upload_time,
                expiry_time=expiry_time,
                category=category
            ))

        return files

    except Exception as e:
        logger.error(f"Error listing files: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error listing files: {str(e)}")