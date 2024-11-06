# File: utils/ngrokUtils.py

import os
import subprocess

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
    Lists all active ngrok tunnels using the ngrok command-line tool.
    The tunnels are fetched by executing `ngrok tunnels list`.
    
    Returns:
        str: The output of the ngrok tunnels list command (list of active tunnels).
    """
    try:
        result = subprocess.run(
            ["ngrok", "tunnels", "list"], capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"Error listing tunnels: {result.stderr}")
            return []
        
        # Print the active tunnels found
        print("Active tunnels:\n")
        print(result.stdout)
        
        return result.stdout  # Return the raw output of the tunnels list
    except Exception as e:
        print(f"Error occurred while listing tunnels: {e}")
        return []


def kill_active_tunnel(tunnel_name):
    """
    Terminates a specific ngrok tunnel by its tunnel name using the command-line tool.
    
    Args:
        tunnel_name (str): The name of the tunnel to terminate.
    """
    try:
        result = subprocess.run(
            ["ngrok", "tunnels", "stop", tunnel_name], capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"Error stopping tunnel {tunnel_name}: {result.stderr}")
        else:
            print(f"Successfully killed tunnel: {tunnel_name}")
    except Exception as e:
        print(f"Error occurred while killing tunnel {tunnel_name}: {e}")


def kill_all_tunnels():
    """
    Terminates all active ngrok tunnels by first listing them and then
    stopping each one using the command-line tool. This is helpful for 
    managing the free account limits (which allow only one tunnel).
    """
    active_tunnels = list_active_tunnels()  # Get the list of active tunnels
    
    if "name" in active_tunnels:  # Ensure that the output contains tunnel information
        tunnel_names = [
            line.split()[1] for line in active_tunnels.splitlines() if "name" not in line
        ]
        # Terminate each tunnel based on its name
        for tunnel_name in tunnel_names:
            kill_active_tunnel(tunnel_name)
    else:
        print("No tunnels to kill.")


# ------------------ Main Ngrok Startup Function ------------------

def start_ngrok(port):
    """
    Starts an ngrok tunnel with the given port using the NGROK_AUTHTOKEN.
    This function assumes the NGROK_AUTHTOKEN has already been set in the environment.

    Args:
        port (int): The port number for the local server to tunnel.

    Returns:
        str: The public URL of the ngrok tunnel (if successfully created).
    """
    check_ngrok_authtoken()  # Ensure the NGROK_AUTHTOKEN is set

    try:
        # Start an ngrok tunnel using the local port
        result = subprocess.run(
            ["ngrok", "http", str(port)], capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"Error starting ngrok tunnel: {result.stderr}")
            return None
        
        print(f"Ngrok tunnel successfully started on port {port}")
        print(result.stdout)  # Display tunnel information
        return result.stdout  # Return the ngrok tunnel output (public URL)
    except Exception as e:
        print(f"Error occurred while starting ngrok tunnel: {e}")
        return None


# ------------------ Testing with if __name__ == "__main__ ------------------

if __name__ == "__main__":
    """
    Main entry point to test ngrok tunnel management.
    This block will:
    1. List all active tunnels.
    2. Kill all active tunnels if any are found.
    3. List active tunnels again to confirm the operation.
    """

    print("Step 1: Listing active ngrok tunnels...")
    list_active_tunnels()  # Step 1: List any active tunnels

    print("\nStep 2: Killing all active ngrok tunnels (if any)...")
    kill_all_tunnels()  # Step 2: Kill all active tunnels

    print("\nStep 3: Listing active ngrok tunnels again to confirm...")
    list_active_tunnels()  # Step 3: List again to confirm they've been killed
