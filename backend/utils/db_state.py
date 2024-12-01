# backend/database/db_state.py

from pathlib import Path
import logging
import os
from dotenv import load_dotenv
import databases
import sqlalchemy

# Configure logging
logger = logging.getLogger(__name__)

# === Load Environment Variables ===
load_dotenv()

# === Database Configuration ===
# Define the base directory and database name
BASE_DIR = Path(__file__).resolve().parent.parent / "data"
DATABASE_NAME = "development.db"
DATABASE_PATH = BASE_DIR / DATABASE_NAME

# Ensure the directory exists
BASE_DIR.mkdir(parents=True, exist_ok=True)
logger.info(f"Database directory ensured at: {BASE_DIR.as_posix()}")

# Get environment
ENV = os.getenv("ENVIRONMENT", "development")

# Database configuration based on environment
if ENV == "production":
    # Production: Use Supabase PostgreSQL
    DATABASE_URL = os.getenv("SUPABASE_DATABASE_URL")
    if not DATABASE_URL:
        raise ValueError("No SUPABASE_DATABASE_URL found in production environment.")
    logger.info("Using production Supabase PostgreSQL database")
else:
    # Development: Use local SQLite database
    DATABASE_URL = f"sqlite+aiosqlite:///{DATABASE_PATH.as_posix()}"
    logger.info(f"Using development SQLite database at: {DATABASE_PATH}")

# Initialize database connection
database = databases.Database(DATABASE_URL)

# Import and use schema
from .db_schema import metadata

# Create tables in development (SQLite only)
if ENV == "development":
    # Use a sync SQLite URL for table creation
    sync_url = DATABASE_URL.replace("+aiosqlite", "")
    engine = sqlalchemy.create_engine(sync_url)
    metadata.create_all(engine)
    logger.info("Created development database tables")
