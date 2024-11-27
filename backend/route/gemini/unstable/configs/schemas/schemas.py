# configs/schemas.py
import logging
from typing import Optional, Dict, Any
from database.core import prompt_schema_table
from utils.db_state import database

logger = logging.getLogger(__name__)

class SchemaManager:
    async def get_config(self, prompt_type: str) -> Optional[Dict[str, Any]]:
        """Retrieve the raw schema configuration for the given prompt_type."""
        query = prompt_schema_table.select().where(prompt_schema_table.c.prompt_type == prompt_type)
        logger.info(f"Executing DB query: {query}")
        
        result = await database.fetch_one(query)
        logger.info(f"Raw DB result: {result}")
        
        if result:
            # Return raw dictionary without any parsing
            return dict(result)
            
        logger.warning(f"No config found for prompt_type: {prompt_type}")
        return None