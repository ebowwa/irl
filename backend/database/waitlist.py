# backend/database/waitlist_db.py
from sqlalchemy import Column, DateTime, BigInteger, String, Table, func
from utils.db_state import database, metadata

# Define the waitlist table with an additional 'referral_source' column
waitlist_table = Table(
    "waitlist",
    metadata,
    Column("id", BigInteger, primary_key=True, index=True),
    Column("name", String, nullable=False),
    Column("email", String, unique=True, index=True, nullable=False),
    Column("ip_address", String, nullable=True),
    Column("comment", String, nullable=True),
    Column("referral_source", String, nullable=True),
    Column("created_at", DateTime(timezone=True), server_default=func.now(), nullable=False),
)


