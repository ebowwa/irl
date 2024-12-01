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
    MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB limit
    CHUNK_SIZE = 8 * 1024 * 1024  # 8MB chunks

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
    async def process_file(self, file: UploadFile) -> dict:
        try:
            if file.content_type not in self.SUPPORTED_MIME_TYPES:
                raise HTTPException(
                    status_code=400,
                    detail=f"Unsupported file type: {file.content_type}"
                )

            # Read file in chunks to avoid memory issues
            content = bytearray()
            total_size = 0
            chunk = await file.read(self.CHUNK_SIZE)
            
            while chunk:
                total_size += len(chunk)
                if total_size > self.MAX_FILE_SIZE:
                    raise HTTPException(
                        status_code=413,
                        detail=f"File size exceeds maximum limit of {self.MAX_FILE_SIZE/(1024*1024)}MB"
                    )
                content.extend(chunk)
                chunk = await file.read(self.CHUNK_SIZE)

            uploaded_file = await self.upload_to_gemini(bytes(content), file.content_type)
            return {
                "file_obj": uploaded_file,
                "uri": uploaded_file.uri
            }
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error processing file {file.filename}: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=str(e))

    async def upload_to_gemini(self, file_content: bytes, mime_type: Optional[str] = None) -> object:
        try:
            import io
            file_obj = io.BytesIO(file_content)
            
            # Add detailed logging
            logger.debug(f"Uploading file to Gemini (size: {len(file_content)} bytes, mime_type: {mime_type})")
            
            # Ensure mime_type is always set
            if not mime_type:
                mime_type = "audio/ogg"  # Default to ogg if not specified
                logger.warning(f"No mime_type specified, defaulting to {mime_type}")
            
            uploaded_file = genai.upload_file(file_obj, mime_type=mime_type)
            logger.info(f"Successfully uploaded file as: {uploaded_file.uri}")
            return uploaded_file
        except Exception as e:
            logger.error(f"Error uploading to Gemini: {e}", exc_info=True)
            if "Broken pipe" in str(e):
                logger.error("Network connection was interrupted during upload")
                raise HTTPException(
                    status_code=503,
                    detail="Upload failed due to network interruption. Please try again."
                )
            raise HTTPException(status_code=500, detail=str(e))