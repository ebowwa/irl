# backend/db/waitlist_db.py

from pathlib import Path
import logging
import os  # For environment variables
from dotenv import load_dotenv  # To load environment variables from a .env file
import databases
import sqlalchemy
from sqlalchemy import (
    Column,
    DateTime,
    BigInteger,  # Changed from Integer to BigInteger for PostgreSQL compatibility
    String,
    Table,
    func,
)
from sqlalchemy.exc import IntegrityError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# === Load Environment Variables ===
load_dotenv()  # Loads environment variables from .env file

# === Database Configuration ===

# Use the SUPABASE_DATABASE_URL environment variable
DATABASE_URL = os.getenv("SUPABASE_DATABASE_URL")  # Supabase connection URL

if not DATABASE_URL:
    raise ValueError("No SUPABASE_DATABASE_URL found. Please set the SUPABASE_DATABASE_URL environment variable.")

logger.info(f"Using DATABASE_URL: {DATABASE_URL}")

# Initialize the database
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

# Define the waitlist table with an additional 'referral_source' column
waitlist_table = Table(
    "waitlist",
    metadata,
    Column("id", BigInteger, primary_key=True, index=True),
    Column("name", String, nullable=False),
    Column("email", String, unique=True, index=True, nullable=False),
    Column("ip_address", String, nullable=True),
    Column("comment", String, nullable=True),  # Existing column
    Column("referral_source", String, nullable=True),  # New column for referral source
    Column("created_at", DateTime(timezone=True), server_default=func.now(), nullable=False),
)

# Remove the SQLite-specific engine creation and table creation
# Instead, we'll create an engine suitable for PostgreSQL

# Create the database engine for synchronous operations (for table creation)
SYNC_DATABASE_URL = DATABASE_URL.replace("+asyncpg", "")  # Remove '+asyncpg' for the synchronous engine
engine = sqlalchemy.create_engine(
    SYNC_DATABASE_URL,
    pool_size=20,
    max_overflow=0,
)

# **Important**: Do not call metadata.create_all(engine) here to avoid conflicts with asynchronous operations.

logger.info("Waitlist table schema defined for Supabase PostgreSQL.")

async def connect_to_db():
    logger.info("Connecting to the Supabase PostgreSQL database.")
    try:
        await database.connect()
        logger.info("Supabase PostgreSQL database connected successfully.")
    except Exception as e:
        logger.error(f"Error connecting to the Supabase PostgreSQL database: {e}")
        raise

async def disconnect_from_db():
    logger.info("Disconnecting from the Supabase PostgreSQL database.")
    try:
        await database.disconnect()
        logger.info("Supabase PostgreSQL database disconnected successfully.")
    except Exception as e:
        logger.error(f"Error disconnecting from the Supabase PostgreSQL database: {e}")