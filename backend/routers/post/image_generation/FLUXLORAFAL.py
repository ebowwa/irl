# File: backend/routers/post/image_generation/FLUXLORAFAL.py

from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field
from typing import List, Optional
import httpx
import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from the .env file

router = APIRouter(
    prefix="/FLUXLORAFAL",  # Updated prefix
    tags=["FLUXLORAFAL"],
    responses={404: {"description": "Not found"}},
)


# Configuration
FAL_API_ENDPOINT = os.getenv("FAL_API_ENDPOINT", "https://queue.fal.run/fal-ai/flux-lora")
FAL_API_KEY = os.getenv("FAL_KEY")

if not FAL_API_KEY:
    raise ValueError("FAL_KEY is not set in environment variables.")

# Headers required by FAL's API
FAL_HEADERS = {
    "Authorization": f"Key {FAL_API_KEY}",
    "Content-Type": "application/json",
}

# Pydantic Models Based on FAL's Schema

class ImageGenerationRequest(BaseModel):
    prompt: str = Field(..., description="The prompt to generate an image from.")
    image_size: str = Field(
        "landscape_4_3",
        description="The size of the generated image.",
        pattern="^(square_hd|square|portrait_4_3|portrait_16_9|landscape_4_3|landscape_16_9)$",
    )
    num_inference_steps: int = Field(28, ge=1, le=100, description="Number of inference steps.")
    guidance_scale: float = Field(3.5, ge=0.0, le=20.0, description="CFG scale for guidance.")
    num_images: int = Field(1, ge=1, le=10, description="Number of images to generate.")
    enable_safety_checker: bool = Field(True, description="Enable safety checker.")
    output_format: str = Field(
        "jpeg",
        description="Format of the generated image.",
        pattern="^(jpeg|png)$",
    )
    seed: Optional[int] = Field(None, description="Seed for reproducibility.")
    loras: Optional[List[str]] = Field(
        None,
        description="List of LoRA weights to apply.",
    )
    sync_mode: Optional[bool] = Field(False, description="Wait for generation to complete.")

class Image(BaseModel):
    url: str
    content_type: str = "image/jpeg"
    width: Optional[int] = 512
    height: Optional[int] = 512

class ImageGenerationResponse(BaseModel):
    request_id: str = Field(..., description="Unique ID for the request.")
    status: str = Field(..., description="Current status of the request.")
    images: Optional[List[Image]] = Field(None, description="Generated images.")
    prompt: Optional[str] = Field(None, description="The prompt used for generation.")
    timings: Optional[dict] = Field(None, description="Timings related to generation.")
    has_nsfw_concepts: Optional[List[bool]] = Field(None, description="NSFW content flags.")

# Helper Function to Proxy Requests to FAL
async def proxy_request(method: str, url: str, **kwargs):
    async with httpx.AsyncClient() as client:
        try:
            response = await client.request(method, url, **kwargs)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as http_err:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"FAL API Error: {response.text}",
            )
        except httpx.RequestError as req_err:
            raise HTTPException(
                status_code=502,
                detail=f"Error connecting to FAL API: {str(req_err)}",
            )
        except Exception as err:
            raise HTTPException(
                status_code=500,
                detail=f"Unexpected Error: {str(err)}",
            )

@router.post("/submit", response_model=ImageGenerationResponse)
async def submit_image_generation(request: ImageGenerationRequest):
    """
    Submit an image generation request to FAL's Queue API.
    """
    # Prepare the payload
    payload = request.dict(exclude_unset=True)
    
    # Remove any None values to avoid sending them if not necessary
    payload = {k: v for k, v in payload.items() if v is not None}
    
    # Proxy the request to FAL's API
    fal_response = await proxy_request(
        method="POST",
        url=FAL_API_ENDPOINT,
        headers=FAL_HEADERS,
        json=payload,
    )
    
    # Ensure the response contains a request_id
    if "request_id" not in fal_response:
        raise HTTPException(
            status_code=502,
            detail="Invalid response from FAL API: Missing request_id.",
        )
    
    return ImageGenerationResponse(**fal_response)

@router.get("/status/{request_id}", response_model=ImageGenerationResponse)
async def check_request_status(request_id: str):
    """
    Check the status of a submitted image generation request.
    """
    status_url = f"{FAL_API_ENDPOINT}/requests/{request_id}/status"
    
    fal_response = await proxy_request(
        method="GET",
        url=status_url,
        headers=FAL_HEADERS,
    )
    
    return ImageGenerationResponse(**fal_response)

@router.get("/result/{request_id}", response_model=ImageGenerationResponse)
async def fetch_request_result(request_id: str):
    result_url = f"{FAL_API_ENDPOINT}/requests/{request_id}"
    
    fal_response = await proxy_request(
        method="GET",
        url=result_url,
        headers=FAL_HEADERS,
    )

    # Debug the response from FAL API
    print(f"FAL Response: {fal_response}")  # You can remove this after debugging

    # Check if request is completed
    if fal_response.get("status") != "completed":
        raise HTTPException(
            status_code=400,
            detail="Request is not completed yet.",
        )
    
    # Return the response
    return ImageGenerationResponse(**fal_response)

