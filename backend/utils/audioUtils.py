# backend/utils/audioUtils.py
import os
import tempfile
from fastapi import UploadFile, HTTPException

async def process_audio_upload(file: UploadFile):
    """
    Processes the uploaded audio file by validating and saving it to a temporary location.
    Returns the file path of the saved file.
    """
    if file.content_type not in ["audio/mpeg", "audio/wav", "audio/ogg"]:
        raise HTTPException(status_code=400, detail="Invalid audio file type.")
    
    try:
        # Create a temporary file and save the uploaded audio content
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            file_content = await file.read()
            temp_file.write(file_content)
            return temp_file.name
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save audio file: {str(e)}")


def cleanup_tempfile(filepath: str):
    """
    Removes the temporary file after processing.
    """
    if filepath and os.path.exists(filepath):
        os.remove(filepath)
