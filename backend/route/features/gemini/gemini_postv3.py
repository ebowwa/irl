# File: /backend/route/features/gemini/gemini_postv3.py

from fastapi import APIRouter, HTTPException, Form
from fastapi.responses import StreamingResponse
from typing import Optional, List
from services.geminiServicev2 import generate_content, generate_content_stream, configure_gemini
from utils.gemini_config import SUPPORTED_LANGUAGES
import logging
import base64
import httpx

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize the Gemini service
configure_gemini()

# Initialize the API router
router = APIRouter(
    tags=["Gemini Models"],
    responses={401: {"description": "Unauthorized"}}
)

@router.post("/generate", summary="Generate Content")
async def generate_content_route(
    model: str = Form(..., description="Model variant to use", example="gemini-1.5-flash-8b"),
    text: Optional[str] = Form(None, description="Input text prompt"),
    media_file_uri: Optional[str] = Form(None, description="URI of the uploaded media to use as input"),
    mime_type: Optional[str] = Form(None, description="MIME type of the uploaded media"),
    language: Optional[str] = Form("en", description="Language code", example="en"),
    candidate_count: int = Form(1, description="Number of candidate responses", ge=1, le=5),
    max_output_tokens: int = Form(8192, description="Maximum number of tokens in the output", ge=1, le=8192),
    temperature: float = Form(0.95, description="Sampling temperature", ge=0.0, le=2.0),
    top_p: float = Form(0.9, description="Nucleus sampling parameter", ge=0.0, le=1.0),
    response_mime_type: str = Form("application/json", description="Response MIME type", example="application/json"),
    stream: bool = Form(False, description="Stream the response")
):
    """
    Generate content using Gemini models. Supports text input and/or media inputs.
    """
    # Validate the language
    if language not in SUPPORTED_LANGUAGES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported language. Supported languages: {SUPPORTED_LANGUAGES}"
        )
    
    # Ensure at least one input is provided
    if not text and not media_file_uri:
        raise HTTPException(
            status_code=400,
            detail="At least one of 'text' or 'media_file_uri' must be provided."
        )
    
    # Prepare messages
    messages = []
    if text:
        messages.append({
            "author": "user",
            "content": {
                "parts": [
                    {
                        "text": text
                    }
                ]
            }
        })
    
    if media_file_uri and mime_type:
        # Download the media file from the URI
        async with httpx.AsyncClient() as client:
            response = await client.get(media_file_uri)
            if response.status_code != 200:
                raise HTTPException(
                    status_code=400,
                    detail=f"Failed to retrieve media from URI: {media_file_uri}"
                )
            media_data = response.content

        # Encode media data in base64
        media_data_base64 = base64.b64encode(media_data).decode('utf-8')

        # Append media to messages as a Blob
        messages.append({
            "author": "user",
            "content": {
                "parts": [
                    {
                        "blob": {
                            "mime_type": mime_type,
                            "data": media_data_base64
                        }
                    }
                ]
            }
        })
    elif media_file_uri and not mime_type:
        raise HTTPException(
            status_code=400,
            detail="MIME type is required when providing media_file_uri."
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

    try:
        if stream:
            # Handle streaming response
            async def stream_response():
                async for chunk in generate_content_stream(
                    model=model,
                    messages=messages,
                    config=generation_config,
                    safety_settings=safety_settings
                ):
                    yield chunk

            return StreamingResponse(stream_response(), media_type="text/plain")
        else:
            # Handle non-streaming response
            response = await generate_content(
                model=model,
                messages=messages,
                config=generation_config,
                safety_settings=safety_settings
            )

            logger.info("Received response from Gemini API.")

            # Prepare the response based on candidate_count
            if candidate_count == 1:
                # Access the first candidate's message content
                if response.candidates and len(response.candidates) > 0:
                    candidate = response.candidates[0]
                    text_response = candidate['content']['parts'][0].get('text', '')
                    return {"response": text_response}
                else:
                    return {"response": ""}
            else:
                responses = []
                for candidate in response.candidates:
                    if 'content' in candidate and 'parts' in candidate['content']:
                        parts = candidate['content']['parts']
                        text_content = ''.join([part.get('text', '') for part in parts])
                        responses.append(text_content)
                    else:
                        responses.append("Unknown content")
                return {"responses": responses}
    except Exception as e:
        logger.error(f"Generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Generation failed: {e}")
