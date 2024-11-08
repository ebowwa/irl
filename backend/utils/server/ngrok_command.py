# server_router.py

from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse
import requests
import os
from typing import Optional
import asyncio
import subprocess
import sys

# Initialize the APIRouter
router = APIRouter()

class ServerState:
    """
    A class to hold and manage the server's state properties.
    """
    def __init__(self):
        self.request_count: int = 0  # Total number of incoming requests
        self.port: int = 8000        # Server port, default is 8000
        self.public_url: Optional[str] = None  # Public URL via ngrok

# Instantiate the server state
server_state = ServerState()

@router.middleware("http")
async def count_requests(request: Request, call_next):
    """
    Middleware to count each incoming HTTP request.
    
    Args:
        request (Request): The incoming HTTP request.
        call_next (callable): The next middleware or endpoint handler.
    
    Returns:
        Response: The HTTP response from the next handler.
    """
    server_state.request_count += 1
    response = await call_next(request)
    return response

def fetch_ngrok_public_url() -> Optional[str]:
    """
    Fetches the current public URL from ngrok's local API.
    
    Returns:
        Optional[str]: The public URL if available, else None.
    """
    try:
        response = requests.get("http://localhost:4040/api/tunnels")
        response.raise_for_status()
        data = response.json()
        tunnels = data.get("tunnels", [])
        for tunnel in tunnels:
            if tunnel.get("proto") == "https":
                return tunnel.get("public_url")
        return None
    except Exception as e:
        print(f"Error fetching ngrok URL: {e}", file=sys.stderr)
        return None

async def update_public_url_periodically():
    """
    Asynchronous task to periodically update the public URL from ngrok.
    Runs every 60 seconds.
    """
    while True:
        url = await asyncio.to_thread(fetch_ngrok_public_url)
        if url:
            server_state.public_url = url
            print(f"Updated public URL: {url}")
        else:
            print("Public URL not available.", file=sys.stderr)
        await asyncio.sleep(60)  # Update interval in seconds

def start_ngrok(port: int) -> None:
    """
    Starts ngrok as a subprocess to create a public URL tunnel to the specified port.
    
    Args:
        port (int): The port number to which ngrok should tunnel.
    """
    try:
        # Start ngrok as a subprocess
        subprocess.Popen(["ngrok", "http", str(port)])
        print(f"ngrok started on port {port}")
    except FileNotFoundError:
        print("ngrok executable not found. Please ensure ngrok is installed and in your PATH.", file=sys.stderr)
    except Exception as e:
        print(f"Failed to start ngrok: {e}", file=sys.stderr)

def stop_ngrok() -> None:
    """
    Stops the ngrok subprocess gracefully.
    """
    try:
        if sys.platform.startswith("win"):
            # For Windows systems
            subprocess.run(["taskkill", "/F", "/IM", "ngrok.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            # For Unix-like systems
            subprocess.run(["pkill", "ngrok"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("ngrok stopped.")
    except Exception as e:
        print(f"Failed to stop ngrok: {e}", file=sys.stderr)

@router.on_event("startup")
async def on_startup():
    """
    Event handler that runs on application startup.
    Initializes server properties, starts ngrok, and launches the background task.
    """
    # Retrieve port from environment variable or use default
    port = os.getenv("PORT")
    if port:
        try:
            server_state.port = int(port)
        except ValueError:
            print(f"Invalid PORT environment variable: {port}. Using default port {server_state.port}.", file=sys.stderr)
    
    # Start ngrok if public_url is not already available
    if not server_state.public_url:
        start_ngrok(server_state.port)
    
    # Start the background task to update the public URL periodically
    asyncio.create_task(update_public_url_periodically())

@router.on_event("shutdown")
def on_shutdown():
    """
    Event handler that runs on application shutdown.
    Cleans up resources by stopping ngrok.
    """
    stop_ngrok()

@router.get("/server-info", summary="Retrieve Server Information")
async def get_server_info():
    """
    Endpoint to retrieve current server information including:
    - Application name
    - Server port
    - Public URL (via ngrok)
    - Total number of handled requests
    
    Returns:
        JSONResponse: A JSON object containing server information.
    """
    info = {
        "app_name": "CaringMind",
        "port": server_state.port,
        "public_url": server_state.public_url,
        "request_count": server_state.request_count,
        # Additional properties can be added here
    }
    return JSONResponse(content=info)

@router.post("/reset-request-count", summary="Reset Request Counter")
async def reset_request_count():
    """
    Endpoint to reset the request counter back to zero.
    
    Returns:
        JSONResponse: A confirmation message.
    """
    server_state.request_count = 0
    return JSONResponse(content={"message": "Request count has been reset."})

@router.post("/restart-ngrok", summary="Restart ngrok Tunnel")
async def restart_ngrok():
    """
    Endpoint to restart ngrok to obtain a new public URL.
    
    Process:
    1. Stops the existing ngrok subprocess.
    2. Starts a new ngrok subprocess targeting the current port.
    3. Waits for ngrok to establish the new tunnel.
    4. Fetches and updates the new public URL.
    
    Returns:
        JSONResponse: A confirmation message with the new public URL.
    
    Raises:
        HTTPException: If ngrok fails to restart or retrieve the new URL.
    """
    stop_ngrok()
    await asyncio.sleep(2)  # Wait for ngrok to shut down
    start_ngrok(server_state.port)
    await asyncio.sleep(5)  # Wait for ngrok to establish the new tunnel
    url = fetch_ngrok_public_url()
    if url:
        server_state.public_url = url
        return JSONResponse(content={"message": "ngrok restarted successfully.", "public_url": url})
    else:
        raise HTTPException(status_code=500, detail="Failed to restart ngrok and retrieve the new public URL.")

@router.post("/update-base-domain", summary="Update Base Domain")
async def update_base_domain(new_domain: str):
    """
    Endpoint to update the base domain used by the server.
    
    Args:
        new_domain (str): The new domain to be set as the base domain.
    
    Returns:
        JSONResponse: A confirmation message with the updated domain.
    
    Note:
        - Updating environment variables at runtime may not affect already loaded configurations.
        - Ensure that any dependent components are updated accordingly.
    """
    os.environ["BASE_DOMAIN"] = new_domain
    # Implement additional logic here if the new domain needs to be applied immediately
    return JSONResponse(content={"message": f"Base domain updated to {new_domain}"})

@router.get("/", summary="Root Endpoint")
async def root():
    """
    Root endpoint providing a welcome message.
    
    Returns:
        JSONResponse: A welcome message.
    """
    return JSONResponse(content={"message": "Welcome to the CaringMind API!"})

