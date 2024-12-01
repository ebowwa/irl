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
        os.makedirs(DB_DIR, exist_ok=True)
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        # User visits table - tracks session-level data
        c.execute('''
            CREATE TABLE IF NOT EXISTS user_visits (
                visitor_id TEXT,
                session_id TEXT,
                first_visit_timestamp TEXT,
                last_visit_timestamp TEXT,
                visit_count INTEGER DEFAULT 1,
                total_time_spent INTEGER DEFAULT 0,
                last_page TEXT,
                user_agent TEXT,
                screen_resolution TEXT,
                device_type TEXT,
                city TEXT,
                country TEXT,
                PRIMARY KEY (visitor_id, session_id)
            )
        ''')
        
        # User events table - tracks specific user actions
        c.execute('''
            CREATE TABLE IF NOT EXISTS user_events (
                visitor_id TEXT,
                event_type TEXT,
                event_data TEXT,
                timestamp TEXT,
                page TEXT
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
    session_id: str
    timestamp: int
    page: str
    referrer: Optional[str] = None
    user_agent: str
    screen_resolution: str
    device_type: str
    location: Optional[dict] = None
    event_type: Optional[str] = None
    event_data: Optional[dict] = None

@router.post("/track")
async def track_visitor(data: VisitorData):
    if not ensure_db_exists():
        return {"success": False, "error": "Could not create or access database"}
    
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        current_time = datetime.fromtimestamp(data.timestamp / 1000).isoformat()
        
        # Update or insert user visit data
        c.execute('''
            INSERT INTO user_visits (
                visitor_id, session_id, first_visit_timestamp, last_visit_timestamp,
                visit_count, last_page, user_agent, screen_resolution, device_type,
                city, country
            ) VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(visitor_id, session_id) DO UPDATE SET
                last_visit_timestamp = ?,
                visit_count = visit_count + 1,
                last_page = ?,
                total_time_spent = (
                    strftime('%s', ?) - 
                    strftime('%s', first_visit_timestamp)
                )
        ''', (
            data.visitor_id,
            data.session_id,
            current_time,  # first_visit_timestamp
            current_time,  # last_visit_timestamp
            data.page,
            data.user_agent,
            data.screen_resolution,
            data.device_type,
            data.location.get('city') if data.location else None,
            data.location.get('country') if data.location else None,
            # For ON CONFLICT UPDATE
            current_time,
            data.page,
            current_time
        ))
        
        # If there's an event, track it
        if data.event_type:
            c.execute('''
                INSERT INTO user_events (
                    visitor_id, event_type, event_data, timestamp, page
                ) VALUES (?, ?, ?, ?, ?)
            ''', (
                data.visitor_id,
                data.event_type,
                str(data.event_data) if data.event_data else None,
                current_time,
                data.page
            ))
        
        conn.commit()
        conn.close()
        return {"success": True}
    except Exception as e:
        print(f"Error tracking visitor: {e}")
        return {"success": False, "error": str(e)}

@router.get("/user/{visitor_id}")
async def get_user_metadata(visitor_id: str):
    if not ensure_db_exists():
        return {"success": False, "error": "Could not access database"}
    
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        # Get latest visit data
        c.execute('''
            SELECT 
                first_visit_timestamp,
                last_visit_timestamp,
                visit_count,
                total_time_spent,
                last_page,
                device_type,
                city,
                country
            FROM user_visits 
            WHERE visitor_id = ?
            ORDER BY last_visit_timestamp DESC
            LIMIT 1
        ''', (visitor_id,))
        
        visit_data = c.fetchone()
        
        if not visit_data:
            return {
                "success": True,
                "data": {
                    "is_first_visit": True,
                    "visit_count": 0
                }
            }
        
        # Get recent events
        c.execute('''
            SELECT event_type, event_data, timestamp
            FROM user_events
            WHERE visitor_id = ?
            ORDER BY timestamp DESC
            LIMIT 5
        ''', (visitor_id,))
        
        recent_events = [{
            "type": event[0],
            "data": event[1],
            "timestamp": event[2]
        } for event in c.fetchall()]
        
        metadata = {
            "is_first_visit": False,
            "first_visit": visit_data[0],
            "last_visit": visit_data[1],
            "visit_count": visit_data[2],
            "total_time_spent_seconds": visit_data[3],
            "last_page": visit_data[4],
            "device_type": visit_data[5],
            "city": visit_data[6],
            "country": visit_data[7],
            "recent_events": recent_events
        }
        
        conn.close()
        return {"success": True, "data": metadata}
        
    except Exception as e:
        print(f"Error getting user metadata: {e}")
        return {"success": False, "error": str(e)}
