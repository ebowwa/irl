# File: backend/routers/media_router.py
from fastapi import APIRouter, HTTPException, UploadFile, Request
from fastapi.responses import FileResponse
import os
import mimetypes
import tempfile
from backend.utils.audio_utils import process_audio_upload, cleanup_tempfile  # Your existing utility functions

# Create the APIRouter instance
router = APIRouter()

# Store paths for temporarily available media files
media_files = {}

@router.post("/upload/")
async def upload_file(file: UploadFile, request: Request):
    """
    Upload an audio, image, or video file and temporarily make it available via a unique URL.
    The URL is dynamically generated based on the environment and request.
    """
    if file.content_type.startswith('audio'):
        # Process the uploaded audio file using the audioUtils
        temp_file_path = await process_audio_upload(file)
    elif file.content_type.startswith(('image', 'video')):
        try:
            # For image or video, we directly create a temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
                temp_file.write(await file.read())
                temp_file_path = temp_file.name
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to save file: {str(e)}")
    else:
        raise HTTPException(status_code=400, detail="Unsupported file type.")
    
    # Store the temp file in a dictionary to retrieve it by filename
    filename = os.path.basename(temp_file_path)
    media_files[filename] = temp_file_path

    # Dynamically generate the file URL
    file_url = request.url_for('serve_media', filename=filename)

    # Return the dynamically generated URL
    return {"url": str(file_url)}

@router.get("/media/{filename}")
async def serve_media(filename: str):
    """
    Serve a media file (audio, image, or video) temporarily available via a URL.
    """
    file_path = media_files.get(filename)

    # Check if the file exists and is being tracked in the dictionary
    if not file_path or not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")

    # Guess the media type based on the file extension
    media_type, _ = mimetypes.guess_type(file_path)

    return FileResponse(path=file_path, media_type=media_type)

@router.delete("/media/{filename}")
async def delete_media(filename: str):
    """
    Manually delete the temporary media file and remove its entry from the dictionary.
    """
    file_path = media_files.pop(filename, None)
    if file_path:
        cleanup_tempfile(file_path)
        return {"detail": f"File {filename} deleted successfully"}
    else:
        raise HTTPException(status_code=404, detail="File not found")
