# File: main.py

from fastapi import FastAPI
from websocket.routers import ping, whisper_tts, hume
from websocket.routers.LLM.claude import router as claude_router

app = FastAPI()

app.include_router(ping.router) # Internal

# TODO: ON-CLIENT: only send audio files if determined speech is present, gasps in speech are okay to keep as they help with prosody, but since this will be always running we need to not waste money and only send conversations to the external models
app.include_router(whisper_tts.router) # FAL 
app.include_router(hume.router)
app.include_router(claude_router, prefix="/api/v1")
# Claude/OpenAI/Gemini
# Auth/DB
# Integrations - platforms, devices

# chatgpt gpt to the db/auth to browse further?

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)