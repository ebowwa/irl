# backend/route/features/device_registration.py
# https://chatgpt.com/share/6736848d-b160-800f-a532-f6dabf4d1d23
"""
Device Registration Module
==========================

This module provides CRUD operations for device registrations, including:
- Registering a new device
- Retrieving a device registration by ID
- Listing all device registrations
- Updating a device registration
- Deleting a device registration
- **Checking if a device is registered**

TODO:
- Integrate this database either as the same DB for the Google media upload (which is likely the cleanest)
  or map a new DB to the entries of device registration.
- Modularize so that DB isn't created by both and initialized by both + scalability.
  [Reference](https://chatgpt.com/share/67350cef-7334-800f-9bd9-a2c2b633bd6d)
- Handle cases in the register endpoint to ensure checks before CRUD operations.
- (Optional) Implement Telegram notifications for device registration events.
"""

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
DATABASE_NAME = "app_user_identification.db"
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
    # Column("referral_source", String, nullable=True),
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
router = APIRouter()

# === Pydantic Models ===

class DeviceRegistrationEntry(BaseModel):
    id: int
    google_account_id: str
    device_uuid: str
    id_token: str
    access_token: str
    # referral_source: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True  # For Pydantic v2
        # orm_mode = True  # Uncomment if using Pydantic v1

class DeviceRegistrationCreate(BaseModel):
    google_account_id: str = Field(..., example="1234567890")
    device_uuid: str = Field(..., example="550e8400-e29b-41d4-a716-446655440000")
    id_token: str = Field(..., example="eyJhbGciOiJIUzI1NiIsInR5cCI6...")
    access_token: str = Field(..., example="ya29.a0AfH6SMC...")
    # referral_source: Optional[str] = Field(None, example="Campaign XYZ")

class DeviceRegistrationUpdate(BaseModel):
    google_account_id: Optional[str] = None
    device_uuid: Optional[str] = None
    id_token: Optional[str] = None
    access_token: Optional[str] = None
    # referral_source: Optional[str] = None

class DeviceRegistrationCheck(BaseModel):
    google_account_id: Optional[str] = None
    device_uuid: Optional[str] = None

    class Config:
        schema_extra = {
            "example": {
                "google_account_id": "1234567890",
                "device_uuid": "550e8400-e29b-41d4-a716-446655440000"
            }
        }

class DeviceRegistrationCheckResponse(BaseModel):
    is_registered: bool
    device: Optional[DeviceRegistrationEntry]

    class Config:
        from_attributes = True  # For Pydantic v2
        # orm_mode = True  # Uncomment if using Pydantic v1

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
    """
    Registers a new device with the provided information.

    - **google_account_id**: Unique identifier for the Google account.
    - **device_uuid**: Unique UUID for the device.
    - **id_token**: Authentication ID token.
    - **access_token**: Authentication access token.
    """
    logger.info(f"Registering device with Google Account ID: {entry.google_account_id}")

    # Check if the device is already registered
    check_query = device_registration_table.select().where(
        (device_registration_table.c.google_account_id == entry.google_account_id) |
        (device_registration_table.c.device_uuid == entry.device_uuid)
    )
    existing_entry = await database.fetch_one(check_query)
    if existing_entry:
        logger.warning("Attempt to register an already registered device.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A device with this Google Account ID or Device UUID already exists.",
        )

    # Insert the new device registration
    query = device_registration_table.insert().values(
        google_account_id=entry.google_account_id,
        device_uuid=entry.device_uuid,
        id_token=entry.id_token,
        access_token=entry.access_token,
        # referral_source=entry.referral_source,
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
                # referral_source=new_entry['referral_source']
            )
            logger.info(f"Telegram notification sent for device registration ID: {last_record_id}")
        except Exception as e:
            logger.error(f"Failed to send Telegram notification: {e}")
            # Optionally, decide whether to fail the request or continue
    """
    return DeviceRegistrationEntry.model_validate(new_entry)  # Updated for Pydantic v2

@router.get(
    "/register/{entry_id}",
    response_model=DeviceRegistrationEntry,
    summary="Retrieve a device registration by ID",
)
async def get_device_registration(entry_id: int):
    """
    Retrieves a device registration entry by its unique ID.

    - **entry_id**: The ID of the device registration to retrieve.
    """
    logger.info(f"Retrieving device registration with ID: {entry_id}")
    query = device_registration_table.select().where(device_registration_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        logger.warning(f"Device registration with ID {entry_id} not found.")
        raise HTTPException(status_code=404, detail="Device registration not found")
    logger.info(f"Device registration found: {entry}")
    return DeviceRegistrationEntry.model_validate(entry)  # Updated for Pydantic v2

@router.get(
    "/register",
    response_model=List[DeviceRegistrationEntry],
    summary="List all device registrations"
)
async def list_device_registrations():
    """
    Lists all device registrations, ordered by creation date descending.
    """
    logger.info("Listing all device registrations.")
    query = device_registration_table.select().order_by(device_registration_table.c.created_at.desc())
    entries = await database.fetch_all(query)
    logger.info(f"Number of device registrations retrieved: {len(entries)}")
    return [DeviceRegistrationEntry.model_validate(entry) for entry in entries]  # Updated for Pydantic v2

@router.put(
    "/register/{entry_id}",
    response_model=DeviceRegistrationEntry,
    summary="Update a device registration by ID"
)
async def update_device_registration(entry_id: int, entry: DeviceRegistrationUpdate):
    """
    Updates a device registration entry by its unique ID.

    - **entry_id**: The ID of the device registration to update.
    - **entry**: The fields to update.
    """
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
        result = await database.execute(query)
        if not result:
            logger.warning(f"Device registration with ID {entry_id} not found for update.")
            raise HTTPException(status_code=404, detail="Device registration not found")
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
    return DeviceRegistrationEntry.model_validate(updated_entry)  # Updated for Pydantic v2

@router.delete(
    "/register/{entry_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a device registration by ID",
)
async def delete_device_registration(entry_id: int):
    """
    Deletes a device registration entry by its unique ID.

    - **entry_id**: The ID of the device registration to delete.
    """
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

# === New Endpoint: Check Device Registration ===

@router.post(
    "/register/check",
    summary="Check if a device is registered",
    response_model=DeviceRegistrationCheckResponse,
    status_code=status.HTTP_200_OK,
)
async def check_device_registration(check: DeviceRegistrationCheck):
    """
    Checks if a device is registered based on Google Account ID and/or Device UUID.

    - **google_account_id**: (Optional) The Google Account ID to check.
    - **device_uuid**: (Optional) The Device UUID to check.

    Returns a JSON object indicating registration status and relevant details.
    """
    logger.info("Checking device registration status.")

    if not check.google_account_id and not check.device_uuid:
        logger.warning("No identifiers provided for registration check.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one identifier (google_account_id or device_uuid) must be provided.",
        )

    # Build the query based on provided identifiers
    query = device_registration_table.select()
    if check.google_account_id and check.device_uuid:
        query = query.where(
            (device_registration_table.c.google_account_id == check.google_account_id) &
            (device_registration_table.c.device_uuid == check.device_uuid)
        )
    elif check.google_account_id:
        query = query.where(device_registration_table.c.google_account_id == check.google_account_id)
    elif check.device_uuid:
        query = query.where(device_registration_table.c.device_uuid == check.device_uuid)

    # Execute the query
    entry = await database.fetch_one(query)
    if entry:
        logger.info("Device is registered.")
        device_entry = DeviceRegistrationEntry.model_validate(entry)  # Updated for Pydantic v2
        return DeviceRegistrationCheckResponse(is_registered=True, device=device_entry)
    else:
        logger.info("Device is not registered.")
        return DeviceRegistrationCheckResponse(is_registered=False, device=None)

# === Event Handlers ===

@router.on_event("startup")
async def startup():
    """
    Event handler for application startup. Connects to the database and initializes notifier.
    """
    logger.info("Starting up and connecting to the database.")
    try:
        await database.connect()
        logger.info("Database connected successfully.")
    except Exception as e:
        logger.error(f"Error connecting to the database: {e}")
        raise

    # Initialize TelegramNotifier
    # global notifier
    # try:
        # notifier = TelegramNotifier()
        # logger.info("TelegramNotifier initialized successfully.")
    # except Exception as e:
        # logger.error(f"Failed to initialize TelegramNotifier: {e}")

@router.on_event("shutdown")
async def shutdown():
    """
    Event handler for application shutdown. Disconnects from the database and cleans up notifier.
    """
    logger.info("Shutting down and disconnecting from the database.")
    try:
        await database.disconnect()
        logger.info("Database disconnected successfully.")
    except Exception as e:
        logger.error(f"Error disconnecting from the database: {e}")

    #if notifier:
        # Cleanup notifier if necessary
        # pass
