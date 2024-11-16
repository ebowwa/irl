# File: /backend/route/features/gemini/gemini_post_v2.py
# need to test that this takes multiple media types since it uses the new google media upload, audio has been tested and as such should be retested last images and video first use curl to extract example media files to use
from fastapi import APIRouter, HTTPException, Form, File, UploadFile
from typing import Optional, List
from services.geminiService import generate_content, configure_gemini, list_models, list_supported_languages
from utils.gemini_config import SUPPORTED_LANGUAGES
from route.features.gemini.google_media_upload import validate_file, get_file_info
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize the Gemini service
configure_gemini()

# Initialize the API router with a different prefix to differentiate from v1
router = APIRouter()
#    prefix="/v2",
#    tags=["Gemini Models V2"],
#    responses={401: {"description": "Unauthorized"}}

@router.post("/generate", summary="Generate Content with Media Support")
async def generate_content_route(
    model: str = Form(..., description="Model variant to use", example="gemini-1.5-flash-8b"),
    text: Optional[str] = Form(None, description="Input text prompt"),
    files: Optional[List[UploadFile]] = File(None, description="Media files to process"),
    file_ids: Optional[List[str]] = Form(None, description="IDs of previously uploaded files"),
    language: Optional[str] = Form("en", description="Language code", example="en"),
    candidate_count: int = Form(1, description="Number of candidate responses", ge=1, le=5),
    max_output_tokens: int = Form(8192, description="Maximum number of tokens in the output", ge=1, le=8192),
    temperature: float = Form(0.95, description="Sampling temperature", ge=0.0, le=2.0),
    top_p: float = Form(0.9, description="Nucleus sampling parameter", ge=0.0, le=1.0),
    response_mime_type: str = Form("application/json", description="Response MIME type", example="application/json"),
    stream: bool = Form(False, description="Stream the response")
):
    """
    Enhanced content generation endpoint supporting both text and media inputs.
    Handles both direct file uploads and references to previously uploaded files.
    """
    try:
        # Validate the language
        if language not in SUPPORTED_LANGUAGES:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported language. Supported languages: {SUPPORTED_LANGUAGES}"
            )

        # Prepare contents
        contents = []

        # Handle text input
        if text:
            contents.append({
                "role": "user",
                "parts": [{"text": text}]
            })

        # Handle direct file uploads
        if files:
            for file in files:
                try:
                    # Validate file
                    is_valid, error_message, category = await validate_file(file)
                    if not is_valid:
                        raise HTTPException(status_code=400, detail=error_message)

                    # Read file content
                    content = await file.read()

                    # Add to contents
                    contents.append({
                        "role": "user",
                        "parts": [{
                            "inline_data": {
                                "mime_type": file.content_type,
                                "data": content
                            }
                        }]
                    })

                    await file.seek(0)

                except Exception as e:
                    logger.error(f"Error processing file {file.filename}: {str(e)}")
                    raise HTTPException(
                        status_code=500,
                        detail=f"Error processing file {file.filename}: {str(e)}"
                    )

        # Handle previously uploaded files
        if file_ids:
            for file_id in file_ids:
                try:
                    # Get file info and content
                    file_info = await get_file_info(file_id)
                    if not file_info:
                        raise HTTPException(
                            status_code=404,
                            detail=f"File with ID {file_id} not found"
                        )

                    # Add to contents using the stored file
                    contents.append({
                        "role": "user",
                        "parts": [{
                            "file_data": {
                                "file_id": file_id,
                                "mime_type": file_info.mime_type
                            }
                        }]
                    })

                except Exception as e:
                    logger.error(f"Error processing file ID {file_id}: {str(e)}")
                    raise HTTPException(
                        status_code=500,
                        detail=f"Error processing file ID {file_id}: {str(e)}"
                    )

        # Define generation configuration
        generation_config = {
            "temperature": temperature,
            "top_p": top_p,
            "max_output_tokens": max_output_tokens,
            "candidate_count": candidate_count,
            "response_mime_type": response_mime_type
        }

        # Define safety settings
        safety_settings = {
            'HATE': 'BLOCK_NONE',
            'HARASSMENT': 'BLOCK_NONE',
            'SEXUAL': 'BLOCK_NONE',
            'DANGEROUS': 'BLOCK_NONE'
        }

        # Generate content
        response = generate_content(
            model=model,
            contents=contents,
            config=generation_config,
            safety_settings=safety_settings,
            stream=stream
        )

        logger.info("Received response from Gemini API.")

        # Format response
        if candidate_count == 1:
            return {"response": response.text}
        else:
            responses = []
            for candidate in response.candidates:
                if hasattr(candidate, 'text') and isinstance(candidate.text, str):
                    responses.append(candidate.text)
                elif hasattr(candidate, 'content') and isinstance(candidate.content, str):
                    responses.append(candidate.content)
                else:
                    responses.append("Unknown content")
            return {"responses": responses}

    except Exception as e:
        logger.error(f"Generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Generation failed: {e}")