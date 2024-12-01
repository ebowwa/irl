# services/gemini_service.py
import asyncio
import google.generativeai as genai
from google.generativeai import types as genai_types
from typing import Dict, List, Union, Callable, Any
import logging
import json
import os
import base64
from fastapi import HTTPException
from ..configs.schemas import SchemaManager
from ..utils.json_utils import extract_json_from_response
from fastapi import UploadFile
import aiohttp

logger = logging.getLogger(__name__)

async def retry_with_exponential_backoff(
    operation: Callable[[], Any],
    initial_delay: float = 1,
    max_delay: float = 60,
    max_retries: int = 5,
    backoff_factor: float = 2,
) -> Any:
    """Retry an operation with exponential backoff."""
    delay = initial_delay
    last_exception = None
    
    for attempt in range(max_retries):
        try:
            return await operation() if asyncio.iscoroutinefunction(operation) else operation()
        except Exception as e:
            last_exception = e
            logger.warning(f"Attempt {attempt + 1} failed: {str(e)}")
            
            if attempt < max_retries - 1:
                await asyncio.sleep(delay)
                delay = min(delay * backoff_factor, max_delay)
            
    raise last_exception or Exception("Operation failed after max retries")

class GeminiService:
    def __init__(self, schema_manager: SchemaManager):
        self.schema_manager = schema_manager
        # Configure Gemini API
        genai.configure(api_key=os.getenv('GOOGLE_API_KEY'))
        logger.info("Initialized Gemini service with API key")

    async def _send_message_async(self, chat, message: str):
        """Helper method to handle async message sending"""
        return await chat.send_message_async(message)

    async def process_audio_content(
        self,
        content: bytes,
        prompt_type: str,
        model_name: str = "gemini-1.5-flash",
        temperature: float = 1.0,
        top_p: float = 0.95,
        top_k: int = 40,
        max_output_tokens: int = 8192
    ) -> Dict:
        """Process audio content using Gemini API with proper prompt handling."""
        try:
            # Get the appropriate prompt text for the given prompt type
            prompt_text = await self.schema_manager.get_prompt_text(prompt_type)
            
            # Initialize Gemini client
            model = genai.GenerativeModel(model_name)
            
            # Configure generation parameters
            generation_config = {
                "temperature": temperature,
                "top_p": top_p,
                "top_k": top_k,
                "max_output_tokens": max_output_tokens
            }
            
            # Create content with proper format for Gemini API
            content_parts = [
                {
                    "parts": [
                        {"text": prompt_text},
                        {
                            "inline_data": {
                                "mime_type": "audio/ogg",
                                "data": base64.b64encode(content).decode('utf-8')
                            }
                        }
                    ]
                }
            ]
            
            # Generate response with retry mechanism
            response = await retry_with_exponential_backoff(
                lambda: model.generate_content(
                    content_parts,
                    generation_config=generation_config
                )
            )
            
            # Process and validate response
            if not response or not response.parts:
                raise ValueError("No response generated from Gemini")
                
            result = response.parts[0].text
            
            # Try to parse as JSON if response schema exists and response looks like JSON
            config = await self.schema_manager.get_config(prompt_type)
            if config and config.get("response_schema"):
                try:
                    # Only attempt JSON parsing if the response looks like JSON
                    cleaned_text = result.strip()
                    if cleaned_text.startswith('{') or cleaned_text.startswith('['):
                        if cleaned_text.startswith("```json"):
                            cleaned_text = cleaned_text[7:]
                        if cleaned_text.endswith("```"):
                            cleaned_text = cleaned_text[:-3]
                        cleaned_text = cleaned_text.strip()
                        
                        # Attempt to parse JSON
                        result = json.loads(cleaned_text)
                except json.JSONDecodeError as e:
                    # If JSON parsing fails, just return the text response
                    logger.debug(f"Response is not JSON format, returning as text: {str(e)}")
                    pass
                    
            return {
                "status": "success",
                "result": result
            }
            
        except Exception as e:
            logger.error(f"Gemini processing failed: {str(e)}", exc_info=True)
            raise ValueError(f"Gemini processing failed: {str(e)}")

    async def process_audio(self, uploaded_files: List[Union[UploadFile, Dict]], config: Dict) -> List[Dict]:
        """Process audio files with Gemini API."""
        try:
            # Configure Gemini model
            generation_config = {
                "temperature": config.get('temperature', 1.0),
                "top_p": config.get('top_p', 0.95),
                "top_k": config.get('top_k', 40),
                "max_output_tokens": config.get('max_output_tokens', 8192),
            }
            
            model = genai.GenerativeModel(
                name=config.get('model_name', 'gemini-1.5-flash'),
                generation_config=generation_config
            )
            
            results = []
            for file in uploaded_files:
                try:
                    # Handle different file input types
                    if isinstance(file, dict):
                        # Handle file URI
                        file_uri = file.get('uri')
                        if not file_uri:
                            raise ValueError("Missing file URI")
                            
                        # Download file from URI
                        async with aiohttp.ClientSession() as session:
                            async with session.get(file_uri) as response:
                                if response.status != 200:
                                    raise ValueError(f"Failed to download file: {response.status}")
                                content = await response.read()
                                
                    else:
                        # Handle direct file upload
                        content = await file.read()
                        
                    # Get prompt text based on type
                    prompt_text = await self.schema_manager.get_prompt_text(config.get('prompt_type'))
                    
                    # Create parts list for content
                    parts = [
                        genai.types.Part.from_text(prompt_text),
                        genai.types.Part.from_data(
                            data=content,
                            mime_type="audio/ogg"
                        )
                    ]
                    
                    # Create the content object according to Gemini API requirements
                    content = parts
                    
                    logger.debug(f"Final content structure: {json.dumps(content)}")
                    
                    # Process with Gemini
                    response = await retry_with_exponential_backoff(
                        lambda: model.generate_content(content)
                    )
                    
                    if not response or not response.candidates:
                        raise ValueError("No response generated from Gemini")
                        
                    result = response.candidates[0].content.text
                    
                    # Try to parse as JSON if response schema exists
                    config = await self.schema_manager.get_config(config.get('prompt_type'))
                    if config and config.get("response_schema"):
                        try:
                            result = json.loads(result)
                        except json.JSONDecodeError:
                            logger.warning("Failed to parse Gemini response as JSON")
                            
                    results.append({
                        "status": "success",
                        "file": file.filename if hasattr(file, 'filename') else file_uri,
                        "result": result
                    })
                    
                except Exception as e:
                    logger.error(f"Error processing file: {str(e)}", exc_info=True)
                    results.append({
                        "status": "error",
                        "file": file.filename if hasattr(file, 'filename') else "unknown",
                        "error": str(e)
                    })
                    
            return results
            
        except Exception as e:
            logger.error(f"Error in batch processing: {str(e)}", exc_info=True)
            raise ValueError(f"Batch processing failed: {str(e)}")