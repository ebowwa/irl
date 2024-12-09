# pip install fastapi pydantic uvicorn fal-client

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Union, Optional, Dict, Any
from enum import Enum
import uvicorn
import fal_client
import asyncio
import os
from dotenv import load_dotenv
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

app = FastAPI()

class ImageSizeEnum(str, Enum):
    square_hd = "square_hd"
    square = "square"
    portrait_4_3 = "portrait_4_3"
    portrait_16_9 = "portrait_16_9"
    landscape_4_3 = "landscape_4_3"
    landscape_16_9 = "landscape_16_9"

class OutputFormatEnum(str, Enum):
    jpeg = "jpeg"
    png = "png"

class ImageSize(BaseModel):
    width: int = 512
    height: int = 512

class LoraWeight(BaseModel):
    path: str
    scale: float = 1.0

class GeneratedImage(BaseModel):
    url: str
    width: int
    height: int
    content_type: str

class TimingInfo(BaseModel):
    inference: float

class FluxResponse(BaseModel):
    seed: int
    images: List[GeneratedImage]
    prompt: str
    timings: TimingInfo
    has_nsfw_concepts: List[bool]

class InputModel(BaseModel):
    prompt: str
    image_size: Optional[Union[ImageSizeEnum, ImageSize]] = Field(default="landscape_4_3")
    num_inference_steps: Optional[int] = Field(default=28)
    seed: Optional[int] = None
    loras: Optional[List[LoraWeight]] = Field(default=[])
    guidance_scale: Optional[float] = Field(default=3.5)
    sync_mode: Optional[bool] = Field(default=False)
    num_images: Optional[int] = Field(default=1)
    enable_safety_checker: Optional[bool] = Field(default=True)
    output_format: Optional[OutputFormatEnum] = Field(default="jpeg")
    embeddings: Optional[List] = Field(default=[])
    model_name: Optional[str] = None

# Store active requests and their progress
active_requests: Dict[str, Any] = {}
request_progress: Dict[str, int] = {}

@app.post("/generate_image")
async def generate_image(input_data: InputModel):
    arguments = {}

    # Handle prompt
    arguments["prompt"] = input_data.prompt

    # Handle image_size
    if input_data.image_size is not None:
        if isinstance(input_data.image_size, ImageSize):
            arguments["image_size"] = {
                "width": input_data.image_size.width,
                "height": input_data.image_size.height,
            }
        elif isinstance(input_data.image_size, ImageSizeEnum):
            arguments["image_size"] = input_data.image_size.value
        elif isinstance(input_data.image_size, str):
            arguments["image_size"] = input_data.image_size

    # Handle other optional fields
    if input_data.num_inference_steps is not None:
        arguments["num_inference_steps"] = input_data.num_inference_steps
    if input_data.seed is not None:
        arguments["seed"] = input_data.seed
    if input_data.loras:
        arguments["loras"] = [lora.dict() for lora in input_data.loras]
    if input_data.guidance_scale is not None:
        arguments["guidance_scale"] = input_data.guidance_scale
    if input_data.num_images is not None:
        arguments["num_images"] = input_data.num_images
    if input_data.enable_safety_checker is not None:
        arguments["enable_safety_checker"] = input_data.enable_safety_checker
    if input_data.output_format is not None:
        arguments["output_format"] = input_data.output_format.value if isinstance(input_data.output_format, OutputFormatEnum) else input_data.output_format
    if input_data.embeddings:
        arguments["embeddings"] = input_data.embeddings
    if input_data.model_name is not None:
        arguments["model_name"] = input_data.model_name

    try:
        if input_data.sync_mode:
            # Wait for the image to be generated and return the result
            result = await fal_client.subscribe(
                "fal-ai/flux-lora",
                arguments=arguments,
            )
            return FluxResponse(**result)
        else:
            # Submit the request and store the handler
            loop = asyncio.get_event_loop()
            handler = await loop.run_in_executor(
                None, 
                fal_client.submit, 
                "fal-ai/flux-lora", 
                arguments
            )
            request_id = handler.request_id
            active_requests[request_id] = handler
            request_progress[request_id] = 0
            logger.info(f"Created request with ID: {request_id}")
            return {"request_id": request_id}
    except Exception as e:
        logger.error(f"Error during image generation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/status/{request_id}")
async def get_status(request_id: str):
    try:
        logger.info(f"Checking status for request ID: {request_id}")
        
        # Get the handler from active requests
        handler = active_requests.get(request_id)
        if not handler:
            logger.warning(f"No handler found for request ID: {request_id}")
            raise HTTPException(status_code=404, detail="Request not found")

        # Get the status
        loop = asyncio.get_event_loop()
        status_result = await loop.run_in_executor(None, lambda: fal_client.status("fal-ai/flux-lora", request_id, with_logs=True))
        logger.info(f"Status for request {request_id}: {type(status_result).__name__}")

        # Update progress based on logs if available
        if hasattr(status_result, 'logs') and status_result.logs:
            for log in status_result.logs:
                if isinstance(log, dict) and 'message' in log:
                    message = log['message']
                    if '%|' in message:
                        try:
                            progress = int(message.split('%|')[0].strip())
                            # Only update progress if it's greater than the current progress
                            current_progress = request_progress.get(request_id, 0)
                            if progress > current_progress:
                                request_progress[request_id] = progress
                        except:
                            pass

        # Add timeout check
        if request_id in request_progress:
            current_progress = request_progress[request_id]
            if current_progress > 80 and current_progress < 100:
                # If progress is high but stuck, check if the result is actually ready
                try:
                    result = await loop.run_in_executor(None, lambda: fal_client.result("fal-ai/flux-lora", request_id))
                    if result:
                        # If we can get a result, consider it completed
                        if isinstance(result, dict):
                            response_data = FluxResponse(
                                seed=result.get('seed', 0),
                                images=[GeneratedImage(**img) for img in result.get('images', [])],
                                prompt=result.get('prompt', ''),
                                timings=TimingInfo(inference=result.get('timings', {}).get('inference', 0.0)),
                                has_nsfw_concepts=result.get('has_nsfw_concepts', [False])
                            )
                        else:
                            response_data = FluxResponse(**result)

                        # Clean up
                        if request_id in active_requests:
                            del active_requests[request_id]
                        if request_id in request_progress:
                            del request_progress[request_id]

                        return {
                            "status": "completed",
                            "progress": 100,
                            "result": response_data.dict()
                        }
                except Exception as e:
                    logger.warning(f"Failed to check result while progress stuck: {e}")

        # Check if completed
        if (isinstance(status_result, dict) and status_result.get('status') == 'completed') or \
           (hasattr(status_result, 'status') and status_result.status == 'completed'):
            try:
                # Get the result
                result = await loop.run_in_executor(None, lambda: fal_client.result("fal-ai/flux-lora", request_id))
                
                # Extract result data
                if isinstance(result, dict):
                    response_data = FluxResponse(
                        seed=result.get('seed', 0),
                        images=[GeneratedImage(**img) for img in result.get('images', [])],
                        prompt=result.get('prompt', ''),
                        timings=TimingInfo(inference=result.get('timings', {}).get('inference', 0.0)),
                        has_nsfw_concepts=result.get('has_nsfw_concepts', [False])
                    )
                else:
                    # Handle case where result is the output directly
                    response_data = FluxResponse(**result)

                # Clean up
                if request_id in active_requests:
                    del active_requests[request_id]
                if request_id in request_progress:
                    del request_progress[request_id]

                return {
                    "status": "completed",
                    "progress": 100,
                    "result": response_data.dict()
                }
            except Exception as e:
                logger.error(f"Error processing result: {e}")
                if request_id in active_requests:
                    del active_requests[request_id]
                if request_id in request_progress:
                    del request_progress[request_id]
                return {
                    "status": "failed",
                    "error": f"Error processing result: {str(e)}"
                }

        # Check if failed
        elif (isinstance(status_result, dict) and status_result.get('status') == 'failed') or \
             (hasattr(status_result, 'status') and status_result.status == 'failed'):
            error_msg = str(getattr(status_result, 'error', None)) or status_result.get('error', 'Unknown error')
            if request_id in active_requests:
                del active_requests[request_id]
            if request_id in request_progress:
                del request_progress[request_id]
            return {
                "status": "failed",
                "error": error_msg
            }

        # Still processing
        else:
            current_status = None
            if isinstance(status_result, dict):
                current_status = status_result.get('status', 'processing')
            elif hasattr(status_result, 'status'):
                current_status = status_result.status
            else:
                current_status = 'processing'

            return {
                "status": current_status,
                "progress": request_progress.get(request_id, 0)
            }
    except Exception as e:
        logger.error(f"Error checking status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Ensure the FAL_KEY environment variable is set
if "FAL_KEY" not in os.environ:
    raise EnvironmentError("FAL_KEY environment variable is not set.")

# Run the FastAPI app with Uvicorn
if __name__ == "__main__":
    module_name = os.path.splitext(os.path.basename(__file__))[0]
    uvicorn.run(f"{module_name}:app", host="0.0.0.0", port=8000, reload=True)
