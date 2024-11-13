# backend/route/website_services/waitlist_router.py 

# may want to include referral source on the waitlist 

# will add telegram next to update me on waitlist status

from datetime import datetime
from typing import List, Optional
import os
from pathlib import Path
import logging

import databases
import sqlalchemy
from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import Column, DateTime, Integer, String, Table, func
from sqlalchemy.exc import IntegrityError  # Import IntegrityError
# 1. Import the TelegramNotifier class from the notification module
from utils.extensions_telegram.notification import TelegramNotifier  # Adjust the import path as necessary

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# === Updated Section: Use Relative Paths ===

# Determine the base directory relative to this file's location
BASE_DIR = Path(__file__).resolve().parent.parent.parent / "data"
# Explanation:
# - __file__ refers to the current file (waitlist_router.py)
# - resolve() gets the absolute path
# - parent.parent.parent navigates up three directories:
#   backend/route/website_services/waitlist_router.py -> backend/route/website_services -> backend/route -> backend -> project root
# - / "data" appends the "data" directory to the project root

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

# Initialize the router
router = APIRouter(prefix="/waitlist", tags=["Waitlist CRUD"])

# Pydantic Models
class WaitlistEntry(BaseModel):
    id: int
    name: str
    email: EmailStr
    ip_address: Optional[str]
    comment: Optional[str]
    referral_source: Optional[str]  # New field
    created_at: datetime

    class Config:
        orm_mode = True


class WaitlistCreate(BaseModel):
    name: str
    email: EmailStr
    comment: Optional[str] = None
    referral_source: Optional[str] = None  # New field


class WaitlistUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    comment: Optional[str] = None
    referral_source: Optional[str] = None  # New field


# 2. Initialize a global variable for the TelegramNotifier
notifier: Optional[TelegramNotifier] = None

# CRUD Endpoints

@router.post(
    "/",
    response_model=WaitlistEntry,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new waitlist entry",
)
async def create_entry(entry: WaitlistCreate, request: Request):
    """
    Create a new waitlist entry with the provided name, email, comment, and optional referral_source.
    The client's IP address is recorded from the request headers.
    """
    logger.info(f"Creating entry: {entry.dict()}")

    # Extract client IP
    ip_address = request.headers.get("X-Forwarded-For")
    if ip_address:
        ip_address = ip_address.split(",")[0].strip()
    else:
        ip_address = request.client.host
    logger.info(f"Client IP address: {ip_address}")

    # Insert the new entry, including the comment and referral_source
    query = waitlist_table.insert().values(
        name=entry.name,
        email=entry.email,
        ip_address=ip_address,
        comment=entry.comment,
        referral_source=entry.referral_source,  # Include referral_source
    )
    try:
        last_record_id = await database.execute(query)
        logger.info(f"Inserted entry with ID: {last_record_id}")
    except IntegrityError:
        logger.error(f"IntegrityError: Email {entry.email} already exists.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An entry with this email already exists.",
        )
    except Exception as e:
        logger.error(f"Unexpected error during insertion: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred.",
        )

    # Retrieve the created entry
    query = waitlist_table.select().where(waitlist_table.c.id == last_record_id)
    new_entry = await database.fetch_one(query)
    logger.info(f"New entry retrieved: {new_entry}")

    # 3. Send a Telegram notification for the new entry
    if notifier:
        try:
            await notifier.send_new_waitlist_entry(
                name=new_entry['name'],
                email=new_entry['email'],
                comment=new_entry['comment'],
                referral_source=new_entry['referral_source'],  # Include referral_source
            )
            logger.info(f"Telegram notification sent for entry ID: {last_record_id}")
        except Exception as e:
            logger.error(f"Failed to send Telegram notification: {e}")
            # Optionally, you can choose to raise an exception or continue

    return new_entry


@router.get(
    "/{entry_id}",
    response_model=WaitlistEntry,
    summary="Retrieve a waitlist entry by ID",
)
async def get_entry(entry_id: int):
    """
    Retrieve a specific waitlist entry by its ID.
    """
    logger.info(f"Retrieving entry with ID: {entry_id}")
    query = waitlist_table.select().where(waitlist_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        logger.warning(f"Entry with ID {entry_id} not found.")
        raise HTTPException(status_code=404, detail="Entry not found")
    logger.info(f"Entry found: {entry}")
    return entry

# TODO: DUE TO THE notifications with telegram we no longer need to make the list accessible via post requests i believe, its highly unsafe and bad user usage
@router.get(
    "/", response_model=List[WaitlistEntry], summary="List all waitlist entries"
)
async def list_entries():
    """
    Retrieve all waitlist entries, ordered by creation date descending.
    """
    logger.info("Listing all waitlist entries.")
    query = waitlist_table.select().order_by(waitlist_table.c.created_at.desc())
    entries = await database.fetch_all(query)
    logger.info(f"Number of entries retrieved: {len(entries)}")
    return entries


@router.put(
    "/{entry_id}", response_model=WaitlistEntry, summary="Update a waitlist entry by ID"
)
async def update_entry(entry_id: int, entry: WaitlistUpdate):
    """
    Update an existing waitlist entry's name, email, comment, and/or referral_source.
    Only provided fields will be updated.
    """
    logger.info(f"Updating entry ID {entry_id} with data: {entry.dict(exclude_unset=True)}")

    # Prepare the update data, including the comment and referral_source
    update_data = {k: v for k, v in entry.dict().items() if v is not None}
    if not update_data:
        logger.warning("No fields provided for update.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update.",
        )

    # Execute the update
    query = (
        waitlist_table.update()
        .where(waitlist_table.c.id == entry_id)
        .values(**update_data)
    )
    try:
        await database.execute(query)
        logger.info(f"Entry ID {entry_id} updated successfully.")
    except IntegrityError:
        logger.error(f"IntegrityError: Email {entry.email} already exists.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An entry with this email already exists.",
        )
    except Exception as e:
        logger.error(f"Unexpected error during update: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred.",
        )

    # Fetch the updated entry
    query = waitlist_table.select().where(waitlist_table.c.id == entry_id)
    updated_entry = await database.fetch_one(query)
    if updated_entry is None:
        logger.warning(f"Entry with ID {entry_id} not found after update.")
        raise HTTPException(status_code=404, detail="Entry not found")
    logger.info(f"Updated entry retrieved: {updated_entry}")

    # 4. Optionally, send a Telegram notification about the update
    if notifier:
        try:
            await notifier.send_updated_waitlist_entry(
                name=updated_entry['name'],
                email=updated_entry['email'],
                comment=updated_entry['comment'],
                referral_source=updated_entry['referral_source'],
            )
            logger.info(f"Telegram notification sent for updated entry ID: {entry_id}")
        except Exception as e:
            logger.error(f"Failed to send Telegram notification for update: {e}")
            # Decide whether to raise an exception or continue

    return updated_entry


@router.delete(
    "/{entry_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a waitlist entry by ID",
)
async def delete_entry(entry_id: int):
    """
    Delete a waitlist entry by its ID.
    """
    logger.info(f"Deleting entry with ID: {entry_id}")

    # Check if the entry exists
    query = waitlist_table.select().where(waitlist_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        logger.warning(f"Entry with ID {entry_id} not found for deletion.")
        raise HTTPException(status_code=404, detail="Entry not found")

    # Perform the deletion
    delete_query = waitlist_table.delete().where(waitlist_table.c.id == entry_id)
    try:
        await database.execute(delete_query)
        logger.info(f"Entry ID {entry_id} deleted successfully.")
    except Exception as e:
        logger.error(f"Unexpected error during deletion: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred.",
        )
    return {"message": "Entry deleted successfully", "entry_id": entry_id}


# 4. Event handlers to connect/disconnect the database and initialize/close the TelegramNotifier

@router.on_event("startup")
async def startup():
    logger.info("Starting up and connecting to the database.")
    try:
        await database.connect()
        logger.info("Database connected successfully.")
    except Exception as e:
        logger.error(f"Error connecting to the database: {e}")
        raise

    # 5. Initialize the TelegramNotifier during startup
    global notifier  # Declare notifier as global to modify the global variable
    try:
        notifier = TelegramNotifier()
        logger.info("TelegramNotifier initialized successfully.")
    except Exception as e:
        logger.error(f"Failed to initialize TelegramNotifier: {e}")
        # Depending on your requirements, you might want to raise an exception here
        # to prevent the application from starting without Telegram notifications.


@router.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down and disconnecting from the database.")
    try:
        await database.disconnect()
        logger.info("Database disconnected successfully.")
    except Exception as e:
        logger.error(f"Error disconnecting from the database: {e}")

    # 6. Close the TelegramNotifier during shutdown
    if notifier:
        try:
            await notifier.close()
            logger.info("TelegramNotifier closed successfully.")
        except Exception as e:
            logger.error(f"Failed to close TelegramNotifier: {e}")
