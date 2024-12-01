# api/routes.py
from fastapi import APIRouter, File, UploadFile, Query, HTTPException, Depends, Body, Path, Form
from fastapi.responses import JSONResponse
from typing import List, Optional, Dict, Union
import asyncio
import logging
import json
import os
from ..services.auth_service import AuthService
from ..services.audio_service import AudioService
from ..services.gemini_service import GeminiService
from ..services.storage_service import StorageService
from ..configs.schemas import SchemaManager
from pydantic import BaseModel, ConfigDict, ValidationError

logger = logging.getLogger(__name__)

# Constants
ALLOWED_AUDIO_EXTENSIONS = ('.wav', '.mp3', '.aiff', '.aac', '.ogg', '.flac')
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB

# Initialize services
try:
    schema_manager = SchemaManager()
    auth_service = AuthService()
    audio_service = AudioService()
    gemini_service = GeminiService(schema_manager)
    storage_service = StorageService()
except Exception as e:
    logger.error(f"Failed to initialize services: {e}")
    raise

router = APIRouter()

class AudioProcessingRequest(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        protected_namespaces=(),  # Disable protected namespaces to resolve model_name conflict
        json_schema_extra={
            "example": {
                "prompt_type": "transcription_v1",
                "model_name": "gemini-1.5-flash",
                "temperature": 0.7
            }
        }
    )
    
    prompt_type: str = "transcription_v1"
    model_name: str = "gemini-1.5-flash"
    temperature: float = 0.7
    top_p: float = 0.95
    top_k: int = 40
    max_output_tokens: int = 8192

    @classmethod
    async def from_form(cls, form_data: str):
        """Parse form data into AudioProcessingRequest object."""
        try:
            data = json.loads(form_data)
            return cls(**data)
        except json.JSONDecodeError as e:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid JSON in audio_processing_request: {str(e)}"
            )
        except ValidationError as e:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid audio processing request: {str(e)}"
            )

@router.post("/process-audio")
async def process_audio(
    files: List[UploadFile] = File(...),
    audio_processing_request: str = Form(...),
    google_account_id: Optional[str] = Form(None),
    device_uuid: Optional[str] = Form(None)
):
    """Process audio files using Gemini API."""
    processed_files = []
    
    try:
        # Parse audio processing request
        request = await AudioProcessingRequest.from_form(audio_processing_request)
        
        # Verify user if credentials provided
        user_id = await auth_service.verify_user(google_account_id, device_uuid)
        
        # Get prompt configuration (will raise 400 if invalid)
        await schema_manager.get_prompt_text(request.prompt_type)
        
        for file in files:
            try:
                if isinstance(file, str):
                    # Handle file URI
                    result = await process_audio_uri(
                        file, 
                        request.prompt_type,
                        request.model_name,
                        request.temperature,
                        request.top_p,
                        request.top_k,
                        request.max_output_tokens
                    )
                    processed_files.append(result)
                    continue

                # Validate file type
                if not file.filename.lower().endswith(ALLOWED_AUDIO_EXTENSIONS):
                    processed_files.append({
                        "status": "failed",
                        "filename": file.filename,
                        "error": f"Invalid file type. Allowed types: {', '.join(ALLOWED_AUDIO_EXTENSIONS)}"
                    })
                    continue

                # Read and process file
                try:
                    contents = bytearray()
                    file_size = 0
                    chunk_size = 8192

                    # Read file in chunks
                    while True:
                        try:
                            chunk = await file.read(chunk_size)
                            if not chunk:
                                break
                            
                            contents.extend(chunk)
                            file_size += len(chunk)
                            
                            if file_size > MAX_FILE_SIZE:
                                processed_files.append({
                                    "status": "failed",
                                    "filename": file.filename,
                                    "error": f"File too large. Maximum size: {MAX_FILE_SIZE/1024/1024}MB"
                                })
                                break
                        except Exception as e:
                            logger.error(f"Error reading chunk from {file.filename}: {e}")
                            raise

                    if file_size <= MAX_FILE_SIZE:
                        # Process with Gemini
                        result = await gemini_service.process_audio_content(
                            content=bytes(contents),
                            prompt_type=request.prompt_type,
                            model_name=request.model_name,
                            temperature=request.temperature,
                            top_p=request.top_p,
                            top_k=request.top_k,
                            max_output_tokens=request.max_output_tokens
                        )
                        processed_files.append({
                            "status": "success",
                            "filename": file.filename,
                            "result": result
                        })

                finally:
                    # Ensure proper cleanup
                    try:
                        await file.close()
                    except Exception as e:
                        logger.warning(f"Error closing file {file.filename}: {e}")
                    
                    if hasattr(file, 'file'):
                        try:
                            file.file.close()
                        except Exception as e:
                            logger.warning(f"Error closing file handle for {file.filename}: {e}")

            except Exception as e:
                logger.error(f"Error processing file {file.filename}: {e}", exc_info=True)
                processed_files.append({
                    "status": "failed",
                    "filename": file.filename,
                    "error": str(e)
                })

        return JSONResponse(content={"results": processed_files})

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in process_audio: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

@router.post("/process-audio-uri")
async def process_audio_uri(
    file_uri: str = Body(..., embed=True),
    audio_processing_request: AudioProcessingRequest = Body(..., embed=True),
    google_account_id: Optional[str] = Query(None),
    device_uuid: Optional[str] = Query(None)
):
    """Process audio using a Google media file URI."""
    try:
        # Verify user if credentials provided
        user_id = await auth_service.verify_user(google_account_id, device_uuid)
        
        # Get prompt configuration (will raise 400 if invalid)
        await schema_manager.get_prompt_text(audio_processing_request.prompt_type)

        # Validate file URI
        if not file_uri.startswith(("gs://", "http://", "https://")):
            raise HTTPException(
                status_code=400,
                detail="Invalid file URI. Must start with gs://, http://, or https://"
            )

        # Process the file
        try:
            result = await gemini_service.process_audio_uri(
                file_uri=file_uri,
                prompt_type=audio_processing_request.prompt_type,
                model_name=audio_processing_request.model_name,
                temperature=audio_processing_request.temperature,
                top_p=audio_processing_request.top_p,
                top_k=audio_processing_request.top_k,
                max_output_tokens=audio_processing_request.max_output_tokens
            )
            
            return JSONResponse(content={"results": [{
                "status": "success",
                "uri": file_uri,
                "result": result
            }]})

        except Exception as e:
            logger.error(f"Gemini processing failed: {e}", exc_info=True)
            return JSONResponse(content={"results": [{
                "status": "failed",
                "uri": file_uri,
                "error": f"Gemini processing failed: {str(e)}"
            }]})

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in process_audio_uri: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

# Prompt Schema CRUD endpoints
@router.post("/prompt-schema")
async def create_prompt_schema(request: Dict = Body(...)):
    """Create a new prompt schema configuration."""
    try:
        if request.get("prompt_type") == SchemaManager.DEFAULT_PROMPT_TYPE:
            raise HTTPException(status_code=400, detail=f"Cannot modify default prompt type: {SchemaManager.DEFAULT_PROMPT_TYPE}")
        
        result = await schema_manager.create_config(**request)
        return JSONResponse(content=result)
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Failed to create prompt schema: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/prompt-schema/{prompt_type}", response_model=Dict)
async def get_prompt_schema(prompt_type: str = Path(...)):
    """Get a prompt schema configuration by type."""
    try:
        result = await schema_manager.get_config(prompt_type)
        if not result:
            raise HTTPException(status_code=404, detail=f"Prompt schema not found: {prompt_type}")
        return JSONResponse(content=result)
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Failed to get prompt schema: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/prompt-schema/{prompt_type}", response_model=Dict)
async def update_prompt_schema(
    prompt_type: str = Path(...),
    prompt_text: Optional[str] = Body(None),
    response_schema: Optional[Dict] = Body(None)
):
    """Update an existing prompt schema configuration."""
    try:
        if prompt_type == SchemaManager.DEFAULT_PROMPT_TYPE:
            raise HTTPException(status_code=400, detail=f"Cannot modify default prompt type: {SchemaManager.DEFAULT_PROMPT_TYPE}")
        
        result = await schema_manager.update_config(prompt_type, prompt_text, response_schema)
        if not result:
            raise HTTPException(status_code=404, detail=f"Prompt schema not found: {prompt_type}")
        return JSONResponse(content=result)
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Failed to update prompt schema: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/prompt-schema/{prompt_type}")
async def delete_prompt_schema(prompt_type: str = Path(...)):
    """Delete a prompt schema configuration."""
    try:
        if prompt_type == SchemaManager.DEFAULT_PROMPT_TYPE:
            raise HTTPException(status_code=400, detail=f"Cannot delete default prompt type: {SchemaManager.DEFAULT_PROMPT_TYPE}")
            
        result = await schema_manager.delete_config(prompt_type)
        if not result:
            raise HTTPException(status_code=404, detail=f"Prompt schema not found: {prompt_type}")
        return JSONResponse(content={"status": "success", "message": f"Deleted prompt schema: {prompt_type}"})
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Failed to delete prompt schema: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": "2.0.0"}