#!/usr/bin/env python3
import os
import asyncio
from pathlib import Path
import sqlalchemy
from sqlalchemy.ext.asyncio import create_async_engine
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

async def init_db():
    """Initialize the database tables."""
    try:
        # Import database configuration
        from utils.db_state import database, metadata
        
        # Get environment
        env = os.getenv("ENVIRONMENT", "development")
        
        if env == "development":
            # Development: Use SQLite
            BASE_DIR = Path(__file__).resolve().parent.parent / "data"
            DATABASE_NAME = "development.db"
            DATABASE_PATH = BASE_DIR / DATABASE_NAME
            
            # Ensure the data directory exists
            BASE_DIR.mkdir(parents=True, exist_ok=True)
            
            # Create SQLite engine
            engine = create_async_engine(f"sqlite+aiosqlite:///{DATABASE_PATH}")
            
        else:
            # Production: Use Supabase PostgreSQL
            database_url = os.getenv("SUPABASE_DATABASE_URL")
            
            if not database_url:
                raise ValueError("Missing SUPABASE_DATABASE_URL in environment")
            
            # Remove sslmode from URL and add it to connect_args
            database_url = database_url.replace("?sslmode=require", "")
                
            # Create PostgreSQL engine with SSL configuration
            engine = create_async_engine(
                database_url,
                connect_args={"ssl": "require"}
            )
        
        async with engine.begin() as conn:
            # Create all tables
            await conn.run_sync(metadata.create_all)
            print(f"Database tables created successfully in {env} environment")
        
        await engine.dispose()
        
    except Exception as e:
        print(f"Error initializing database: {e}")
        raise

if __name__ == "__main__":
    asyncio.run(init_db())
