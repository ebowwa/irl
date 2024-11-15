# backend/route/features/gemini_transcription_v1.py

import asyncio
import websockets
import json

async def send_audio():
    uri = "ws://2157-2601-646-a201-db60-00-2386.ngrok-free.app/transcribe/ws/transcribe"  # Updated URL with prefix
    async with websockets.connect(uri) as websocket:
        # Send file metadata first
        await websocket.send(json.dumps({"file_name": "audio_file.ogg", "mime_type": "audio/ogg"}))

        # Send audio file in chunks
        with open("backend/utils/server/audio_file.ogg", "rb") as audio_file:
            while True:
                chunk = audio_file.read(1024)  # Adjust chunk size as needed
                if not chunk:
                    break
                await websocket.send(chunk)

        # Indicate end of file with empty message
        await websocket.send(b"")

        # Receive transcription results
        while True:
            try:
                response = await websocket.recv()
                print("Response:", response)
                data = json.loads(response)
                if data.get("status") == "complete":
                    break
            except websockets.exceptions.ConnectionClosed:
                print("Connection closed")
                break

# Run the client
if __name__ == "__main__":
    asyncio.run(send_audio())
    