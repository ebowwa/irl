# I/O Notes for Route: `backend/routers/post/image_generation/sdxl.py`

### Route: `/sdxl/generate` (POST)
- **Input**:  
  - **Model**: `SDXLImageGenerationRequest`
    - `prompt` (str): The main prompt used for image generation.
    - `negative_prompt` (Optional[str], default=""): A prompt to avoid certain elements in the generated image.
    - `image_size` (Optional[str], default="square_hd"): The size of the generated image.
    - `num_inference_steps` (Optional[int], default=25): Number of inference steps.
    - `seed` (Optional[int], default=None): Seed value for reproducibility.
    - `guidance_scale` (Optional[float], default=7.5): Strength of the prompt guidance.
    - `num_images` (Optional[int], default=1): Number of images to generate.
    - `loras` (Optional[List[dict]], default=[]): Additional LoRA settings for model tweaking.
    - `embeddings` (Optional[List[dict]], default=[]): Custom embeddings for the model.
    - `enable_safety_checker` (Optional[bool], default=True): Whether to run the safety checker for NSFW detection.
    - `safety_checker_version` (Optional[str], default="v1"): Version of the safety checker.
    - `expand_prompt` (Optional[bool], default=False): Expands the prompt with additional context.
    - `format` (Optional[str], default="jpeg"): The output format (JPEG by default).
  
- **Output**:  
  - **Model**: 
    - `request_id` (str): An ID to track the status of the image generation request.

- **Errors**:  
  - 500: If `FAL_KEY` is missing from the environment variables.
  - 500: If `request_id` is missing from the API response.
  - Custom HTTP errors based on the `response.status_code` from the FAL API.


### Route: `/sdxl/status/{request_id}` (GET)
- **Input**:  
  - **Parameters**:
    - `request_id` (str): ID of the image generation request to track its status.
  
- **Output**:  
  - **Model**: 
    - JSON object containing the status of the image generation job (e.g., "in-progress", "completed", "failed").

- **Errors**:  
  - 500: If the API response is malformed (e.g., no valid JSON or missing expected fields).
  - Custom HTTP errors based on the `response.status_code` from the FAL API.


### Route: `/sdxl/result/{request_id}` (GET)
- **Input**:  
  - **Parameters**:
    - `request_id` (str): ID of the image generation request to retrieve the final image and its metadata.
  
- **Output**:  
  - **Model**: `SDXLImageResponse`
    - `seed` (Optional[int]): Seed used for the image generation.
    - `images` (List[ImageData]): List of image data with metadata.
      - `url` (str): URL of the generated image.
      - `width` (int): Width of the image.
      - `height` (int): Height of the image.
      - `content_type` (str): MIME type (e.g., "image/jpeg").
    - `prompt` (str): The prompt used for image generation.
    - `inference_time` (Optional[float]): Time taken for the inference process.
    - `has_nsfw_concepts` (List[bool]): Whether NSFW content was detected.

- **Errors**:  
  - 500: If no images or prompt are found in the API response.
  - 500: If the API response is malformed (e.g., no valid JSON).
  - Custom HTTP errors based on the `response.status_code` from the FAL API.
