# backend/routers/websocket/HumeStreaming.py
from fastapi import WebSocket, WebSocketDisconnect
import os
from dotenv import load_dotenv
import asyncio
import websockets
import json
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
                yield json.loads(message)
        except websockets.exceptions.ConnectionClosed:
            print("Connection closed")

    async def send_data(self, file_data):
        if not self.websocket:
            print("WebSocket connection not established. Call connect() first.")
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

async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    client = HumeStreamingClient()
    connected = await client.connect()
    
    if not connected:
        await websocket.close(code=1011, reason="Failed to connect to Hume AI")
        return

    try:
        # Receive the file from the client
        file_data = await websocket.receive_bytes()
        
        # Send the file data to Hume AI
        await client.send_data(file_data)

        # Start receiving messages and forward them to the client
        async for message in client.receive_messages():
            await websocket.send_text(json.dumps(message))
    
    except WebSocketDisconnect:
        print("WebSocket connection closed")
    finally:
        if client.websocket:
            await client.websocket.close()