# services/gemini_service.py

import os
import asyncio
import google.generativeai as genai
from backend.utils._extensions.gemini_config import MODEL_VARIANTS, SUPPORTED_RESPONSE_MIME_TYPES, SUPPORTED_LANGUAGES
from fastapi import HTTPException
import logging
from dotenv import load_dotenv
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def configure_gemini():
    """Configures the Gemini API client with the API key."""
    GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
    if not GOOGLE_API_KEY:
        raise ValueError("GOOGLE_API_KEY is not set in the environment variables.")
    genai.configure(api_key=GOOGLE_API_KEY)
    logger.info("Gemini API client configured.")

async def generate_content_stream(model: str, contents: list, config: dict, safety_settings: dict):
    """
    Generates content using the specified Gemini model and configuration, streaming the response.

    Yields:
        str: Chunks of the response.
    """
    logger.info(f"Generating content using model: {model}")

    # Validate the model name
    if model not in MODEL_VARIANTS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported model variant. Supported models: {list(MODEL_VARIANTS.keys())}"
        )

    # Validate the response MIME type
    response_mime_type = config.get("response_mime_type", "application/json")
    if response_mime_type not in SUPPORTED_RESPONSE_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported response MIME type. Supported types: {SUPPORTED_RESPONSE_MIME_TYPES}"
        )

    # Initialize the generative model
    gemini_model = genai.GenerativeModel(model_name=model)
    logger.info("Initialized Gemini GenerativeModel.")

    try:
        loop = asyncio.get_event_loop()

        def blocking_stream():
            return gemini_model.generate_content(
                contents=contents,
                generation_config=config,
                safety_settings=safety_settings,
                stream=True
            )

        response_iterator = await loop.run_in_executor(None, blocking_stream)

        for chunk in response_iterator:
            # Adjust based on the actual structure of the chunk
            yield chunk.text if hasattr(chunk, 'text') else str(chunk)
    except Exception as e:
        logger.error(f"Generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Generation failed: {e}")

async def generate_content(model: str, contents: list, config: dict, safety_settings: dict):
    """
    Generates content using the specified Gemini model and configuration.

    Returns:
        response: The full response object.
    """
    logger.info(f"Generating content using model: {model}")

    # Validate the model name
    if model not in MODEL_VARIANTS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported model variant. Supported models: {list(MODEL_VARIANTS.keys())}"
        )

    # Validate the response MIME type
    response_mime_type = config.get("response_mime_type", "application/json")
    if response_mime_type not in SUPPORTED_RESPONSE_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported response MIME type. Supported types: {SUPPORTED_RESPONSE_MIME_TYPES}"
        )

    # Initialize the generative model
    gemini_model = genai.GenerativeModel(model_name=model)
    logger.info("Initialized Gemini GenerativeModel.")

    try:
        loop = asyncio.get_event_loop()

        def blocking_call():
            return gemini_model.generate_content(
                contents=contents,
                generation_config=config,
                safety_settings=safety_settings,
                stream=False
            )

        response = await loop.run_in_executor(None, blocking_call)
        logger.info("Content generation successful.")
        return response
    except Exception as e:
        logger.error(f"Generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Generation failed: {e}")

# 3. List available models
def list_models():
    """Returns a list of available Gemini model variants."""
    return {"models": MODEL_VARIANTS}

# 4. List supported languages
def list_supported_languages():
    """Returns a list of supported languages."""
    return {"languages": SUPPORTED_LANGUAGES}
