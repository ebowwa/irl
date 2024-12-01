# configs/schemas.py
import os
from typing import Dict
import json
import logging
from pathlib import Path
import datetime

logger = logging.getLogger(__name__)

class SchemaManager:
    DEFAULT_PROMPT_TYPE = "transcription_v1"
    DEFAULT_PROMPT_TEXT = "Please analyze this audio and provide a detailed summary including: key topics discussed, speaker emotions, main points, and any notable insights or conclusions."
    
    def __init__(self):
        from database.core import database, prompt_schema_table
        self.database = database
        self.prompt_schema_table = prompt_schema_table
        
    async def get_config(self, prompt_type: str) -> Dict:
        """Get prompt configuration, returning None if not found (except for default)."""
        if prompt_type == self.DEFAULT_PROMPT_TYPE:
            return {
                "prompt_text": self.DEFAULT_PROMPT_TEXT,
                "response_schema": {
                    "type": "object",
                    "properties": {
                        "summary": {"type": "string"},
                        "topics": {"type": "array", "items": {"type": "string"}},
                        "emotions": {"type": "object"},
                        "key_points": {"type": "array", "items": {"type": "string"}},
                        "insights": {"type": "array", "items": {"type": "string"}}
                    }
                }
            }
            
        query = self.prompt_schema_table.select().where(
            self.prompt_schema_table.c.prompt_type == prompt_type
        )
        result = await self.database.fetch_one(query)
        if result:
            return {
                "prompt_text": result["prompt_text"],
                "response_schema": json.loads(result["response_schema"])
            }
        return None

    async def get_prompt_text(self, prompt_type: str) -> str:
        """Get prompt text, raising 400 error if prompt type is invalid."""
        if prompt_type == self.DEFAULT_PROMPT_TYPE:
            return self.DEFAULT_PROMPT_TEXT
            
        config = await self.get_config(prompt_type)
        if not config:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=400,
                detail=f"Invalid prompt type: {prompt_type}"
            )
        return config["prompt_text"]

    async def create_config(self, prompt_type: str, prompt_text: str, response_schema: Dict) -> Dict:
        """Create new prompt configuration."""
        if prompt_type == self.DEFAULT_PROMPT_TYPE:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=400,
                detail=f"Cannot modify default prompt type: {self.DEFAULT_PROMPT_TYPE}"
            )
            
        try:
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
        except Exception as e:
            logger.error(f"Error creating config: {e}", exc_info=True)
            from fastapi import HTTPException
            raise HTTPException(
                status_code=500,
                detail="Failed to create prompt schema"
            )

    async def update_config(self, prompt_type: str, prompt_text: str = None, response_schema: Dict = None) -> Dict:
        """Update existing prompt configuration."""
        if prompt_type == self.DEFAULT_PROMPT_TYPE:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=400,
                detail=f"Cannot modify default prompt type: {self.DEFAULT_PROMPT_TYPE}"
            )
            
        try:
            current_timestamp = int(datetime.datetime.utcnow().timestamp())
            values = {"updated_at": current_timestamp}
            
            if prompt_text:
                values["prompt_text"] = prompt_text
            if response_schema:
                values["response_schema"] = json.dumps(response_schema)
                
            query = self.prompt_schema_table.update().where(
                self.prompt_schema_table.c.prompt_type == prompt_type
            ).values(**values)
            
            result = await self.database.execute(query)
            if not result:
                from fastapi import HTTPException
                raise HTTPException(
                    status_code=404,
                    detail=f"Prompt schema not found: {prompt_type}"
                )
            return await self.get_config(prompt_type)
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error updating config: {e}", exc_info=True)
            from fastapi import HTTPException
            raise HTTPException(
                status_code=500,
                detail="Failed to update prompt schema"
            )

    async def delete_config(self, prompt_type: str) -> bool:
        """Delete prompt configuration."""
        if prompt_type == self.DEFAULT_PROMPT_TYPE:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=400,
                detail=f"Cannot delete default prompt type: {self.DEFAULT_PROMPT_TYPE}"
            )
            
        try:
            query = self.prompt_schema_table.delete().where(
                self.prompt_schema_table.c.prompt_type == prompt_type
            )
            result = await self.database.execute(query)
            return result is not None
        except Exception as e:
            logger.error(f"Error deleting config: {e}", exc_info=True)
            return False
