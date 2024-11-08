# ngrok_router.py
# ANNOYING CNSOLE LOGS AND OPS -I.E.
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import JSONResponse
import requests
import os
import asyncio
import subprocess
import sys
from typing import Optional

# Initialize the APIRouter
router = APIRouter(prefix="/ngrok", tags=["ngrok"])

class ServerState:
    """
    A class to hold and manage the server's state properties.
    """
    def __init__(self):
        self.request_count: int = 0            # Total number of incoming requests
        self.port: int = 8000                  # Server port, default is 8000
        self.public_url: Optional[str] = None  # Public URL via ngrok

# Instantiate the server state
server_state = ServerState()

async def increment_request_count():
    """
    Dependency to increment the request count.

    This function acts as a dependency for each endpoint,
    ensuring that every request is counted.
    """
    server_state.request_count += 1

@router.on_event("startup")
async def on_startup():
    """
    Event handler that runs on router startup.
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
async def on_shutdown():
    """
    Event handler that runs on router shutdown.
    Cleans up resources by stopping ngrok.
    """
    stop_ngrok()

def start_ngrok(port: int) -> None:
    """
    Starts ngrok as a subprocess to create a public URL tunnel to the specified port.

    Args:
        port (int): The port number to which ngrok should tunnel.
    """
    try:
        # Start ngrok as a subprocess
        subprocess.Popen(["ngrok", "http", str(port)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
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

async def wait_for_ngrok():
    """
    Waits until ngrok's API is available or until a timeout is reached.
    """
    max_retries = 10
    delay = 3  # seconds
    for attempt in range(max_retries):
        try:
            response = requests.get("http://localhost:4040/api/tunnels")
            if response.status_code == 200:
                print("ngrok API is available.")
                return
        except requests.exceptions.ConnectionError:
            pass
        print(f"ngrok API not available yet. Retrying in {delay} seconds... (Attempt {attempt + 1}/{max_retries})")
        await asyncio.sleep(delay)
    print("ngrok API is not available after multiple attempts.", file=sys.stderr)

async def update_public_url_periodically():
    """
    Asynchronous task to periodically update the public URL from ngrok.
    Runs every 60 seconds.
    """
    # Initial wait for ngrok to be ready
    await wait_for_ngrok()
    
    while True:
        url = await asyncio.to_thread(fetch_ngrok_public_url)
        if url:
            server_state.public_url = url
            print(f"Updated public URL: {url}")
        else:
            print("Public URL not available.", file=sys.stderr)
        await asyncio.sleep(60)  # Update interval in seconds

@router.get("/server-info", summary="Retrieve Server Information", dependencies=[Depends(increment_request_count)])
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

@router.post("/reset-request-count", summary="Reset Request Counter", dependencies=[Depends(increment_request_count)])
async def reset_request_count():
    """
    Endpoint to reset the request counter back to zero.

    Returns:
        JSONResponse: A confirmation message.
    """
    server_state.request_count = 0
    return JSONResponse(content={"message": "Request count has been reset."})

@router.post("/restart-ngrok", summary="Restart ngrok Tunnel", dependencies=[Depends(increment_request_count)])
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
    try:
        # Stop existing ngrok
        if sys.platform.startswith("win"):
            subprocess.run(["taskkill", "/F", "/IM", "ngrok.exe"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.run(["pkill", "ngrok"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("ngrok stopped.")

        # Start ngrok
        subprocess.Popen(["ngrok", "http", str(server_state.port)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"ngrok started on port {server_state.port}")

        # Wait for ngrok to establish the new tunnel
        await asyncio.sleep(5)

        # Fetch new public URL
        url = fetch_ngrok_public_url()
        if url:
            server_state.public_url = url
            return JSONResponse(content={"message": "ngrok restarted successfully.", "public_url": url})
        
        raise HTTPException(status_code=500, detail="Failed to retrieve the new public URL after restarting ngrok.")
    except Exception as e:
        print(f"Error restarting ngrok: {e}", file=sys.stderr)
        raise HTTPException(status_code=500, detail="An error occurred while restarting ngrok.")

@router.post("/update-base-domain", summary="Update Base Domain", dependencies=[Depends(increment_request_count)])
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

@router.get("/", summary="Root Endpoint", dependencies=[Depends(increment_request_count)])
async def root():
    """
    Root endpoint providing a welcome message.

    Returns:
        JSONResponse: A welcome message.
    """
    return JSONResponse(content={"message": "Welcome to the CaringMind API!"})
