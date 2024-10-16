# backend/routers/post/image_generation/sdxl.py
import os
import requests
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

# APIRouter instance for creating API routes
router = APIRouter()
# Note: on amtrak wifi the peer refused the connection the api url 
# FAL API URL for fast-sdxl image generation and the FAL API Key from environment variables
FAL_API_URL = "https://queue.fal.run/fal-ai/fast-sdxl"
FAL_KEY = os.getenv("FAL_KEY")

# Error handling if API key is missing
if not FAL_KEY:
    raise ValueError("FAL_KEY environment variable not set. Please set your API key as an environment variable.")

# Model for the image generation request using Pydantic
class SDXLImageGenerationRequest(BaseModel):
    prompt: str  # Main image generation prompt
    negative_prompt: Optional[str] = ""  # Optional negative prompt
    image_size: Optional[str] = "square_hd"  # Image size, default is "square_hd"
    num_inference_steps: Optional[int] = 25  # Number of steps for inference, default is 25
    seed: Optional[int] = None  # Seed for reproducibility
    guidance_scale: Optional[float] = 7.5  # Guidance scale for image generation, default 7.5
    num_images: Optional[int] = 1  # Number of images to generate, default is 1
    loras: Optional[List[dict]] = []  # Optional: LoRA settings for specific model tweaks
    embeddings: Optional[List[dict]] = []  # Optional: Custom embeddings for the model
    enable_safety_checker: Optional[bool] = True  # Enable safety checker (for NSFW, etc.)
    safety_checker_version: Optional[str] = "v1"  # Safety checker version, default is "v1"
    expand_prompt: Optional[bool] = False  # Option to expand the prompt with additional context
    format: Optional[str] = "jpeg"  # Output image format, default is JPEG

# Route for submitting image generation requests to the fast-sdxl API
@router.post("/sdxl/generate")
def submit_sdxl_image_generation_request(payload: SDXLImageGenerationRequest):
    """
    Submits a request to generate an image via the fast-sdxl API.
    Handles errors if the request fails and returns request_id on success.
    """
    headers = {
        "Authorization": f"Key {FAL_KEY}",  # Authorization header with API key
        "Content-Type": "application/json"  # Sending JSON data
    }

    # Send POST request to FAL API
    response = requests.post(FAL_API_URL, json=payload.dict(), headers=headers)

    # Handle non-200 status codes
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Error submitting image generation request")

    response_data = response.json()
    request_id = response_data.get("request_id")

    # Check if request_id is missing from response
    if not request_id:
        raise HTTPException(status_code=500, detail="Failed to retrieve request ID")

    # Return request_id for the image generation job
    return {"request_id": request_id}

# Route to check the status of a submitted image generation request
@router.get("/sdxl/status/{request_id}")
def check_sdxl_request_status(request_id: str):
    """
    Checks the status of the submitted image generation request using the request ID.
    """
    status_url = f"{FAL_API_URL}/requests/{request_id}/status"  # Status URL for the request
    headers = {
        "Authorization": f"Key {FAL_KEY}"  # Authorization header with API key
    }

        # Send GET request to check the status
    response = requests.get(status_url, headers=headers)

    # Parse the JSON response
    try:
        response_data = response.json()
    except ValueError:
        raise HTTPException(status_code=500, detail="Malformed response received from the FAL API")

    # Check for 'detail' field indicating an error, even if status code is 200-299
    if "detail" in response_data:
        error_detail = response_data.get("detail", "Unknown error")
        raise HTTPException(status_code=response.status_code, detail=error_detail)

    # Check for 'status' field in the response
    if 'status' not in response_data:
        raise HTTPException(status_code=500, detail="Missing 'status' in FAL API response")

    # Return the status of the request
    return response_data

# Additional Pydantic models for image data and response handling
from pydantic import BaseModel
from typing import List, Optional

# Model for image metadata returned by the API
class ImageData(BaseModel):
    url: str  # URL of the generated image
    width: int  # Image width
    height: int  # Image height
    content_type: str  # Content type of the image (e.g., "image/jpeg")

# Model for the overall image response structure
class SDXLImageResponse(BaseModel):
    seed: Optional[int]  # Seed used for the image generation
    images: List[ImageData]  # List of generated images and their metadata
    prompt: str  # Prompt used to generate the image
    inference_time: Optional[float]  # Time taken for the inference process
    has_nsfw_concepts: List[bool]  # Flag indicating if NSFW concepts were detected

# Route to fetch the result of the image generation request
@router.get("/sdxl/result/{request_id}", response_model=SDXLImageResponse)
def fetch_sdxl_image_result(request_id: str):
    """
    Fetches the final generated image and metadata from the fast-sdxl API using the request_id.
    This version includes additional error handling, response validation, and proper logging.
    """
    result_url = f"{FAL_API_URL}/requests/{request_id}"  # URL to fetch the result
    headers = {
        "Authorization": f"Key {FAL_KEY}"  # Authorization header with API key
    }

    # Send GET request to fetch the image result
    response = requests.get(result_url, headers=headers)

    # Check if the response was successful
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Error fetching image result")

    # Parse the JSON response
    try:
        response_data = response.json()


        # Check for required fields in the response
        if 'images' not in response_data or not response_data['images']:
            raise HTTPException(status_code=500, detail="No images returned in the response")

        if 'prompt' not in response_data:
            raise HTTPException(status_code=500, detail="Prompt missing from the response")

        # Prepare the response model with parsed data
        image_response = SDXLImageResponse(
            seed=response_data.get('seed'),
            images=[ImageData(**img) for img in response_data['images']],
            prompt=response_data['prompt'],
            inference_time=response_data.get('timings', {}).get('inference'),
            has_nsfw_concepts=response_data.get('has_nsfw_concepts', [False])
        )

        # Return the structured image response
        return image_response

    except ValueError:
        # Handle JSON parsing errors
        raise HTTPException(status_code=500, detail="Malformed response received from the image generation API")
