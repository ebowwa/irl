# File: utils/ngrokUtils.py

import os
import subprocess
import threading
import time
import re
import logging
import requests

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ------------------ Utility Functions ------------------

def check_ngrok_authtoken():
    """
    Ensures that the NGROK_AUTHTOKEN is available in the environment.
    Raises an error if not set.
    """
    authtoken = os.getenv("NGROK_AUTHTOKEN")
    if not authtoken:
        raise ValueError("NGROK_AUTHTOKEN is not set in environment variables.")
    return authtoken

# ------------------ Tunnel Management ------------------

def list_active_tunnels():
    """
    Retrieves a list of all active Ngrok tunnels by querying the Ngrok local API.
    
    Returns:
        list: A list of dictionaries containing tunnel details.
    """
    try:
        response = requests.get("http://localhost:4040/api/tunnels")
        response.raise_for_status()
        data = response.json()
        return data.get("tunnels", [])
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching Ngrok tunnels: {e}")
        return []

def get_ngrok_url_for_port(port):
    """
    Retrieves the public URL of the Ngrok tunnel running on the specified port.
    
    Args:
        port (int): The local port number to check.
    
    Returns:
        str or None: The public URL if found, else None.
    """
    tunnels = list_active_tunnels()
    for tunnel in tunnels:
        # The 'proto' field contains 'http' or 'https'
        # The 'config' -> 'addr' field contains the address, e.g., 'http://localhost:9090'
        addr = tunnel.get("config", {}).get("addr", "")
        # Normalize addr to extract port
        match = re.search(r":(\d+)$", addr)
        if match:
            tunnel_port = int(match.group(1))
            if tunnel_port == port:
                return tunnel.get("public_url")
    return None

def get_all_ngrok_urls():
    """
    Retrieves all active Ngrok public URLs.
    
    Returns:
        list: A list of public URLs.
    """
    tunnels = list_active_tunnels()
    urls = [tunnel.get("public_url") for tunnel in tunnels if tunnel.get("public_url")]
    return urls

def start_ngrok(port):
    """
    Starts an Ngrok tunnel for the specified port using subprocess.
    Note: This function will start a new Ngrok process, which may conflict with existing instances.
    Use with caution.
    
    Args:
        port (int): The port number to tunnel.
    
    Returns:
        str or None: The public URL if successfully started, else None.
    """
    check_ngrok_authtoken()  # Ensure the NGROK_AUTHTOKEN is set

    try:
        # Start ngrok as a subprocess
        process = subprocess.Popen(
            ["ngrok", "http", str(port)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        logger.info(f"Started Ngrok process with PID: {process.pid}")
        return process
    except Exception as e:
        logger.error(f"Error starting Ngrok tunnel: {e}")
        return None

def kill_active_tunnel(tunnel_name):
    """
    Terminates a specific Ngrok tunnel by its tunnel name using the Ngrok local API.
    
    Args:
        tunnel_name (str): The name of the tunnel to terminate.
    """
    try:
        response = requests.delete(f"http://localhost:4040/api/tunnels/{tunnel_name}")
        if response.status_code == 204:
            logger.info(f"Successfully killed tunnel: {tunnel_name}")
        else:
            logger.error(f"Failed to kill tunnel {tunnel_name}: {response.text}")
    except requests.exceptions.RequestException as e:
        logger.error(f"Error terminating tunnel {tunnel_name}: {e}")

def kill_all_tunnels():
    """
    Terminates all active Ngrok tunnels by querying the Ngrok local API.
    """
    tunnels = list_active_tunnels()
    for tunnel in tunnels:
        tunnel_name = tunnel.get("name")
        if tunnel_name:
            kill_active_tunnel(tunnel_name)
    logger.info("All Ngrok tunnels have been terminated.")

# ------------------ Testing with if __name__ == "__main__" ------------------

if __name__ == "__main__":
    """
    Main entry point to test Ngrok tunnel management.
    This block will:
    1. List all active tunnels.
    2. Kill all active tunnels if any are found.
    3. List active tunnels again to confirm the operation.
    4. Start a new tunnel on a specified port.
    5. Display the new tunnel's public URL.
    """
    import json

    PORT = 9090  # Example port

    print("Step 1: Listing active Ngrok tunnels...")
    tunnels = list_active_tunnels()
    print(json.dumps(tunnels, indent=2))
    
    print("\nStep 2: Killing all active Ngrok tunnels (if any)...")
    kill_all_tunnels()
    
    print("\nStep 3: Listing active Ngrok tunnels again to confirm...")
    tunnels = list_active_tunnels()
    print(json.dumps(tunnels, indent=2))
    
    print(f"\nStep 4: Starting a new Ngrok tunnel on port {PORT}...")
    process = start_ngrok(PORT)
    if process:
        print(f"Ngrok tunnel started with PID: {process.pid}")
        time.sleep(5)  # Wait for Ngrok to initialize
        url = get_ngrok_url_for_port(PORT)
        if url:
            print(f"Ngrok tunnel started at: {url}")
        else:
            print("Failed to retrieve Ngrok URL.")
    else:
        print("Failed to start Ngrok tunnel.")
