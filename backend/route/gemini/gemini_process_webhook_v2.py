# backend/route/features/gemini_process_webhook_v2.py
# Updated to support unified batch processing with a single consolidated result
import logging
import re
import json
import os
from fastapi import HTTPException
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content
from typing import Dict, List, Union


# Configure logging
logger = logging.getLogger(__name__)

# Path to the configs directory
CONFIGS_DIR = os.path.join(os.path.dirname(__file__), 'configs')

def load_configurations(configs_dir: str = CONFIGS_DIR) -> Dict[str, Dict]:
    """
    Loads all JSON configuration files from the specified directory.

    Args:
        configs_dir (str): Path to the directory containing JSON config files.

    Returns:
        Dict[str, Dict]: A dictionary mapping prompt_type to its configuration.
    """
    configurations = {}
    for filename in os.listdir(configs_dir):
        if filename.endswith('.json'):
            filepath = os.path.join(configs_dir, filename)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    # Use the filename (without extension) as the key
                    prompt_type = os.path.splitext(filename)[0]
                    # Convert response_schema dict to content.Schema object
                    response_schema = dict_to_schema(config.get('response_schema', {}))
                    configurations[prompt_type] = {
                        "prompt_text": config.get("prompt_text", ""),
                        "response_schema": response_schema
                    }
                logger.info(f"Loaded configuration '{prompt_type}' from '{filename}'.")
            except Exception as e:
                logger.error(f"Failed to load configuration '{filename}': {e}")
    return configurations

def dict_to_schema(schema_dict: Dict) -> content.Schema:
    """
    Recursively converts a dictionary to a content.Schema object.

    Args:
        schema_dict (Dict): The schema as a dictionary.

    Returns:
        content.Schema: The corresponding Schema object.
    """
    schema_type = getattr(content.Type, schema_dict.get('type', 'OBJECT'))
    required = schema_dict.get('required', [])
    properties = schema_dict.get('properties', {})

    # Recursively convert properties
    converted_properties = {}
    for prop_name, prop_details in properties.items():
        prop_type = prop_details.get('type', 'STRING')
        if prop_type == 'OBJECT':
            converted_properties[prop_name] = dict_to_schema(prop_details)
        elif prop_type == 'ARRAY':
            items = prop_details.get('items', {})
            item_type = items.get('type', 'STRING')
            if item_type == 'OBJECT':
                item_schema = dict_to_schema(items)
            else:
                item_schema = content.Schema(type=getattr(content.Type, item_type))
            converted_properties[prop_name] = content.Schema(
                type=content.Type.ARRAY,
                items=item_schema,
                description=prop_details.get('description', '')
            )
        else:
            converted_properties[prop_name] = content.Schema(
                type=getattr(content.Type, prop_type),
                description=prop_details.get('description', '')
            )

    return content.Schema(
        type=schema_type,
        required=required,
        properties=converted_properties
    )

# Load all configurations at module import
PROMPTS_SCHEMAS = load_configurations()

def process_with_gemini_webhook(
    uploaded_files: Union[List[object], object],
    prompt_type: str = "default",
    batch: bool = False
) -> Dict:
    """
    Internal webhook to process audio file(s) using Gemini's generative capabilities.

    Args:
        uploaded_files: The uploaded file object(s) from Gemini.
        prompt_type (str): The key to select the prompt and schema configuration.
        batch (bool): Flag indicating whether to process as a batch.

    Returns:
        dict: Parsed JSON response from Gemini.
    """
    try:
        config = PROMPTS_SCHEMAS.get(prompt_type)
        if not config:
            logger.error(f"Invalid prompt_type selected: {prompt_type}")
            raise HTTPException(status_code=400, detail=f"Invalid prompt_type: {prompt_type}")

        prompt_text = config["prompt_text"]
        response_schema = config["response_schema"]

        # Prepare the prompt and model configuration
        generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 8192,
            "response_schema": response_schema,
            "response_mime_type": "application/json",
        }

        model = genai.GenerativeModel(model_name="gemini-1.5-flash", generation_config=generation_config)
        logger.info(f"Initialized Gemini GenerativeModel with prompt_type '{prompt_type}' and batch={batch}")

        if batch:
            # Create chat history with all uploaded files and prompt for batch processing
            chat_history = [{"role": "user", "parts": uploaded_files + [prompt_text]}]
            logger.debug(f"Batch prompt constructed with files and prompt.")

        else:
            # Process a single file
            chat_history = [{"role": "user", "parts": [uploaded_files, prompt_text]}]
            logger.debug(f"Individual prompt constructed for file '{uploaded_files.display_name}': {prompt_text}")

        chat_session = model.start_chat(history=chat_history)
        logger.info("Chat session started with Gemini.")

        # Send a message to the model
        response = chat_session.send_message("Process the audio and think deeply")
        logger.debug(f"Received response from Gemini: {response.text}")

        # Extract JSON from the response
        parsed_result = extract_json_from_response(response.text)
        logger.info("Successfully extracted JSON from Gemini response.")

        return parsed_result

    except HTTPException as he:
        logger.error(f"HTTPException in process_with_gemini_webhook: {he.detail}")
        raise he  # Re-raise HTTP exceptions
    except Exception as e:
        logger.error(f"Unexpected error in process_with_gemini_webhook: {e}")
        raise HTTPException(status_code=500, detail="Gemini processing failed")


def extract_json_from_response(response_text: str) -> Dict:
    """
    Extracts JSON content from Gemini response text.

    Args:
        response_text (str): The text response from Gemini.

    Returns:
        dict: Parsed JSON object.
    """
    json_pattern = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL)
    match = json_pattern.search(response_text)
    if match:
        json_str = match.group(1)
        try:
            return json.loads(json_str)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decoding error: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to decode JSON: {e}")
    else:
        try:
            return json.loads(response_text)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decoding error: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to decode JSON: {e}")