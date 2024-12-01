import sqlite3
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import os
from pathlib import Path

router = APIRouter()

# Use relative path from the current file to the database
CURRENT_DIR = Path(__file__).parent.parent.parent  # Go up to backend directory
DB_DIR = CURRENT_DIR / "database"
DB_PATH = str(DB_DIR / "analytics.db")

def ensure_db_exists():
    """Ensure database and table exist"""
    try:
        os.makedirs(DB_DIR, exist_ok=True)  # Ensure database directory exists
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('''
            CREATE TABLE IF NOT EXISTS visitor_analytics (
                visitor_id TEXT,
                timestamp TEXT,
                page TEXT,
                referrer TEXT,
                user_agent TEXT,
                screen_resolution TEXT,
                device_type TEXT,
                city TEXT,
                country TEXT
            )
        ''')
        conn.commit()
        conn.close()
        return True
    except Exception as e:
        print(f"Error ensuring database exists: {e}")
        return False

class VisitorData(BaseModel):
    visitor_id: str
    timestamp: int
    page: str
    referrer: Optional[str] = None
    user_agent: str
    screen_resolution: str
    device_type: str
    location: Optional[dict] = None

@router.post("/track")
async def track_visitor(data: VisitorData):
    # First ensure database exists
    if not ensure_db_exists():
        return {"success": False, "error": "Could not create or access database"}
    
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        c.execute('''
            INSERT INTO visitor_analytics 
            (visitor_id, timestamp, page, referrer, user_agent, screen_resolution, device_type, city, country)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            data.visitor_id,
            datetime.fromtimestamp(data.timestamp / 1000).isoformat(),
            data.page,
            data.referrer,
            data.user_agent,
            data.screen_resolution,
            data.device_type,
            data.location.get('city') if data.location else None,
            data.location.get('country') if data.location else None
        ))
        conn.commit()
        conn.close()
        return {"success": True}
    except Exception as e:
        print(f"Error tracking visitor: {e}")  # Log the error
        return {"success": False, "error": str(e)}
