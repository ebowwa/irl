# services/gemini_service.py

import os
import google.generativeai as genai
from utils.gemini_config import MODEL_VARIANTS, SUPPORTED_RESPONSE_MIME_TYPES, SUPPORTED_LANGUAGES
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

def generate_content(model: str, contents: list, config: dict, safety_settings: dict, stream: bool):
    """
    Generates content using the specified Gemini model and configuration.

    Args:
        model (str): The model variant to use.
        contents (list): The content to generate from.
        config (dict): Generation configuration parameters.
        safety_settings (dict): Safety settings for content generation.
        stream (bool): Whether to stream the response.

    Returns:
        response: The raw response object from the Gemini API.
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

    # Call the model to generate content
    try:
        response = gemini_model.generate_content(
            contents=contents,
            generation_config=config,
            safety_settings=safety_settings,
            stream=stream
        )
        logger.info("Content generation successful.")
        return response  # Return the raw response object
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