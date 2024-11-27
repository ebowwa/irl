# utils/json_utils.py
import json
import re
import logging
from typing import Dict
from fastapi import HTTPException

logger = logging.getLogger(__name__)

def extract_json_from_response(response_text: str) -> Dict:
    json_pattern = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL)
    match = json_pattern.search(response_text)
    
    try:
        if match:
            return json.loads(match.group(1))
        return json.loads(response_text)
    except json.JSONDecodeError as e:
        logger.error(f"JSON decoding error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to decode JSON: {e}")
