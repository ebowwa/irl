import os
import numpy as np
from openai import OpenAI
from fastapi import HTTPException
from dotenv import load_dotenv
import tiktoken

# Load environment variables from a .env file
load_dotenv()

# Initialize the OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# Define available models
MODELS = {
    "small": "text-embedding-3-small",
    "large": "text-embedding-3-large"
}

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
    # Explicitly use 'cl100k_base' encoding for the specified models
    if model in ["text-embedding-3-small", "text-embedding-3-large"]:
        encoding = tiktoken.get_encoding("cl100k_base")
    else:
        encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))


# Function to generate embeddings
def generate_embedding(model_key: str, input_text: str, normalize: bool):
    """
    Generate embeddings using the specified model.
    Returns the embedding of the input text and metadata.
    """
    model = MODELS.get(model_key)
    if model is None:
        raise HTTPException(status_code=400, detail=f"Model '{model_key}' not available")

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

        # Metadata
        metadata = {
            "model": model,
            "dimensions": len(embedding),
            "token_count": token_count,
            "input_char_count": len(input_text),
            "normalized": normalize
        }

        return embedding, metadata
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding generation failed: {str(e)}")
