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

DATABASE_URL = os.getenv("SUPABASE_DATABASE_URL")  # Supabase connection URL

if not DATABASE_URL:
    raise ValueError("No SUPABASE_DATABASE_URL found. Please set the SUPABASE_DATABASE_URL environment variable.")

logger.info(f"Using SUPABASE DATABASE_URL: {DATABASE_URL}")

# Initialize the database and metadata
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()
