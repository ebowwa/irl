# database_events.py

import logging
from fastapi import FastAPI

from database.db_modules_v2 import database as db_v2_database
from database.waitlist_db import database as waitlist_database

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def register_db_events(app: FastAPI):
    @app.on_event("startup")
    async def startup():
        """
        Event handler for application startup. Connects to the databases.
        """
        logger.info("Connecting to the databases.")
        try:
            await db_v2_database.connect()
            logger.info("db_modules_v2 database connected successfully.")
            await waitlist_database.connect()
            logger.info("waitlist_db database connected successfully.")
        except Exception as e:
            logger.error(f"Error connecting to the databases: {e}")
            raise

    @app.on_event("shutdown")
    async def shutdown():
        """
        Event handler for application shutdown. Disconnects from the databases.
        """
        logger.info("Disconnecting from the databases.")
        try:
            await db_v2_database.disconnect()
            logger.info("db_modules_v2 database disconnected successfully.")
            await waitlist_database.disconnect()
            logger.info("waitlist_db database disconnected successfully.")
        except Exception as e:
            logger.error(f"Error disconnecting from the databases: {e}")
