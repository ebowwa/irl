# configs/schemas.py
import os
from typing import Dict
import json
import logging
from pathlib import Path
import datetime

logger = logging.getLogger(__name__)

class SchemaManager:
    def __init__(self):
        from database.core import database, prompt_schema_table
        self.database = database
        self.prompt_schema_table = prompt_schema_table
        
    async def get_config(self, prompt_type: str) -> Dict:
        query = self.prompt_schema_table.select().where(
            self.prompt_schema_table.c.prompt_type == prompt_type
        )
        result = await self.database.fetch_one(query)
        if result:
            return {
                "prompt_text": result["prompt_text"],
                "response_schema": json.loads(result["response_schema"])
            }
        logger.warning(f"Configuration not found for prompt_type: {prompt_type}")
        return None

    async def create_config(self, prompt_type: str, prompt_text: str, response_schema: Dict) -> Dict:
        current_timestamp = int(datetime.datetime.utcnow().timestamp())
        query = self.prompt_schema_table.insert().values(
            prompt_type=prompt_type,
            prompt_text=prompt_text,
            response_schema=json.dumps(response_schema),
            created_at=current_timestamp,
            updated_at=current_timestamp
        )
        await self.database.execute(query)
        return await self.get_config(prompt_type)

    async def update_config(self, prompt_type: str, prompt_text: str = None, response_schema: Dict = None) -> Dict:
        current_timestamp = int(datetime.datetime.utcnow().timestamp())
        values = {"updated_at": current_timestamp}
        if prompt_text:
            values["prompt_text"] = prompt_text
        if response_schema:
            values["response_schema"] = json.dumps(response_schema)
            
        query = self.prompt_schema_table.update().where(
            self.prompt_schema_table.c.prompt_type == prompt_type
        ).values(**values)
        await self.database.execute(query)
        return await self.get_config(prompt_type)

    async def delete_config(self, prompt_type: str) -> bool:
        # First check if the config exists
        existing = await self.get_config(prompt_type)
        if not existing:
            return False
            
        query = self.prompt_schema_table.delete().where(
            self.prompt_schema_table.c.prompt_type == prompt_type
        )
        try:
            await self.database.execute(query)
            return True
        except Exception as e:
            logger.error(f"Failed to delete prompt schema: {e}")
            return False
