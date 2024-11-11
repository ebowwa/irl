# backend/route/website_services/waitlist_router.py 

# we need to allow an additional string comment to be saved alongside this waitlist
# the ui will have it answer `What excites you most about our platform?` the user will respond and we need to collect this as well alongisde the email and name

from datetime import datetime
from typing import List, Optional

import databases
import sqlalchemy
from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import Column, DateTime, Integer, String, Table, func

# Database URL for SQLite with a more descriptive name
DATABASE_URL = "sqlite+aiosqlite:///./waitlist_data.db" # how can this store the db in `/caringmind/data`

# For PostgreSQL in production, use:
# DATABASE_URL = "postgresql+asyncpg://user:password@localhost/dbname"

# Initialize the database
database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

# Define the waitlist table
waitlist_table = Table(
    "waitlist",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("name", String, nullable=False),
    Column("email", String, unique=True, index=True, nullable=False),
    Column("ip_address", String, nullable=True),
    Column("created_at", DateTime, default=func.now(), nullable=False),
)

# Create the database engine
engine = sqlalchemy.create_engine(
    DATABASE_URL.replace("+aiosqlite", ""),
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
)

# Create the table(s)
metadata.create_all(engine)

# Initialize the router
router = APIRouter(prefix="/waitlist", tags=["Waitlist CRUD"])


# Pydantic Models
class WaitlistEntry(BaseModel):
    id: int
    name: str
    email: EmailStr
    ip_address: Optional[str]
    created_at: datetime

    class Config:
        orm_mode = True


class WaitlistCreate(BaseModel):
    name: str
    email: EmailStr


class WaitlistUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None


# CRUD Endpoints


@router.post(
    "/",
    response_model=WaitlistEntry,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new waitlist entry",
)
async def create_entry(entry: WaitlistCreate, request: Request):
    """
    Create a new waitlist entry with the provided name and email.
    The client's IP address is recorded from the request headers.
    """
    # Extract client IP
    ip_address = request.headers.get("X-Forwarded-For")
    if ip_address:
        ip_address = ip_address.split(",")[0].strip()
    else:
        ip_address = request.client.host

    # Insert the new entry
    query = waitlist_table.insert().values(
        name=entry.name,
        email=entry.email,
        ip_address=ip_address,
    )
    try:
        last_record_id = await database.execute(query)
    except databases.UniqueViolationError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An entry with this email already exists.",
        )

    # Retrieve the created entry
    query = waitlist_table.select().where(waitlist_table.c.id == last_record_id)
    new_entry = await database.fetch_one(query)
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
    query = waitlist_table.select().where(waitlist_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        raise HTTPException(status_code=404, detail="Entry not found")
    return entry


@router.get(
    "/", response_model=List[WaitlistEntry], summary="List all waitlist entries"
)
async def list_entries():
    """
    Retrieve all waitlist entries, ordered by creation date descending.
    """
    query = waitlist_table.select().order_by(waitlist_table.c.created_at.desc())
    return await database.fetch_all(query)


@router.put(
    "/{entry_id}", response_model=WaitlistEntry, summary="Update a waitlist entry by ID"
)
async def update_entry(entry_id: int, entry: WaitlistUpdate):
    """
    Update an existing waitlist entry's name and/or email.
    Only provided fields will be updated.
    """
    # Prepare the update data
    update_data = {k: v for k, v in entry.dict().items() if v is not None}
    if not update_data:
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
    except databases.UniqueViolationError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An entry with this email already exists.",
        )

    # Fetch the updated entry
    query = waitlist_table.select().where(waitlist_table.c.id == entry_id)
    updated_entry = await database.fetch_one(query)
    if updated_entry is None:
        raise HTTPException(status_code=404, detail="Entry not found")
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
    # Check if the entry exists
    query = waitlist_table.select().where(waitlist_table.c.id == entry_id)
    entry = await database.fetch_one(query)
    if entry is None:
        raise HTTPException(status_code=404, detail="Entry not found")

    # Perform the deletion
    delete_query = waitlist_table.delete().where(waitlist_table.c.id == entry_id)
    await database.execute(delete_query)
    return {"message": "Entry deleted successfully", "entry_id": entry_id}


# Event handlers to connect/disconnect the database
@router.on_event("startup")
async def startup():
    await database.connect()


@router.on_event("shutdown")
async def shutdown():
    await database.disconnect()
