# services/auth_service.py
from fastapi import HTTPException
from sqlalchemy import select
from typing import Optional
import logging
from database.core import database, device_registration_table

logger = logging.getLogger(__name__)

class AuthService:
    async def verify_user(
        self,
        google_account_id: Optional[str] = None,
        device_uuid: Optional[str] = None
    ) -> Optional[int]:
        """
        Verifies user credentials and returns user_id if valid.
        Returns None if no auth credentials provided (allowing non-auth flow).
        Raises HTTPException if invalid credentials.
        """
        try:
            if not google_account_id and not device_uuid:
                return None

            # Start with a base query selecting all columns
            stmt = select(device_registration_table)

            # Add where clauses based on provided credentials
            conditions = []
            if google_account_id and device_uuid:
                stmt = stmt.where(
                    device_registration_table.c.google_account_id == google_account_id,
                    device_registration_table.c.device_uuid == device_uuid
                )
            elif google_account_id:
                stmt = stmt.where(device_registration_table.c.google_account_id == google_account_id)
            else:
                stmt = stmt.where(device_registration_table.c.device_uuid == device_uuid)

            logger.debug(f"Executing auth query: {stmt}")
            
            # Execute the query
            user = await database.fetch_one(stmt)
            
            if not user and (google_account_id or device_uuid):
                logger.warning(f"User not found for google_account_id={google_account_id}, device_uuid={device_uuid}")
                raise HTTPException(status_code=401, detail="User not registered")
            
            return user['id'] if user else None

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error in verify_user: {e}")
            raise HTTPException(status_code=500, detail=f"Authentication error: {str(e)}")

    async def get_user_by_id(self, user_id: int):
        """
        Retrieve user information by ID.
        """
        try:
            stmt = select(device_registration_table).where(
                device_registration_table.c.id == user_id
            )
            return await database.fetch_one(stmt)
        except Exception as e:
            logger.error(f"Error fetching user {user_id}: {e}")
            return None