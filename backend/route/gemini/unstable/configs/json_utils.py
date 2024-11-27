# utils/json_utils.py
import json
import re
import logging
from typing import Dict
from fastapi import HTTPException

logger = logging.getLogger(__name__)

def extract_json_from_response(response_text: str) -> Dict:
    logger.debug(f"Attempting to extract JSON from response: {response_text}")
    
    if not response_text:
        logger.error("Empty response text received")
        raise HTTPException(status_code=500, detail="Empty response received")
        
    json_pattern = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL)
    match = json_pattern.search(response_text)
    
    try:
        if match:
            json_str = match.group(1)
            logger.debug(f"Found JSON in code block: {json_str}")
            return json.loads(json_str)

        logger.debug("No JSON code block found, attempting to parse entire response")
        return json.loads(response_text)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse as JSON: {str(e)}")
        logger.error(f"Problem text: {response_text}")
        raise HTTPException(status_code=500, detail=f"Failed to decode JSON: {e}")