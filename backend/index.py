# File: backend/index.py **DO NOT OMIT ANYTHING FROM THE FOLLOWING CONTENT, INCLUDING & NOT LIMITED TO COMMENTED NOTES

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import get_swagger_ui_html  # Import Swagger UI
from routers.socket import ping, whisper_tts
from routers.post.llm_inference.claude import router as claude_router
from routers.humeclient import router as hume_router
from routers.post.embeddingRouter.index import router as embeddings_router  # Embeddings import
# from routers.post.image_generation.FLUXLORAFAL import router as fluxlora_router  # Disabled import
from routers.post.image_generation.fast_sdxl import router as sdxl_router  # Fast-SDXL model router
# from routers.post.getChatGPTShareChat.index import router as chatgpt_router  # Disabled ChatGPT router
from routers.post.diarizationRouter.index import router as diarization_router  # Diarization router
from routers.post.llm_inference.openai_post import router as openai_router  # OpenAI (GPT-4o-mini) router
from routers.post.getChatGPTShareChat.index import router as share_oai_chats_router
import ngrok  # Ngrok integration
from utils.serverManager import ServerManager  # Server manager utility
from dotenv import load_dotenv  # Load environment variables from .env
import os
import socket
import subprocess
import signal

# ------------------ Load Environment Variables --------------------
# Load the .env file to read configurations like PORT, NGROK_AUTH, etc.
load_dotenv()

# Flag to toggle Ngrok usage
USE_NGROK = True  # Enable Ngrok by default, can be toggled

# ------------------ FastAPI App Configuration ---------------------
# Create the FastAPI app instance with essential metadata
app = FastAPI(
    title="IRL Backend Service",
    description="A FastAPI backend acting as a proxy to leading AI models.",
    version="0.0.1",
    openapi_url="/openapi.json",  # OpenAPI schema URL
    docs_url=None,  # Disable default docs UI
    redoc_url=None  # Disable default ReDoc UI
)

# ------------------ CORS Middleware -------------------------------
# Add CORS support to allow cross-origin requests from any domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow requests from all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)

# ------------------ API Routes -------------------------------------
# Socket-based routes (ping, whisper-tts)
app.include_router(ping.router)  # Ping route for WebSocket health check
app.include_router(whisper_tts.router)  # Whisper TTS WebSocket route

# Claude/OpenAI LLM routes
app.include_router(claude_router, prefix="/v3/claude")  # LLM inference (Claude)

# Hume AI route (speech prosody, emotional analysis)
app.include_router(hume_router, prefix="/api/v1/hume")

# Embeddings route (vectorization for NLP tasks)
app.include_router(embeddings_router, prefix="/embeddings")

# Image generation routes
# app.include_router(fluxlora_router, prefix="/api")  # Disabled: FluxLora model
app.include_router(sdxl_router, prefix="/api")  # Fast-SDXL image generation

# OpenAI GPT model routes (GPT-4o-mini, configurable models)
app.include_router(openai_router, prefix="/LLM")

# Diarization route (speaker separation)
app.include_router(diarization_router, prefix="/api")

# ChatGPT share conversation route
app.include_router(share_oai_chats_router, prefix="/api/chatgpt")  # New route for ChatGPT share conversations


# ------------------ OpenAPI & Swagger UI ---------------------------
# Serve the OpenAPI schema separately
@app.get("/openapi.json", include_in_schema=False)
async def get_openapi():
    return app.openapi()

# Serve Swagger UI at /api/docs
@app.get("/api/docs", include_in_schema=False)
async def custom_swagger_ui():
    return get_swagger_ui_html(
        openapi_url="/openapi.json",
        title="IRL Backend Service API Docs",
        swagger_favicon_url="https://fastapi.tiangolo.com/img/favicon.png"  # Optional custom favicon
    )

# ------------------ Main Program Entry Point -----------------------
if __name__ == "__main__":
    import uvicorn

    # Get the port from environment or use default 9090
    PORT = int(os.getenv("PORT", 9090))

    # Initialize the ServerManager for handling the port
    server_manager = ServerManager(port=PORT)

    # Attempt to kill any process using the same port before launching
    try:
        server_manager.find_and_kill_process()
    except Exception as e:
        print(f"ServerManager Error: {e}")
        exit(1)  # Terminate if port cannot be freed

    # ------------------ Ngrok Setup (Optional) ---------------------
    # If Ngrok is enabled, establish an HTTP tunnel
    if USE_NGROK:
        try:
            listener = ngrok.forward(f"http://localhost:{PORT}", authtoken=os.getenv("NGROK_AUTHTOKEN"))
            print(f"Ingress established at: {listener.url()}")
        except Exception as e:
            print(f"Ngrok Error: {e}")
            exit(1)  # Terminate if Ngrok fails

    # ------------------ Start the Uvicorn Server -------------------
    # Launch the FastAPI app using Uvicorn ASGI server
    try:
        uvicorn.run(app, host="0.0.0.0", port=PORT)  # Bind to all IPs on port 9090 (default)
    except Exception as e:
        print(f"Failed to start the server: {e}")
