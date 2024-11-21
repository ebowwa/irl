# backend/db/waitlist_db.py

from datetime import datetime
from pathlib import Path
import logging

import databases
import sqlalchemy
from sqlalchemy import Column, DateTime, Integer, String, Table, func
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

# Determine the base directory relative to this file's location
BASE_DIR = Path(__file__).resolve().parent.parent / "data"
DATABASE_NAME = "website_waitlist_data.db"
DATABASE_PATH = BASE_DIR / DATABASE_NAME

# Ensure the directory exists
BASE_DIR.mkdir(parents=True, exist_ok=True)
logger.info(f"Database directory ensured at: {BASE_DIR.as_posix()}")

# Database URL for SQLite using the relative DATABASE_PATH
DATABASE_URL = f"sqlite+aiosqlite:///{DATABASE_PATH.as_posix()}"

# For PostgreSQL in production, use:
# DATABASE_URL = "postgresql+asyncpg://user:password@localhost/dbname"

logger.info(f"Using DATABASE_URL: {DATABASE_URL}")

# Initialize the database
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

# Define the waitlist table with an additional 'referral_source' column
waitlist_table = Table(
    "waitlist",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("name", String, nullable=False),
    Column("email", String, unique=True, index=True, nullable=False),
    Column("ip_address", String, nullable=True),
    Column("comment", String, nullable=True),  # Existing column
    Column("referral_source", String, nullable=True),  # New column for referral source
    Column("created_at", DateTime, default=func.now(), nullable=False),
)

# Create the database engine
engine = sqlalchemy.create_engine(
    DATABASE_URL.replace("+aiosqlite", ""),
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
)

# Create the table(s)
metadata.create_all(engine)
logger.info("Database tables created or already exist.")
