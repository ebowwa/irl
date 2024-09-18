# backend/examples/hume/streaming_client.py
# Tested to work but todo to integrating 

import asyncio
import websockets
import json
import os
from dotenv import load_dotenv
import base64

# Load environment variables
load_dotenv()

API_KEY = os.getenv('HUME_API_KEY')

class HumeStreamingClient:
    def __init__(self):
        self.websocket = None

    async def connect(self):
        uri = "wss://api.hume.ai/v0/stream/models"
        headers = {"X-Hume-Api-Key": API_KEY}
        
        try:
            self.websocket = await websockets.connect(uri, extra_headers=headers)
            print("Connection opened")
            return True
        except Exception as e:
            print(f"Error connecting: {e}")
            return False

    async def receive_messages(self):
        try:
            while True:
                message = await self.websocket.recv()
                print(f"Received: {message}")
                # Here you would process the predictions
        except websockets.exceptions.ConnectionClosed:
            print("Connection closed")

    async def send_data(self, file_path):
        if not self.websocket:
            print("WebSocket connection not established. Call connect() first.")
            return

        try:
            with open(file_path, 'rb') as file:
                file_data = file.read()
        except FileNotFoundError:
            print(f"File not found: {file_path}")
            return
        
        base64_data = base64.b64encode(file_data).decode('utf-8')

        payload = {
            "data": base64_data,
            "models": {
                "prosody": {}
            }
        }

        try:
            await self.websocket.send(json.dumps(payload))
            print("Data sent")
        except Exception as e:
            print(f"Error sending data: {e}")

# async def main():
    # client = HumeStreamingClient()
    # connected = await client.connect()
    
    # if connected:
        # Start receiving messages in the background
        # receive_task = asyncio.create_task(client.receive_messages())
        
        # Send data
        # await client.send_data("/Users/ebowwa/Downloads/nice-enthusiastic-male-dan-barracuda-1-00-02.mp3")
        
        # Keep the connection open
        # await asyncio.gather(receive_task)
    # else:
        # print("Failed to connect. Exiting.")

# Run the async main function
# if __name__ == "__main__":
    # asyncio.run(main())