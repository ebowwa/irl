from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from backend.utils.audio_utils import process_audio_upload, cleanup_tempfile

router = APIRouter()

# Upload audio route using the helper function
@router.post("/upload-audio/")
async def upload_audio(file: UploadFile = File(...)):
    try:
        # Process the audio file (validate and save)
        temp_file_path = await process_audio_upload(file)

        # Perform any additional processing here if needed

        return JSONResponse({
            "filename": file.filename,
            "message": "File uploaded successfully"
        })
    finally:
        # Clean up the temporary file
        cleanup_tempfile(temp_file_path)
