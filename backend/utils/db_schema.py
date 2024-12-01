from sqlalchemy import Table, Column, Integer, String, DateTime, ForeignKey, MetaData
from datetime import datetime

metadata = MetaData()

# Define your tables here
users = Table(
    "users",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("created_at", DateTime, default=datetime.utcnow),
    Column("updated_at", DateTime, default=datetime.utcnow, onupdate=datetime.utcnow),
)

audio_transcriptions = Table(
    "audio_transcriptions",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("user_id", Integer, ForeignKey("users.id")),
    Column("file_path", String),
    Column("transcription", String),
    Column("created_at", DateTime, default=datetime.utcnow),
)
