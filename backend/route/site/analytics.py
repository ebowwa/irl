import sqlite3
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import os

router = APIRouter()

DB_PATH = "/Users/ebowwa/caringmind/backend/database/analytics.db"

# Initialize analytics table if it doesn't exist
def init_analytics_table():
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

init_analytics_table()

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
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    try:
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
        return {"status": "success", "message": "Analytics data stored successfully"}
    
    except Exception as e:
        return {"status": "error", "message": str(e)}
    
    finally:
        conn.close()
