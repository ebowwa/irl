# File: main.py

from fastapi import FastAPI
from routers.websocket import ping, whisper_tts
from routers.post.Hume import prosody  # Import the new Hume router
from routers.post.LLM.claude import router as claude_router

app = FastAPI()

# Internal: Ping Route for Status Checks
app.include_router(ping.router)

# TODO: ON-CLIENT: only send audio files if determined speech is present,
# gasps in speech are okay to keep as they help with prosody,
# but since this will be always running we need to not waste money
# and only send conversations to the external models
app.include_router(whisper_tts.router)  # FAL - Whisper TTS Router

# Hume Prosody Router
app.include_router(prosody.router)

# Claude/OpenAI/Gemini LLM Router
# Prefix for versioning API calls, so they are properly routed under /api/v1
app.include_router(claude_router, prefix="/api/v1")

# Claude/OpenAI/Gemini
# Auth/DB: Authentication and Database
# TODO: Add more detailed integrations, perhaps with platforms, devices
# Integrations: platforms, devices
# TODO: Embed contacts, other segments of data shared between device and here
# Possibly add features to communicate between multiple connected devices

# ChatGPT/GPT Integration to DB/Auth to browse further?
# TODO: Look into leveraging GPT's capabilities to connect with the database/auth system

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
