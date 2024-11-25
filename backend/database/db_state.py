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
# BASE_DIR = Path(__file__).resolve().parent.parent.parent / "data"
# DATABASE_NAME = "app_user_identification_v2.db"
# DATABASE_PATH = BASE_DIR / DATABASE_NAME

# Ensure the directory exists
# BASE_DIR.mkdir(parents=True, exist_ok=True)
# logger.info(f"Database directory ensured at: {BASE_DIR.as_posix()}")

# Define the database URL for SQLite with aiosqlite
# DATABASE_URL = f"sqlite+aiosqlite:///{DATABASE_PATH.as_posix()}"

DATABASE_URL = os.getenv("SUPABASE_DATABASE_URL")  # Supabase connection URL

if not DATABASE_URL:
    raise ValueError("No SUPABASE_DATABASE_URL found. Please set the SUPABASE_DATABASE_URL environment variable.")

logger.info(f"Using SUPABASE DATABASE_URL: {DATABASE_URL}")

# Initialize the database and metadata
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()
