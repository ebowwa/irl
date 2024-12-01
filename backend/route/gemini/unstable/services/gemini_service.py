# services/gemini_service.py
import google.generativeai as genai
from typing import Dict, List, Union
import logging
from fastapi import HTTPException
from ..configs.schemas import SchemaManager
from ..utils.json_utils import extract_json_from_response

logger = logging.getLogger(__name__)

class GeminiService:
    def __init__(self, schema_manager: SchemaManager):
        self.schema_manager = schema_manager

    async def process_audio(
        self,
        uploaded_files: Union[List[object], object],
        prompt_type: str = "default",
        batch: bool = False,
        model_name: str = "gemini-1.5-flash",
        temperature: float = 1.0,
        top_p: float = 0.95,
        top_k: int = 40,
        max_output_tokens: int = 8192
    ) -> Dict:
        try:
            config = await self.schema_manager.get_config(prompt_type)
            if not config:
                raise HTTPException(status_code=400, detail=f"Invalid prompt_type: {prompt_type}")

            generation_config = {
                "temperature": temperature,
                "top_p": top_p,
                "top_k": top_k,
                "max_output_tokens": max_output_tokens,
            }

            # Only add response schema if it exists in config
            if "response_schema" in config:
                generation_config["response_schema"] = config["response_schema"]

            model = genai.GenerativeModel(model_name=model_name, generation_config=generation_config)
            
            # Ensure files are in the correct format
            if not isinstance(uploaded_files, (list, object)):
                raise HTTPException(
                    status_code=400,
                    detail="Invalid file format provided"
                )

            # Prepare the chat history with proper formatting
            if batch:
                files = [uploaded_files] if not isinstance(uploaded_files, list) else uploaded_files
                # Ensure each file is properly formatted for the API
                parts = []
                for file in files:
                    if hasattr(file, 'uri'):
                        parts.append({"file_uri": file.uri})
                    else:
                        parts.append(file)
                
                if "prompt_text" in config:
                    parts.append(config["prompt_text"])
                
                chat_history = [{"role": "user", "parts": parts}]
            else:
                # For single file processing
                file = uploaded_files[0] if isinstance(uploaded_files, list) else uploaded_files
                parts = []
                
                if hasattr(file, 'uri'):
                    parts.append({"file_uri": file.uri})
                else:
                    parts.append(file)
                
                if "prompt_text" in config:
                    parts.append(config["prompt_text"])
                
                chat_history = [{"role": "user", "parts": parts}]

            logger.debug(f"Processing with chat history: {chat_history}")
            
            # Use async context manager for chat session
            chat = model.start_chat(history=chat_history)
            response = await self._send_message_async(chat, "Process the audio")
            
            # Extract and validate JSON response
            try:
                result = extract_json_from_response(response.text)
                return result
            except ValueError as e:
                logger.error(f"Failed to parse Gemini response: {e}")
                raise HTTPException(
                    status_code=500,
                    detail="Failed to parse Gemini response"
                )

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Unexpected error in process_audio: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Gemini processing failed: {str(e)}")

    async def _send_message_async(self, chat, message: str):
        """Helper method to handle async message sending"""
        try:
            # Use asyncio.to_thread if the operation is blocking
            import asyncio
            response = await asyncio.to_thread(chat.send_message, message)
            return response
        except Exception as e:
            logger.error(f"Error sending message: {e}")
            raise