# backend/services/embedding_generate_service.py
# -------------------------------------
# DO NOT REVERT BACK TO OPENAI>1.0
# -------------------------------------
# Service for generating text embeddings using various models.
# Handles embedding generation logic and related utilities.
# -------------------------------------

from pydantic import BaseModel, Field, validator
from typing import Tuple, Dict, Any, Optional
from services.embeddingService import generate_embedding  # Import the existing embedding service
import json

# -------------------------------------
# Pydantic Model for Embedding Input
# -------------------------------------
class EmbeddingInput(BaseModel):
    """Pydantic Model for Embedding Input."""
    
    input_text: str = Field(..., description="The text to generate embeddings for.")
    normalize: bool = Field(False, description="Whether to normalize the embedding vector.")
    model: str = Field(..., description="Model to use for embedding generation (e.g., 'small', 'large').")

    # -------------------------------------
    # Validators for Parameter Constraints
    # -------------------------------------
    @validator('model')
    def model_must_be_valid(cls, v):
        """Ensure that the model is either 'small' or 'large'."""
        if v not in ('small', 'large'):
            raise ValueError("Model must be either 'small' or 'large'.")
        return v

# -------------------------------------
# Service Function: Generate Embedding
# -------------------------------------
def generate_embedding_service(input_data: EmbeddingInput) -> Dict[str, Any]:
    """
    Generate embedding for the given input text using the specified model.
    
    Args:
        input_data (EmbeddingInput): The input data containing text, normalization flag, and model.
    
    Returns:
        Dict[str, Any]: A dictionary containing the embedding and metadata.
    """
    try:
        embedding, metadata = generate_embedding(input_data.model, input_data.input_text, input_data.normalize)
        return {
            "embedding": embedding,
            "metadata": metadata
        }
    except Exception as e:
        # Log the exception if logging is set up (not shown here)
        raise e  # Let the route handle the exception
