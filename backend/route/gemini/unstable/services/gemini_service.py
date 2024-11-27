# services/gemini_service.py
import google.generativeai as genai
from typing import Dict, List, Union
import logging
from fastapi import HTTPException
from ..configs.schemas.schemas import SchemaManager
from ..configs.json_utils import extract_json_from_response
from ..configs.schemas.schemas_convertor import dict_to_schema


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
            # Get config and log everything about it
            config = await self.schema_manager.get_config(prompt_type)
            logger.info("========== DEBUG OUTPUT ==========")
            logger.info(f"Prompt type: {prompt_type}")
            logger.info(f"Raw config from DB: {config}")
            
            if not config:
                logger.error("No config found")
                raise HTTPException(status_code=400, detail=f"Invalid prompt_type: {prompt_type}")

            # Log the response schema specifically
            logger.info(f"Response schema type: {type(config['response_schema'])}")
            logger.info(f"Raw response schema content: {config['response_schema']}")
            
            # Create and log the generation config exactly as we'll send it
            generation_config = {
                "temperature": temperature,
                "top_p": top_p,
                "top_k": top_k,
                "max_output_tokens": max_output_tokens,
                "response_schema": config["response_schema"]  # Using raw schema exactly as received
            }
            
            logger.info(f"Final generation config being sent to model: {json.dumps(generation_config, indent=2)}")
            logger.info("================================")

            model = genai.GenerativeModel(model_name=model_name, generation_config=generation_config)
            
            if batch:
                if isinstance(uploaded_files, list):
                    files = uploaded_files
                else:
                    files = [uploaded_files]
                chat_history = [{"role": "user", "parts": files + [config["prompt_text"]]}]
            else:
                file = uploaded_files[0] if isinstance(uploaded_files, list) else uploaded_files
                chat_history = [{"role": "user", "parts": [file, config["prompt_text"]]}]

            chat_session = model.start_chat(history=chat_history)
            response = chat_session.send_message("Process the audio and think deeply")
            
            logger.info(f"Raw response from model: {response.text}")
            
            result = extract_json_from_response(response.text)
            return result

        except HTTPException as he:
            logger.error(f"HTTP Exception: {he}")
            raise he
        except Exception as e:
            logger.error(f"Unexpected error in process_audio: {e}")
            logger.exception("Full traceback:")
            raise HTTPException(status_code=500, detail=str(e))