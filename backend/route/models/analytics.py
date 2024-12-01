import sqlite3
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import os
from pathlib import Path
import json

router = APIRouter()

# Use relative path from the current file to the database
CURRENT_DIR = Path(__file__).parent.parent.parent
DB_DIR = CURRENT_DIR / "database"
DB_PATH = str(DB_DIR / "analytics.db")

def ensure_db_exists():
    """Ensure database and tables exist"""
    try:
        os.makedirs(DB_DIR, exist_ok=True)
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        # User visits table - tracks session-level data with retention metrics
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
                days_active INTEGER DEFAULT 1,
                weekly_visits INTEGER DEFAULT 1,
                monthly_visits INTEGER DEFAULT 1,
                streak_days INTEGER DEFAULT 1,
                last_streak_update TEXT,
                engagement_score FLOAT DEFAULT 0.0,
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
                page TEXT,
                engagement_value FLOAT DEFAULT 1.0
            )
        ''')
        
        # User achievements table - for gamification
        c.execute('''
            CREATE TABLE IF NOT EXISTS user_achievements (
                visitor_id TEXT,
                achievement_type TEXT,
                achievement_data TEXT,
                earned_timestamp TEXT,
                points INTEGER DEFAULT 0,
                PRIMARY KEY (visitor_id, achievement_type)
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

def update_retention_metrics(c, visitor_id: str, current_time: datetime):
    """Update retention-related metrics for a user"""
    c.execute('''
        SELECT last_visit_timestamp, streak_days, last_streak_update,
               weekly_visits, monthly_visits
        FROM user_visits 
        WHERE visitor_id = ? 
        ORDER BY last_visit_timestamp DESC 
        LIMIT 1
    ''', (visitor_id,))
    
    result = c.fetchone()
    if not result:
        return
    
    last_visit = datetime.fromisoformat(result[0])
    current_streak = result[1]
    last_streak_update = datetime.fromisoformat(result[2]) if result[2] else None
    weekly_visits = result[3]
    monthly_visits = result[4]
    
    # Update streak
    if last_streak_update:
        days_diff = (current_time.date() - last_streak_update.date()).days
        if days_diff == 1:  # Consecutive day
            current_streak += 1
        elif days_diff > 1:  # Streak broken
            current_streak = 1
    
    # Update weekly and monthly visits
    if last_visit:
        if (current_time - last_visit) <= timedelta(days=7):
            weekly_visits += 1
        if (current_time - last_visit) <= timedelta(days=30):
            monthly_visits += 1
    
    return current_streak, weekly_visits, monthly_visits

def calculate_engagement_score(c, visitor_id: str):
    """Calculate user engagement score based on various metrics"""
    c.execute('''
        SELECT visit_count, streak_days, weekly_visits, monthly_visits
        FROM user_visits 
        WHERE visitor_id = ? 
        ORDER BY last_visit_timestamp DESC 
        LIMIT 1
    ''', (visitor_id,))
    
    metrics = c.fetchone()
    if not metrics:
        return 0.0
    
    visit_weight = 0.3
    streak_weight = 0.3
    weekly_weight = 0.2
    monthly_weight = 0.2
    
    score = (
        (metrics[0] * visit_weight) +
        (metrics[1] * streak_weight) +
        (metrics[2] * weekly_weight) +
        (metrics[3] * monthly_weight)
    )
    
    return min(score, 100.0)  # Cap at 100

@router.post("/track")
async def track_visitor(data: VisitorData):
    if not ensure_db_exists():
        return {"success": False, "error": "Could not create or access database"}
    
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        current_time = datetime.fromtimestamp(data.timestamp / 1000)
        current_time_iso = current_time.isoformat()
        
        # Update retention metrics
        streak, weekly, monthly = update_retention_metrics(c, data.visitor_id, current_time)
        engagement_score = calculate_engagement_score(c, data.visitor_id)
        
        # Update or insert user visit data
        c.execute('''
            INSERT INTO user_visits (
                visitor_id, session_id, first_visit_timestamp, last_visit_timestamp,
                visit_count, last_page, user_agent, screen_resolution, device_type,
                city, country, streak_days, weekly_visits, monthly_visits,
                last_streak_update, engagement_score
            ) VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(visitor_id, session_id) DO UPDATE SET
                last_visit_timestamp = ?,
                visit_count = visit_count + 1,
                last_page = ?,
                total_time_spent = (
                    strftime('%s', ?) - 
                    strftime('%s', first_visit_timestamp)
                ),
                streak_days = ?,
                weekly_visits = ?,
                monthly_visits = ?,
                last_streak_update = ?,
                engagement_score = ?
        ''', (
            data.visitor_id,
            data.session_id,
            current_time_iso,
            current_time_iso,
            data.page,
            data.user_agent,
            data.screen_resolution,
            data.device_type,
            data.location.get('city') if data.location else None,
            data.location.get('country') if data.location else None,
            streak,
            weekly,
            monthly,
            current_time_iso,
            engagement_score,
            # For ON CONFLICT UPDATE
            current_time_iso,
            data.page,
            current_time_iso,
            streak,
            weekly,
            monthly,
            current_time_iso,
            engagement_score
        ))
        
        # If there's an event, track it with engagement value
        if data.event_type:
            engagement_value = 1.0
            if data.event_type == 'complete_exercise':
                engagement_value = 5.0
            elif data.event_type == 'start_session':
                engagement_value = 2.0
            
            c.execute('''
                INSERT INTO user_events (
                    visitor_id, event_type, event_data, timestamp, page,
                    engagement_value
                ) VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                data.visitor_id,
                data.event_type,
                json.dumps(data.event_data) if data.event_data else None,
                current_time_iso,
                data.page,
                engagement_value
            ))
            
            # Check for achievements
            if data.event_type == 'complete_exercise':
                c.execute('''
                    SELECT COUNT(*) FROM user_events 
                    WHERE visitor_id = ? AND event_type = 'complete_exercise'
                ''', (data.visitor_id,))
                exercise_count = c.fetchone()[0]
                
                # Award achievements based on milestones
                milestones = {
                    5: ('exercise_novice', 10),
                    25: ('exercise_intermediate', 25),
                    100: ('exercise_master', 50)
                }
                
                for count, (achievement, points) in milestones.items():
                    if exercise_count == count:
                        c.execute('''
                            INSERT OR IGNORE INTO user_achievements
                            (visitor_id, achievement_type, achievement_data,
                             earned_timestamp, points)
                            VALUES (?, ?, ?, ?, ?)
                        ''', (
                            data.visitor_id,
                            achievement,
                            json.dumps({'exercise_count': count}),
                            current_time_iso,
                            points
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
        
        # Get latest visit data with retention metrics
        c.execute('''
            SELECT 
                first_visit_timestamp,
                last_visit_timestamp,
                visit_count,
                total_time_spent,
                last_page,
                device_type,
                city,
                country,
                streak_days,
                weekly_visits,
                monthly_visits,
                engagement_score
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
                    "visit_count": 0,
                    "engagement_score": 0
                }
            }
        
        # Get recent events
        c.execute('''
            SELECT event_type, event_data, timestamp, engagement_value
            FROM user_events
            WHERE visitor_id = ?
            ORDER BY timestamp DESC
            LIMIT 5
        ''', (visitor_id,))
        
        recent_events = [{
            "type": event[0],
            "data": event[1],
            "timestamp": event[2],
            "engagement_value": event[3]
        } for event in c.fetchall()]
        
        # Get achievements
        c.execute('''
            SELECT achievement_type, achievement_data, earned_timestamp, points
            FROM user_achievements
            WHERE visitor_id = ?
            ORDER BY earned_timestamp DESC
        ''', (visitor_id,))
        
        achievements = [{
            "type": ach[0],
            "data": json.loads(ach[1]) if ach[1] else None,
            "earned_timestamp": ach[2],
            "points": ach[3]
        } for ach in c.fetchall()]
        
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
            "streak_days": visit_data[8],
            "weekly_visits": visit_data[9],
            "monthly_visits": visit_data[10],
            "engagement_score": visit_data[11],
            "recent_events": recent_events,
            "achievements": achievements,
            "total_achievement_points": sum(ach["points"] for ach in achievements)
        }
        
        conn.close()
        return {"success": True, "data": metadata}
        
    except Exception as e:
        print(f"Error getting user metadata: {e}")
        return {"success": False, "error": str(e)}
