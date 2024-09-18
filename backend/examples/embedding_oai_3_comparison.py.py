# backend/routers/post/embeddings/index.py
from openai import OpenAI
import os
import numpy as np
import dotenv

# Load environment variables from a .env file, if needed
dotenv.load_dotenv()

# Initialize the OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

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
    response = client.embeddings.create(
        model=model,
        input=input_text,
        encoding_format="float"
    )
    return response.data[0].embedding

# Function to zero-pad the smaller embedding to match the larger one
def pad_embedding(embedding, target_length):
    """
    Pad the given embedding with zeros until its length matches target_length.
    This ensures both embeddings can be compared by making them the same size.
    """
    padding = [0] * (target_length - len(embedding))  # Create a list of zeros for padding
    return np.concatenate([embedding, padding])  # Concatenate the original embedding with padding

# Input text
input_text = "Elijah Arbee, who is the <Token>insert_here</Token>."

# Generate embeddings using both models
small_embedding = generate_embedding("text-embedding-3-small", input_text)
large_embedding = generate_embedding("text-embedding-3-large", input_text)

# Print the embeddings' sizes before transformation
print(f"\nSmall embedding dimensions: {len(small_embedding)}")
print(f"Large embedding dimensions: {len(large_embedding)}")

# Pad the smaller embedding to match the size of the larger one
padded_small_embedding = pad_embedding(small_embedding, len(large_embedding))

# Print the embeddings' sizes after padding
print(f"\nPadded small embedding dimensions: {len(padded_small_embedding)}")
print(f"Large embedding dimensions (unchanged): {len(large_embedding)}")

# Normalize both embeddings
normalized_padded_small_embedding = normalize_l2(padded_small_embedding)
normalized_large_embedding = normalize_l2(large_embedding)

# Calculate cosine similarity between padded small and large embeddings
cosine_similarity = np.dot(normalized_padded_small_embedding, normalized_large_embedding)
print(f"\nCosine similarity between padded small and large embeddings: {cosine_similarity}")
