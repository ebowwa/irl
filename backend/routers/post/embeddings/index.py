# backend/routers/post/embeddings/index.py
# TODO: Improvements and make more easy to use for any purpose, idealy post request to embeddings
from fastapi import APIRouter, HTTPException
from openai import OpenAI
import os
import numpy as np
import dotenv

# Load environment variables from a .env file
dotenv.load_dotenv()

# Initialize the OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# Initialize FastAPI Router
router = APIRouter()

# Function to normalize embeddings using L2 norm
def normalize_l2(x):
    """
    Normalize a vector to have a unit L2 norm.
    If the norm is zero, return the vector as is.
    """
    x = np.array(x)
    norm = np.linalg.norm(x)
    return x / norm if norm != 0 else x

# Function to generate embeddings
def generate_embedding(model, input_text):
    """
    Generate embeddings using the specified model.
    Returns the embedding of the input text as a list of floats.
    """
    try:
        response = client.embeddings.create(
            model=model,
            input=input_text,
            encoding_format="float"
        )
        return response.data[0].embedding
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Function to zero-pad the smaller embedding to match the larger one
def pad_embedding(embedding, target_length):
    """
    Pad the given embedding with zeros until its length matches target_length.
    This ensures both embeddings can be compared by making them the same size.
    """
    padding = [0] * (target_length - len(embedding))
    return np.concatenate([embedding, padding])

# Route to generate embeddings for input text
@router.post("/generate-embedding/")
async def create_embedding(input_text: str, model: str = "text-embedding-3-small"):
    """
    Generate embedding for the given input text using the specified model.
    """
    embedding = generate_embedding(model, input_text)
    return {"embedding": embedding, "length": len(embedding)}

# Route to normalize an embedding using L2 norm
@router.post("/normalize-embedding/")
async def normalize_embedding(embedding: list):
    """
    Normalize the given embedding vector using the L2 norm.
    """
    normalized_embedding = normalize_l2(embedding)
    return {"normalized_embedding": normalized_embedding, "length": len(normalized_embedding)}

# Route to pad an embedding to a specific length
@router.post("/pad-embedding/")
async def pad_embedding_route(embedding: list, target_length: int):
    """
    Zero-pad the given embedding to match the target length.
    """
    if len(embedding) > target_length:
        raise HTTPException(status_code=400, detail="Target length must be greater than the current embedding length.")
    padded_embedding = pad_embedding(embedding, target_length)
    return {"padded_embedding": padded_embedding, "length": len(padded_embedding)}

# Route to calculate cosine similarity between two embeddings
@router.post("/cosine-similarity/")
async def calculate_cosine_similarity(embedding1: list, embedding2: list):
    """
    Calculate the cosine similarity between two embeddings.
    """
    if len(embedding1) != len(embedding2):
        raise HTTPException(status_code=400, detail="Embeddings must be of the same length.")
    normalized_embedding1 = normalize_l2(embedding1)
    normalized_embedding2 = normalize_l2(embedding2)
    cosine_similarity = np.dot(normalized_embedding1, normalized_embedding2)
    return {"cosine_similarity": cosine_similarity}
