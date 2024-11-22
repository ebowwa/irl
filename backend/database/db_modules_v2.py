# backend/database/db_modules_v2.py
# TODO: IDK how the server handles different device ids by google user id's but we need to allow multiple
"""
Device Registration Database Module
===================================

This module handles the database configuration, initialization, and table definitions
for device registrations and processed audio files.

Components:
- Database Configuration
- Database Initialization
- Device Registration Table Definition
- Processed Audio Files Table Definition
"""

from pathlib import Path
import logging

import databases
import sqlalchemy
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Table, Text, func
from fastapi import APIRouter, UploadFile, File, HTTPException, Query 

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)
router = APIRouter()

# === Database Configuration ===

# Define the base directory and database name
BASE_DIR = Path(__file__).resolve().parent.parent.parent / "data"
DATABASE_NAME = "app_user_identification_v2.db"
DATABASE_PATH = BASE_DIR / DATABASE_NAME

# Ensure the directory exists
BASE_DIR.mkdir(parents=True, exist_ok=True)
logger.info(f"Database directory ensured at: {BASE_DIR.as_posix()}")

# Define the database URL for SQLite with aiosqlite
DATABASE_URL = f"sqlite+aiosqlite:///{DATABASE_PATH.as_posix()}"

# Initialize the database
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

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
    Column("file_uri", String, nullable=True),  # New column to store the upload URL
    Column("gemini_result", Text, nullable=False),
    Column("uploaded_at", DateTime, default=func.now(), nullable=False),
    Column("created_at", DateTime, default=func.now(), nullable=False),
    Column("updated_at", DateTime, default=func.now(), onupdate=func.now(), nullable=False),
)

# Create the database engine
engine = sqlalchemy.create_engine(
    DATABASE_URL.replace("+aiosqlite", ""),
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
)

# Create the tables
metadata.create_all(engine)
logger.info("Device registration and processed audio files tables created or already exist.")

# === Event Handlers for Database Connection ===

@router.on_event("startup")
async def startup():
    """
    Event handler for application startup. Connects to the database.
    """
    logger.info("Connecting to the device identification database.")
    try:
        await database.connect()
        logger.info("Device identification database connected successfully.")
    except Exception as e:
        logger.error(f"Error connecting to the device identification database: {e}")
        raise

@router.on_event("shutdown")
async def shutdown():
    """
    Event handler for application shutdown. Disconnects from the database.
    """
    logger.info("Disconnecting from the device identification database.")
    try:
        await database.disconnect()
        logger.info("Device identification database disconnected successfully.")
    except Exception as e:
        logger.error(f"Error disconnecting from the device identification database: {e}")
