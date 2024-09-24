# File: backend/index.py

# i have all these router functions that i intend to call with my app, im not sure that i want to log anything as provacy is important and all data will mostly be stored on client, but maybe i need to so this is my question!   
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers.websocket import ping, whisper_tts
from routers.post.llm_inference.claude import router as claude_router
from routers.humeclient import router as hume_router
from routers.post.embeddings.index import router as embeddings_router  # New import
from routers.post.image_generation.FLUXLORAFAL import router as fluxlora_router  # New import
from routers.post.image_generation.sdxl import router as sdxl_router  # New import for fast-sdxl model
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = FastAPI(
    title="IRL Backend Service",
    description="A FastAPI backend acting as a proxy to leading AI models.",
    version="0.0.1",
)
# Add CORS middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Internal: Ping Route for Status Checks ** this is a websocket ** 
app.include_router(ping.router)

# Whisper TTS Router ** this is a websocket ** 
app.include_router(whisper_tts.router)
# maybe need to set up a post

# Claude/OpenAI/Gemini LLM Router ** this is a post ** 
# TODO: ADD OPENROUTER would like access to the Nous Models
app.include_router(claude_router, prefix="/v3/claude")

# Hume AI Router ** this is a post, but websocket is available ** 
app.include_router(hume_router, prefix="/api/v1/hume")
# speech prosody

# Embeddings Router ** this is a post **
# small & large
app.include_router(embeddings_router, prefix="/embeddings")

# Image Generation Router ** new addition **
app.include_router(fluxlora_router, prefix="/api")

# New router for fast-sdxl image generation
app.include_router(sdxl_router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
