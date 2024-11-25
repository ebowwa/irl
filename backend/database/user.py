# backend/database/db_modules_v2.py

import logging
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Table, Text, func

# Import shared database configuration
from database.db_state import database, metadata

# Configure logging
logger = logging.getLogger(__name__)

logger.info("Configuring database tables for Supabase.")

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
# TODO: maybe one table of these by each user/for each user since the privacy concerns of these contents
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

# Log table configuration success
logger.info("Device Registration and Processed Audio Files tables configured.")
