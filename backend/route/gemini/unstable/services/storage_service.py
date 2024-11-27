# services/storage_service.py
from typing import Any
import json
from database.user import database, processed_audio_files_table
from datetime import datetime

class StorageService:
    async def store_processed_file(
        self,
        user_id: int,
        file_name: str,
        file_uri: str,
        gemini_result: Any
    ):
        """Store processed file results in the database."""
        query = processed_audio_files_table.insert().values(
            user_id=user_id,
            file_name=file_name,
            file_uri=file_uri,
            gemini_result=json.dumps(gemini_result),
            uploaded_at=datetime.utcnow(),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        await database.execute(query)