import os
import requests
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

# Create an APIRouter instance
router = APIRouter()

# Set up the FAL API URL and retrieve the API key from environment variables
FAL_API_URL = "https://queue.fal.run/fal-ai/fast-sdxl"
FAL_KEY = os.getenv("FAL_KEY")

if not FAL_KEY:
    raise ValueError("FAL_KEY environment variable not set. Please set your API key as an environment variable.")

# Pydantic model for image generation request
class SDXLImageGenerationRequest(BaseModel):
    prompt: str
    negative_prompt: Optional[str] = ""
    image_size: Optional[str] = "square_hd"
    num_inference_steps: Optional[int] = 25
    seed: Optional[int] = None
    guidance_scale: Optional[float] = 7.5
    num_images: Optional[int] = 1
    loras: Optional[List[dict]] = []
    embeddings: Optional[List[dict]] = []
    enable_safety_checker: Optional[bool] = True
    safety_checker_version: Optional[str] = "v1"
    expand_prompt: Optional[bool] = False
    format: Optional[str] = "jpeg"

# Route to submit image generation request
@router.post("/sdxl/generate")
def submit_sdxl_image_generation_request(payload: SDXLImageGenerationRequest):
    """
    Submits a request to generate an image via the fast-sdxl API.
    """
    headers = {
        "Authorization": f"Key {FAL_KEY}",
        "Content-Type": "application/json"
    }

    response = requests.post(FAL_API_URL, json=payload.dict(), headers=headers)

    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Error submitting image generation request")

    response_data = response.json()
    request_id = response_data.get("request_id")

    if not request_id:
        raise HTTPException(status_code=500, detail="Failed to retrieve request ID")

    return {"request_id": request_id}

# Route to check the status of the request
@router.get("/sdxl/status/{request_id}")
def check_sdxl_request_status(request_id: str):
    """
    Checks the status of the submitted image generation request.
    """
    status_url = f"{FAL_API_URL}/requests/{request_id}/status"
    headers = {
        "Authorization": f"Key {FAL_KEY}"
    }

    response = requests.get(status_url, headers=headers)

    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Error fetching request status")

    return response.json()

from pydantic import BaseModel
from typing import List, Optional

class ImageData(BaseModel):
    url: str
    width: int
    height: int
    content_type: str

class SDXLImageResponse(BaseModel):
    seed: Optional[int]
    images: List[ImageData]
    prompt: str
    inference_time: Optional[float]
    has_nsfw_concepts: List[bool]

@router.get("/sdxl/result/{request_id}", response_model=SDXLImageResponse)
def fetch_sdxl_image_result(request_id: str):
    """
    Fetches the final generated image and metadata from the fast-sdxl API using the request_id.
    This version includes additional error handling, response validation, and proper logging.
    """
    result_url = f"{FAL_API_URL}/requests/{request_id}"
    headers = {
        "Authorization": f"Key {FAL_KEY}"
    }

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

        # Prepare the response model
        image_response = SDXLImageResponse(
            seed=response_data.get('seed'),
            images=[ImageData(**img) for img in response_data['images']],
            prompt=response_data['prompt'],
            inference_time=response_data.get('timings', {}).get('inference'),
            has_nsfw_concepts=response_data.get('has_nsfw_concepts', [False])
        )

        return image_response

    except ValueError:
        # If JSON parsing fails
        raise HTTPException(status_code=500, detail="Malformed response received from the image generation API")
