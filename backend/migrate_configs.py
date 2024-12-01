import os
import json
import asyncio
import logging
import sqlalchemy
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict
from sqlalchemy import Table, Column, Integer, String, Text, MetaData, select
from utils.db_state import database, metadata

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Define the prompt_schema table
prompt_schema_table = Table(
    "prompt_schema",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("prompt_type", String, nullable=False, unique=True),
    Column("prompt_text", Text, nullable=False),
    Column("response_schema", Text, nullable=False),
    Column("created_at", Integer, nullable=False),
    Column("updated_at", Integer, nullable=False)
)

class PromptSchemaManager:
    """Manager class for CRUD operations on prompt schemas."""
    
    @staticmethod
    async def create_prompt_schema(
        prompt_type: str,
        prompt_text: str,
        response_schema: Dict
    ) -> Dict:
        """Create a new prompt schema."""
        try:
            current_timestamp = int(datetime.utcnow().timestamp())
            
            # Check if prompt_type already exists
            existing = await PromptSchemaManager.get_prompt_schema_by_type(prompt_type)
            if existing:
                raise ValueError(f"Prompt type '{prompt_type}' already exists")
            
            query = prompt_schema_table.insert().values(
                prompt_type=prompt_type,
                prompt_text=prompt_text,
                response_schema=json.dumps(response_schema),
                created_at=current_timestamp,
                updated_at=current_timestamp
            )
            
            id = await database.execute(query)
            return {
                "id": id,
                "prompt_type": prompt_type,
                "prompt_text": prompt_text,
                "response_schema": response_schema,
                "created_at": current_timestamp,
                "updated_at": current_timestamp
            }
        except Exception as e:
            logger.error(f"Error creating prompt schema: {e}")
            raise

    @staticmethod
    async def get_all_prompt_schemas() -> List[Dict]:
        """Retrieve all prompt schemas."""
        try:
            query = select([prompt_schema_table])
            results = await database.fetch_all(query)
            
            return [{
                "id": row["id"],
                "prompt_type": row["prompt_type"],
                "prompt_text": row["prompt_text"],
                "response_schema": json.loads(row["response_schema"]),
                "created_at": row["created_at"],
                "updated_at": row["updated_at"]
            } for row in results]
        except Exception as e:
            logger.error(f"Error retrieving prompt schemas: {e}")
            raise

    @staticmethod
    async def get_prompt_schema_by_type(prompt_type: str) -> Optional[Dict]:
        """Retrieve a prompt schema by its type."""
        try:
            query = prompt_schema_table.select().where(
                prompt_schema_table.c.prompt_type == prompt_type
            )
            result = await database.fetch_one(query)
            
            if result:
                return {
                    "id": result["id"],
                    "prompt_type": result["prompt_type"],
                    "prompt_text": result["prompt_text"],
                    "response_schema": json.loads(result["response_schema"]),
                    "created_at": result["created_at"],
                    "updated_at": result["updated_at"]
                }
            return None
        except Exception as e:
            logger.error(f"Error retrieving prompt schema: {e}")
            raise

    @staticmethod
    async def update_prompt_schema(
        prompt_type: str,
        prompt_text: Optional[str] = None,
        response_schema: Optional[Dict] = None
    ) -> Optional[Dict]:
        """Update an existing prompt schema."""
        try:
            existing = await PromptSchemaManager.get_prompt_schema_by_type(prompt_type)
            if not existing:
                raise ValueError(f"Prompt type '{prompt_type}' not found")
            
            update_values = {
                "updated_at": int(datetime.utcnow().timestamp())
            }
            
            if prompt_text is not None:
                update_values["prompt_text"] = prompt_text
            if response_schema is not None:
                update_values["response_schema"] = json.dumps(response_schema)
            
            query = prompt_schema_table.update().where(
                prompt_schema_table.c.prompt_type == prompt_type
            ).values(**update_values)
            
            await database.execute(query)
            return await PromptSchemaManager.get_prompt_schema_by_type(prompt_type)
        except Exception as e:
            logger.error(f"Error updating prompt schema: {e}")
            raise

    @staticmethod
    async def delete_prompt_schema(prompt_type: str) -> bool:
        """Delete a prompt schema."""
        try:
            query = prompt_schema_table.delete().where(
                prompt_schema_table.c.prompt_type == prompt_type
            )
            result = await database.execute(query)
            return result > 0
        except Exception as e:
            logger.error(f"Error deleting prompt schema: {e}")
            raise

async def migrate_configs():
    """Migrate JSON config files to database using the CRUD manager."""
    try:
        # Use the stable configs directory
        directory = Path(__file__).parent / 'route' / 'gemini' / 'stable' / 'configs'
        
        if not directory.exists():
            raise FileNotFoundError(f"Config directory not found: {directory}")
        
        logger.info(f"Found config directory at: {directory}")

        if not database.is_connected:
            await database.connect()
            logger.info("Connected to database")

        # Create tables using async connection
        query = """
        CREATE TABLE IF NOT EXISTS prompt_schema (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prompt_type TEXT NOT NULL UNIQUE,
            prompt_text TEXT NOT NULL,
            response_schema TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        )
        """
        await database.execute(query)
        logger.info("Created database tables")

        errors = []

        for file_path in directory.glob('*.json'):
            try:
                prompt_type = file_path.stem
                logger.info(f"Processing {prompt_type}...")
                
                with open(file_path, 'r') as file:
                    data = json.load(file)
                    prompt_text = data.get('prompt_text', '')
                    response_schema = data.get('response_schema', {})

                existing = await PromptSchemaManager.get_prompt_schema_by_type(prompt_type)
                
                if existing:
                    await PromptSchemaManager.update_prompt_schema(
                        prompt_type=prompt_type,
                        prompt_text=prompt_text,
                        response_schema=response_schema
                    )
                    logger.info(f"Updated schema for {prompt_type}")
                else:
                    await PromptSchemaManager.create_prompt_schema(
                        prompt_type=prompt_type,
                        prompt_text=prompt_text,
                        response_schema=response_schema
                    )
                    logger.info(f"Inserted new schema for {prompt_type}")

            except Exception as e:
                error_msg = f"Error processing {file_path.name}: {str(e)}"
                logger.error(error_msg)
                errors.append((file_path.name, str(e)))

        if errors:
            logger.error("Errors occurred while processing the following files:")
            for file_name, error in errors:
                logger.error(f"File: {file_name} - Error: {error}")
        else:
            logger.info("All JSON files successfully migrated to database")

    except Exception as e:
        logger.error(f"Migration failed: {e}")
        raise
    finally:
        if database.is_connected:
            await database.disconnect()
            logger.info("Disconnected from database")

# Example usage
async def main():
    await database.connect()
    try:
        # Create a new prompt schema
        new_schema = await PromptSchemaManager.create_prompt_schema(
            prompt_type="test_prompt",
            prompt_text="This is a test prompt",
            response_schema={"type": "object", "properties": {}}
        )
        print("Created:", new_schema)
        
        # Get all schemas
        all_schemas = await PromptSchemaManager.get_all_prompt_schemas()
        print("All schemas:", all_schemas)
        
        # Update a schema
        updated = await PromptSchemaManager.update_prompt_schema(
            prompt_type="test_prompt",
            prompt_text="Updated test prompt"
        )
        print("Updated:", updated)
        
        # Delete a schema
        deleted = await PromptSchemaManager.delete_prompt_schema("test_prompt")
        print("Deleted:", deleted)
        
    finally:
        await database.disconnect()

if __name__ == "__main__":
    print("Starting migration...")
    asyncio.run(migrate_configs())
    # Or run the example usage:
    # asyncio.run(main())