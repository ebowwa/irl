# File: route/ngrok/ngrok_url.py

from fastapi import APIRouter, HTTPException
from utils.server.ngrok_utils import get_ngrok_url_for_port
import os

router = APIRouter()

@router.get("/url", summary="Get Ngrok Public URL", tags=["Ngrok"])
async def get_ngrok_url():
    """
    Returns the current Ngrok public URL for the specified port.
    """
    # Get the port from environment variables or set a default
    port = int(os.getenv("PORT", 9090))
    
    # Fetch the Ngrok URL for the specified port
    ngrok_url = get_ngrok_url_for_port(port)
    
    if ngrok_url:
        return {"ngrok_url": ngrok_url}
    else:
        raise HTTPException(status_code=404, detail="Ngrok URL not available.")
