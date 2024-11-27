# /home/pi/caringmind/backend/database/core.py
import json
from sqlalchemy import Table, Column, Integer, String, Text
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Table, Text, func
from utils.db_state import database, metadata

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

# === Define the Device Registration Table ===

device_registration_table = Table(
    "device_registration",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("google_account_id", String, index=True, nullable=False, unique=True),
    Column("device_uuid", String, index=True, nullable=False, unique=True),
    Column("id_token", String, nullable=False),
    Column("access_token", String, nullable=False),
    Column("created_at", DateTime, default=func.now(), nullable=False),
    Column("updated_at", DateTime, default=func.now(), onupdate=func.now(), nullable=False),
)

# === Define the Processed Audio Files Table ===

processed_audio_files_table = Table(
    "processed_audio_files",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("user_id", Integer, ForeignKey("device_registration.id"), nullable=False),
    Column("file_name", String, nullable=False),
    Column("file_uri", String, nullable=True),
    Column("gemini_result", Text, nullable=False),
    Column("uploaded_at", DateTime, default=func.now(), nullable=False),
    Column("created_at", DateTime, default=func.now(), nullable=False),
    Column("updated_at", DateTime, default=func.now(), onupdate=func.now(), nullable=False),
)