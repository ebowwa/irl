import asyncio
import websockets
import json

async def send_audio():
    uri = "ws://127.0.0.1:9090/ws/transcribe"
    async with websockets.connect(uri) as websocket:
        # Send file metadata first
        await websocket.send(json.dumps({"file_name": "/Users/ebowwa/Downloads/audio_file.ogg", "mime_type": "audio/ogg"}))

        # Send audio file in chunks
        with open("path/to/audio_file.ogg", "rb") as audio_file:
            while chunk := audio_file.read(1024):  # Adjust chunk size as needed
                await websocket.send(chunk)

        # Close the connection
        await websocket.send(b"")  # Indicate end of file with empty message

        # Receive transcription results
        while True:
            response = await websocket.recv()
            print("Response:", response)

# Run the client
asyncio.run(send_audio())
