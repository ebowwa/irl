# backend/routers/post/embeddingRouter/index.py
from fastapi import APIRouter
from pydantic import BaseModel
from backend.services.embeddingService import generate_embedding

# Initialize FastAPI Router
router = APIRouter()

# Define input model
class EmbeddingInput(BaseModel):
    input_text: str
    normalize: bool = False

# Route to generate embeddings for input text using text-embedding-3-small
@router.post("/small")
async def create_small_embedding(input_data: EmbeddingInput):
    """
    Generate embedding for the given input text using the text-embedding-3-small model.
    """
    embedding, metadata = generate_embedding("small", input_data.input_text, input_data.normalize)
    return {
        "embedding": embedding,
        "metadata": metadata
    }

# Route to generate embeddings for input text using text-embedding-3-large
@router.post("/large")
async def create_large_embedding(input_data: EmbeddingInput):
    """
    Generate embedding for the given input text using the text-embedding-3-large model.
    """
    embedding, metadata = generate_embedding("large", input_data.input_text, input_data.normalize)
    return {
        "embedding": embedding,
        "metadata": metadata
    }
