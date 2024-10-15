# File: backend/index.py **DO NOT OMIT ANYTHING**

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import get_swagger_ui_html  # Import Swagger UI
from routers.socket import ping, whisper_tts
from routers.post.llm_inference.claude import router as claude_router
from routers.humeclient import router as hume_router
from routers.post.embeddingRouter.index import router as embeddings_router  # New import
# from routers.post.image_generation.FLUXLORAFAL import router as fluxlora_router  # New import
from routers.post.image_generation.fast_sdxl import router as sdxl_router  # New import for fast-sdxl model
# from routers.post.getChatGPTShareChat.index import router as chatgpt_router  # Import the new router
from routers.post.diarizationRouter.index import router as diarization_router
from dotenv import load_dotenv
import os
import socket
import subprocess
import signal

# Load environment variables from .env file
load_dotenv()

# New router for OpenAI API integration for GPT-4o-mini, dynamic models, and configuration
from routers.post.llm_inference.openai_post import router as openai_router  # Import the new route

# Ngrok integration
import ngrok

# Import ServerManager from utils
from utils.serverManager import ServerManager

# Add boolean flag for Ngrok activation
USE_NGROK = True  # Set this to True by default, can be toggled later

app = FastAPI(
    title="IRL Backend Service",
    description="A FastAPI backend acting as a proxy to leading AI models.",
    version="0.0.1",
    openapi_url="/openapi.json",  # Default OpenAPI URL
    docs_url=None,  # Disable default docs
    redoc_url=None  # Disable default ReDoc
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

# Claude/OpenAI/Gemini LLM Router ** this is a post **
app.include_router(claude_router, prefix="/v3/claude")

# Hume AI Router ** this is a post, but websocket is available **
app.include_router(hume_router, prefix="/api/v1/hume")

# Embeddings Router ** this is a post **
app.include_router(embeddings_router, prefix="/embeddings")

# Image Generation Router ** new addition **
# app.include_router(fluxlora_router, prefix="/api")

# New router for fast-sdxl image generation
app.include_router(sdxl_router, prefix="/api")

# New route for OpenAI GPT models (including GPT-4o-mini)
app.include_router(openai_router, prefix="/LLM")

# Add the diarization route
app.include_router(diarization_router, prefix="/api")


# Serve OpenAPI schema at a separate route (optional, already available at /openapi.json)
@app.get("/openapi.json", include_in_schema=False)
async def get_openapi():
    return app.openapi()

# Serve the Swagger UI at /api/docs
@app.get("/api/docs", include_in_schema=False)
async def custom_swagger_ui():
    return get_swagger_ui_html(
        openapi_url="/openapi.json",
        title="IRL Backend Service API Docs",
        swagger_favicon_url="https://fastapi.tiangolo.com/img/favicon.png"  # Optional: Customize favicon
    )

if __name__ == "__main__":
    import uvicorn

    # Retrieve the port from environment variables or default to 9090
    PORT = int(os.getenv("PORT", 9090))

    # Initialize ServerManager with the specified port
    server_manager = ServerManager(port=PORT)
    try:
        server_manager.find_and_kill_process()
    except Exception as e:
        print(f"ServerManager Error: {e}")
        exit(1)  # Exit the script if the port cannot be freed

    # Start Ngrok if the flag is True
    if USE_NGROK:
        try:
            listener = ngrok.forward(f"http://localhost:{PORT}", authtoken=os.getenv("NGROK_AUTHTOKEN"))  # No authtoken required for now
            print(f"Ingress established at: {listener.url()}")
        except Exception as e:
            print(f"Ngrok Error: {e}")
            exit(1)  # Exit if Ngrok fails

    # Run the FastAPI server
    try:
        uvicorn.run(app, host="0.0.0.0", port=PORT)
    except Exception as e:
        print(f"Failed to start the server: {e}")
