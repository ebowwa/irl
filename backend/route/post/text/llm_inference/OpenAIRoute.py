# backend/routers/post/llm_inference/openai_generate_text_route.py
# -------------------------------------
# DO NOT REVERT BACK TO OPENAI>1.0
# -------------------------------------
# API routes for OpenAI and Ollama LLM inference
# Handles dynamic API requests and streaming responses
# -------------------------------------

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from services.openaiGenerateTextService import OpenAIRequestConfig, generate_text_service  # Import the service components

# -------------------------------------
# Router Initialization
# -------------------------------------
router = APIRouter()

# -------------------------------------
# Route: Generate Text
# -------------------------------------
@router.post("/generate-text/")
def generate_text(config: OpenAIRequestConfig):
    """Route to handle text generation via OpenAI or Ollama models."""
    try:
        # Call the service to handle text generation
        service_response = generate_text_service(config)

        # Handle streaming responses
        if config.stream:
            return StreamingResponse(service_response, media_type='text/plain')
        else:
            return service_response

    except HTTPException as e:
        # Re-raise HTTP exceptions to be handled by FastAPI
        raise e
    except Exception as e:
        # Handle unexpected exceptions
        raise HTTPException(status_code=500, detail=f"Server Error: {str(e)}")
