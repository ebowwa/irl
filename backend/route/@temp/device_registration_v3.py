# backend/route/features/device_registration.py

"""
Device Registration Module
==========================

This module provides CRUD operations for device registrations, including:
- Registering a new device or updating an existing registration
- Retrieving a device registration by ID
- Listing all device registrations
- Updating a device registration
- Deleting a device registration
- **Checking if a device is registered**

TODO:
- Integrate this database either as the same DB for the Google media upload (which is likely the cleanest)
  or map a new DB to the entries of device registration.
- Handle cases in the register endpoint to ensure checks before CRUD operations.
- (Optional) Implement Telegram notifications for device registration events.
"""

from datetime import datetime
from typing import List, Optional

import logging

from fastapi import APIRouter, HTTPException, Request, status, Depends
from pydantic import BaseModel, Field, validator
import sqlalchemy

from database.user import (
    database,
    device_registration_table
)

from fastapi.security import OAuth2PasswordBearer
import jwt
import google.oauth2.id_token
import google.auth.transport.requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize the router
router = APIRouter()

# === Pydantic Models ===

class DeviceRegistrationEntry(BaseModel):
    id: int
    google_account_id: str
    device_uuid: str
    id_token: str
    access_token: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # For Pydantic v2
        # orm_mode = True  # Uncomment if using Pydantic v1

class DeviceRegistrationCreate(BaseModel):
    google_account_id: str = Field(..., example="1234567890")
    device_uuid: str = Field(..., example="550e8400-e29b-41d4-a716-446655440000")
    id_token: str = Field(..., example="eyJhbGciOiJIUzI1NiIsInR5cCI6...")
    access_token: str = Field(..., example="ya29.a0AfH6SMC...")

    @validator('google_account_id', 'device_uuid')
    def not_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('must not be empty')
        return v

class DeviceRegistrationUpdate(BaseModel):
    google_account_id: Optional[str] = None
    device_uuid: Optional[str] = None
    id_token: Optional[str] = None
    access_token: Optional[str] = None

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

# === OAuth2 and Token Verification ===

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verify_google_token(id_token: str) -> dict:
    try:
        # Specify the CLIENT_ID of the app that accesses the backend:
        CLIENT_ID = "YOUR_GOOGLE_CLIENT_ID"  # Replace with your actual Google Client ID
        idinfo = google.oauth2.id_token.verify_oauth2_token(id_token, google.auth.transport.requests.Request(), CLIENT_ID)
        return idinfo
    except ValueError:
        # Invalid token
        raise HTTPException(status_code=401, detail="Invalid ID token")

# === CRUD Endpoints ===

@router.post(
    "/register",
    response_model=DeviceRegistrationEntry,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new device or update existing registration",
)
async def register_device(entry: DeviceRegistrationCreate, request: Request, idinfo: dict = Depends(verify_google_token)):
    """
    Registers a new device with the provided information.
    If the device is already registered, updates the existing registration.

    - **google_account_id**: Unique identifier for the Google account.
    - **device_uuid**: Unique UUID for the device.
    - **id_token**: Authentication ID token.
    - **access_token**: Authentication access token.
    """
    google_account_id = idinfo.get('sub')
    device_uuid = entry.device_uuid

    logger.info(f"Registering device with Google Account ID: {google_account_id}")

    # Check if the device is already registered by google_account_id or device_uuid
    check_query = device_registration_table.select().where(
        (device_registration_table.c.google_account_id == google_account_id) |
        (device_registration_table.c.device_uuid == device_uuid)
    )
    existing_entry = await database.fetch_one(check_query)

    if existing_entry:
        logger.info("Device is already registered. Updating existing registration.")
        # Prepare the update data
        update_data = {
            "id_token": entry.id_token,
            "access_token": entry.access_token,
            "updated_at": datetime.utcnow()
        }

        # Update based on google_account_id or device_uuid
        update_query = device_registration_table.update().where(
            (device_registration_table.c.google_account_id == google_account_id) |
            (device_registration_table.c.device_uuid == device_uuid)
        ).values(**update_data)

        try:
            await database.execute(update_query)
            logger.info("Device registration updated successfully.")
        except Exception as e:
            logger.error(f"Unexpected error during device registration update: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="An unexpected error occurred during device registration update.",
            )

        # Retrieve the updated device registration
        retrieve_query = device_registration_table.select().where(
            (device_registration_table.c.google_account_id == google_account_id) |
            (device_registration_table.c.device_uuid == device_uuid)
        )
        updated_entry = await database.fetch_one(retrieve_query)
        logger.info(f"Updated device registration retrieved: {updated_entry}")

        return DeviceRegistrationEntry.model_validate(updated_entry)
    else:
        # Insert the new device registration
        query = device_registration_table.insert().values(
            google_account_id=google_account_id,
            device_uuid=device_uuid,
            id_token=entry.id_token,
            access_token=entry.access_token,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        try:
            last_record_id = await database.execute(query)
            logger.info(f"Inserted device registration with ID: {last_record_id}")
        except sqlalchemy.exc.IntegrityError as ie:
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

        return DeviceRegistrationEntry.model_validate(new_entry)

@router.get(
    "/register/{entry_id}",
    response_model=DeviceRegistrationEntry,
    summary="Retrieve a device registration by ID",
)
async def get_device_registration(entry_id: int, current_user: str = Depends(oauth2_scheme)):
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
    return DeviceRegistrationEntry.model_validate(entry)

@router.get(
    "/register",
    response_model=List[DeviceRegistrationEntry],
    summary="List all device registrations"
)
async def list_device_registrations(current_user: str = Depends(oauth2_scheme)):
    """
    Lists all device registrations, ordered by creation date descending.
    """
    logger.info("Listing all device registrations.")
    query = device_registration_table.select().order_by(device_registration_table.c.created_at.desc())
    entries = await database.fetch_all(query)
    logger.info(f"Number of device registrations retrieved: {len(entries)}")
    return [DeviceRegistrationEntry.model_validate(entry) for entry in entries]

@router.put(
    "/register/{entry_id}",
    response_model=DeviceRegistrationEntry,
    summary="Update a device registration by ID"
)
async def update_device_registration(entry_id: int, entry: DeviceRegistrationUpdate, current_user: str = Depends(oauth2_scheme)):
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
        .values(**update_data, updated_at=datetime.utcnow())
    )
    try:
        result = await database.execute(query)
        if not result:
            logger.warning(f"Device registration with ID {entry_id} not found for update.")
            raise HTTPException(status_code=404, detail="Device registration not found")
        logger.info(f"Device registration ID {entry_id} updated successfully.")
    except sqlalchemy.exc.IntegrityError as ie:
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
    return DeviceRegistrationEntry.model_validate(updated_entry)

@router.delete(
    "/register/{entry_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a device registration by ID",
)
async def delete_device_registration(entry_id: int, current_user: str = Depends(oauth2_scheme)):
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
async def check_device_registration(check: DeviceRegistrationCheck, current_user: str = Depends(oauth2_scheme)):
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
        device_entry = DeviceRegistrationEntry.model_validate(entry)
        return DeviceRegistrationCheckResponse(is_registered=True, device=device_entry)
    else:
        logger.info("Device is not registered.")
        return DeviceRegistrationCheckResponse(is_registered=False, device=None)
