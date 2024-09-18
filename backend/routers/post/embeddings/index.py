# backend/routers/post/embeddings/index.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from openai import OpenAI
import os
import numpy as np
from dotenv import load_dotenv
import tiktoken

# Load environment variables from a .env file
load_dotenv()

# Initialize the OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# Initialize FastAPI Router
router = APIRouter()

# Define available models
MODELS = {
    "small": "text-embedding-3-small",
    "large": "text-embedding-3-large"
}

# Define input model
class EmbeddingInput(BaseModel):
    input_text: str
    normalize: bool = False

# Function to normalize embeddings using L2 norm
def normalize_l2(x):
    """
    Normalize a vector to have a unit L2 norm.
    If the norm is zero, return the vector as is.
    """
    x = np.array(x)
    norm = np.linalg.norm(x)
    return x / norm if norm != 0 else x

# Function to estimate token count
def estimate_tokens(text, model):
    """
    Estimate the number of tokens in the input text for the given model.
    """
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

# Function to generate embeddings
def generate_embedding(model, input_text, normalize):
    """
    Generate embeddings using the specified model.
    Returns the embedding of the input text and metadata.
    """
    try:
        response = client.embeddings.create(
            model=model,
            input=input_text,
            encoding_format="float"
        )
        embedding = response.data[0].embedding
        if normalize:
            embedding = normalize_l2(embedding).tolist()
        
        # Estimate token count
        token_count = estimate_tokens(input_text, model)
        
        # Calculate additional metadata
        metadata = {
            "model": model,
            "dimensions": len(embedding),
            "token_count": token_count,
            "input_char_count": len(input_text),
            "normalized": normalize
        }
        
        return embedding, metadata
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Route to generate embeddings for input text using text-embedding-3-small
@router.post("/small")
async def create_small_embedding(input_data: EmbeddingInput):
    """
    Generate embedding for the given input text using the text-embedding-3-small model.
    """
    model = MODELS["small"]
    embedding, metadata = generate_embedding(model, input_data.input_text, input_data.normalize)
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
    model = MODELS["large"]
    embedding, metadata = generate_embedding(model, input_data.input_text, input_data.normalize)
    return {
        "embedding": embedding,
        "metadata": metadata
    }