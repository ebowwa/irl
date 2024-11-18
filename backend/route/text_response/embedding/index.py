# backend/routers/post/embeddingRouter/embedding_generate_route.py
# -------------------------------------
# DO NOT REVERT BACK TO OPENAI>1.0
# -------------------------------------
# API routes for generating text embeddings.
# Handles requests for different embedding models via a single route.
# -------------------------------------

from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from services.embeddingGenerateService import EmbeddingInput, generate_embedding_service

# -------------------------------------
# Initialize FastAPI Router
# -------------------------------------
router = APIRouter()

# -------------------------------------
# Route: Generate Embedding
# -------------------------------------
@router.post("/generate-embedding/")
async def create_embedding(input_data: EmbeddingInput):
    """
    Generate embedding for the given input text using the specified model.
    
    Args:
        input_data (EmbeddingInput): The input data containing text, normalization flag, and model.
    
    Returns:
        JSONResponse: A JSON response containing the embedding and metadata.
    """
    try:
        embedding_result = generate_embedding_service(input_data)
        return JSONResponse(content=embedding_result)
    except ValueError as ve:
        # Handle validation errors (e.g., invalid model)
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        # Handle unexpected errors
        raise HTTPException(status_code=500, detail=f"Embedding Generation Error: {str(e)}")
