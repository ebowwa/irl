# backend/route/features/device_registration.py
# TODO: 
# - remove Telegram & notifications
# - 
# need to handle cases to the register endpoint to be sure check before crud op
from datetime import datetime
from typing import List, Optional
from pathlib import Path
import logging

import databases
import sqlalchemy
from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, Field
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

# === Database Configuration ===

BASE_DIR = Path(__file__).resolve().parent.parent.parent / "data"
DATABASE_NAME = "device_registration.db"
DATABASE_PATH = BASE_DIR / DATABASE_NAME

# Ensure the directory exists
BASE_DIR.mkdir(parents=True, exist_ok=True)
logger.info(f"Database directory ensured at: {BASE_DIR.as_posix()}")

DATABASE_URL = f"sqlite+aiosqlite:///{DATABASE_PATH.as_posix()}"

# Initialize the database
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

# === Define the Device Registration Table ===

device_registration_table = Table(
    "device_registration",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("google_account_id", String, unique=True, index=True, nullable=False),
    Column("device_uuid", String, unique=True, index=True, nullable=False),
    Column("id_token", String, nullable=False),
    Column("access_token", String, nullable=False),
    Column("referral_source", String, nullable=True),
    Column("created_at", DateTime, default=func.now(), nullable=False),
)

# Create the database engine
engine = sqlalchemy.create_engine(
    DATABASE_URL.replace("+aiosqlite", ""),
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
)

# Create the table(s)
metadata.create_all(engine)
logger.info("Device registration tables created or already exist.")

# Initialize the router
router = APIRouter(prefix="", tags=["Device Registration CRUD"])

# === Pydantic Models ===

class DeviceRegistrationEntry(BaseModel):
    id: int
    google_account_id: str
    device_uuid: str
    id_token: str
    access_token: str
    referral_source: Optional[str]
    created_at: datetime

    class Config:
        orm_mode = True

class DeviceRegistrationCreate(BaseModel):
    google_account_id: str = Field(..., example="1234567890")
    device_uuid: str = Field(..., example="550e8400-e29b-41d4-a716-446655440000")
    id_token: str = Field(..., example="eyJhbGciOiJIUzI1NiIsInR5cCI6...")
    access_token: str = Field(..., example="ya29.a0AfH6SMC...")
    referral_source: Optional[str] = Field(None, example="Campaign XYZ")

class DeviceRegistrationUpdate(BaseModel):
    google_account_id: Optional[str] = None
    device_uuid: Optional[str] = None
    id_token: Optional[str] = None
    access_token: Optional[str] = None
    referral_source: Optional[str] = None

# === Telegram Notifier Initialization ===

# notifier: Optional[TelegramNotifier] = None

# === CRUD Endpoints ===

@router.post(
    "/register",
    response_model=DeviceRegistrationEntry,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new device",
)
async def register_device(entry: DeviceRegistrationCreate, request: Request):
    logger.info(f"Registering device with Google Account ID: {entry.google_account_id}")

    # Insert the new device registration
    query = device_registration_table.insert().values(
        google_account_id=entry.google_account_id,
        device_uuid=entry.device_uuid,
        id_token=entry.id_token,
        access_token=entry.access_token,
        referral_source=entry.referral_source,
    )
    try:
        last_record_id = await database.execute(query)
        logger.info(f"Inserted device registration with ID: {last_record_id}")
    except IntegrityError as ie:
        logger.error(f"IntegrityError: {ie}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A device with this Google Account ID or Device UUID already exists.",
        )
    except Exception as e:
        logger.error(f"Unexpected error during device registration: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred during device registration.",
        )

    # Retrieve the created device registration
    query = device_registration_table.select().where(device_registration_table.c.id == last_record_id)
    new_entry = await database.fetch_one(query)
    logger.info(f"New device registration retrieved: {new_entry}")

    # Send Telegram notification
    """
    if notifier:
        try:
            await notifier.send_new_device_registration(
                google_account_id=new_entry['google_account_id'],
                device_uuid=new_entry['device_uuid'],
                referral_source=new_entry['referral_source']
            )
            logger.info(f"Telegram notification sent for device registration ID: {last_record_id}")
        except Exception as e:
            logger.error(f"Failed to send Telegram notification: {e}")
            # Optionally, decide whether to fail the request or continue
    """
    return new_entry

@router.get(
    "/register/{entry_id}",
    response_model=DeviceRegistrationEntry,
    summary="Retrieve a device registration by ID",
)
async def get_device_registration(entry_id: int):
    logger.info(f"Retrieving device registration with ID: {entry_id}")
    query = device_registration_table.select().where(device_registration_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        logger.warning(f"Device registration with ID {entry_id} not found.")
        raise HTTPException(status_code=404, detail="Device registration not found")
    logger.info(f"Device registration found: {entry}")
    return entry

@router.get(
    "/register",
    response_model=List[DeviceRegistrationEntry],
    summary="List all device registrations"
)
async def list_device_registrations():
    logger.info("Listing all device registrations.")
    query = device_registration_table.select().order_by(device_registration_table.c.created_at.desc())
    entries = await database.fetch_all(query)
    logger.info(f"Number of device registrations retrieved: {len(entries)}")
    return entries

@router.put(
    "/register/{entry_id}",
    response_model=DeviceRegistrationEntry,
    summary="Update a device registration by ID"
)
async def update_device_registration(entry_id: int, entry: DeviceRegistrationUpdate):
    logger.info(f"Updating device registration ID {entry_id} with data: {entry.dict(exclude_unset=True)}")

    # Prepare the update data
    update_data = {k: v for k, v in entry.dict().items() if v is not None}
    if not update_data:
        logger.warning("No fields provided for update.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update.",
        )

    # Execute the update
    query = (
        device_registration_table.update()
        .where(device_registration_table.c.id == entry_id)
        .values(**update_data)
    )
    try:
        await database.execute(query)
        logger.info(f"Device registration ID {entry_id} updated successfully.")
    except IntegrityError as ie:
        logger.error(f"IntegrityError: {ie}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A device with the provided Google Account ID or Device UUID already exists.",
        )
    except Exception as e:
        logger.error(f"Unexpected error during update: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred during update.",
        )

    # Fetch the updated device registration
    query = device_registration_table.select().where(device_registration_table.c.id == entry_id)
    updated_entry = await database.fetch_one(query)
    if updated_entry is None:
        logger.warning(f"Device registration with ID {entry_id} not found after update.")
        raise HTTPException(status_code=404, detail="Device registration not found")
    logger.info(f"Updated device registration retrieved: {updated_entry}")
    return updated_entry

@router.delete(
    "/register/{entry_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a device registration by ID",
)
async def delete_device_registration(entry_id: int):
    logger.info(f"Deleting device registration with ID: {entry_id}")

    # Check if the device registration exists
    query = device_registration_table.select().where(device_registration_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        logger.warning(f"Device registration with ID {entry_id} not found for deletion.")
        raise HTTPException(status_code=404, detail="Device registration not found")

    # Perform the deletion
    delete_query = device_registration_table.delete().where(device_registration_table.c.id == entry_id)
    try:
        await database.execute(delete_query)
        logger.info(f"Device registration ID {entry_id} deleted successfully.")
    except Exception as e:
        logger.error(f"Unexpected error during deletion: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred during deletion.",
        )
    return {"message": "Device registration deleted successfully", "entry_id": entry_id}

# === Event Handlers ===

@router.on_event("startup")
async def startup():
    logger.info("Starting up and connecting to the database.")
    try:
        await database.connect()
        logger.info("Database connected successfully.")
    except Exception as e:
        logger.error(f"Error connecting to the database: {e}")
        raise

    # Initialize TelegramNotifier
    #global notifier
    #try:
        # notifier = TelegramNotifier()
        #logger.info("TelegramNotifier initialized successfully.")
    #except Exception as e:
        #logger.error(f"Failed to initialize TelegramNotifier: {e}")

@router.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down and disconnecting from the database.")
    try:
        await database.disconnect()
        logger.info("Database disconnected successfully.")
    except Exception as e:
        logger.error(f"Error disconnecting from the database: {e}")

    #if notifier:
        #pass