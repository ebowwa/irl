# services/audio_service.py
from fastapi import UploadFile, HTTPException
import logging
import google.generativeai as genai
from typing import List, Optional
from tenacity import retry, stop_after_attempt, wait_exponential

logger = logging.getLogger(__name__)
 
class AudioService:
    SUPPORTED_MIME_TYPES = {
        "audio/wav", "audio/mp3", "audio/aiff",
        "audio/aac", "audio/ogg", "audio/flac"
    }

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
    async def process_file(self, file: UploadFile) -> object:
        try:
            if file.content_type not in self.SUPPORTED_MIME_TYPES:
                raise HTTPException(
                    status_code=400,
                    detail=f"Unsupported file type: {file.content_type}"
                )

            content = await file.read()
            return self.upload_to_gemini(content, file.content_type)
        except Exception as e:
            logger.error(f"Error processing file {file.filename}: {e}")
            raise HTTPException(status_code=500, detail=str(e))

    def upload_to_gemini(self, file_content: bytes, mime_type: Optional[str] = None) -> object:
        try:
            import io
            file_obj = io.BytesIO(file_content)
            uploaded_file = genai.upload_file(file_obj, mime_type=mime_type)
            logger.info(f"Successfully uploaded file as: {uploaded_file.uri}")
            return uploaded_file
        except Exception as e:
            logger.error(f"Error uploading to Gemini: {e}")
            raise