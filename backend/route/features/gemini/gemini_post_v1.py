# File: /backend/route/features/gemini_post.py
from fastapi import APIRouter, HTTPException, Form
from typing import Optional
from services.geminiService import generate_content, configure_gemini, list_models, list_supported_languages
from utils.gemini_config import SUPPORTED_LANGUAGES
import logging

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
    language: Optional[str] = Form("en", description="Language code", example="en"),
    candidate_count: int = Form(1, description="Number of candidate responses", ge=1, le=5),
    max_output_tokens: int = Form(8192, description="Maximum number of tokens in the output", ge=1, le=8192),
    temperature: float = Form(0.95, description="Sampling temperature", ge=0.0, le=2.0),
    top_p: float = Form(0.9, description="Nucleus sampling parameter", ge=0.0, le=1.0),
    response_mime_type: str = Form("application/json", description="Response MIME type", example="application/json"),
    stream: bool = Form(False, description="Stream the response")
):
    """
    Generate content using Gemini models. Supports text input.
    """
    # Validate the language
    if language not in SUPPORTED_LANGUAGES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported language. Supported languages: {SUPPORTED_LANGUAGES}"
        )

    # Prepare contents
    contents = []
    if text:
        contents.append({
            "role": "user",
            "parts": [{"text": text}]
        })

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

    # Generate content using the service
    try:
        response = generate_content(
            model=model,
            contents=contents,
            config=generation_config,
            safety_settings=safety_settings,
            stream=stream
        )

        logger.info("Received response from Gemini API.")

        # Prepare the response based on candidate_count
        if candidate_count == 1:
            # For a single candidate, return response.text
            return {"response": response.text}
        else:
            # For multiple candidates, extract texts from response.candidates
            responses = []
            for candidate in response.candidates:
                # Access the appropriate field based on the response structure
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
