# /home/pi/caringmind/backend/configs/schemas.py

import json
from typing import Optional, Dict, Any
from database.core import prompt_schema_table
from utils.db_state import database

class SchemaManager:
    """Manager class for handling prompt schemas."""

    async def get_config(self, prompt_type: str) -> Optional[Dict[str, Any]]:
        """Retrieve the schema configuration for the given prompt_type."""
        query = prompt_schema_table.select().where(prompt_schema_table.c.prompt_type == prompt_type)
        result = await database.fetch_one(query)  # Ensure await is used here
        if result:
            config = dict(result)
            try:
                config["response_schema"] = json.loads(config["response_schema"])
            except json.JSONDecodeError:
                config["response_schema"] = {}
            return config
        return None
