# File: backend/index.py **DO NOT OMIT ANYTHING FROM THE FOLLOWING CONTENT, INCLUDING & NOT LIMITED TO COMMENTED NOTES

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import get_swagger_ui_html  
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
import logging
from route.dev import socket_ping
from route.features.whisper_socket import whisper_tts
from route.features.text.llm_inference.claude import router as claude_router
from route.features.humeclient import router as hume_router
from route.features.text.embedding.index import router as embeddings_router
from route.features.image_generation.fast_sdxl import router as sdxl_router  # Fast-SDXL model 
from route.features.text.llm_inference.OpenAIRoute import router as openai_router
from route.features.text.chatgpt_share.index import router as share_oai_chats_router
# from route.post.audio.transcription.falIndex import router as transcription_router removed to use gemini
from route.features.gemini_flash_series.gemini_index import router as gemini_router
from services.gemini_socket import router as gemini_socket_router
from route.features.user_name_upload_v1 import router as user_name_upload_v1_router
from route.features.user_name_upload_v2 import router as user_name_upload_v2_router
from route.features.user_name_upload_v3 import router as user_name_upload_v3_router
from route.features.unzip_audiobatch import router as unzip_audio_batch_v1_router
from route.features.truth_n_lie_v1 import router as analyze_truth_lie_v1_router
from utils.ngrok_utils import start_ngrok
import ngrok 
from utils.server_manager import ServerManager  # sees If port is open if so closes the port so the server can init
from dotenv import load_dotenv 
import os


# ------------------ Load Environment Variables --------------------
# Load the .env file to read configurations like PORT, NGROK_AUTH, etc.
load_dotenv()

# Flag to toggle Ngrok usage
USE_NGROK = True  # Enable Ngrok by default, can be toggled

# ------------------ FastAPI App Configuration ---------------------
# Create the FastAPI app instance with essential metadata
app = FastAPI(
    title="Caring Mind Backend Service",
    description="an api into the information substrate",
    version="0.0.1",
    openapi_url="/openapi.json",  
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
app.include_router(socket_ping.router)  # Ping route for WebSocket health check
app.include_router(whisper_tts.router)  # Whisper TTS WebSocket route

app.include_router(claude_router, prefix="/v3/claude") 
app.include_router(hume_router, prefix="/api/v1/hume") # Hume AI route (speech prosody, emotional analysis)
app.include_router(embeddings_router, prefix="/text/embeddings") # , prefix="/embeddings")
# app.include_router(fluxlora_router, prefix="/api")  # Disabled: FluxLora model
app.include_router(sdxl_router, prefix="/image/generation")  # Fast-SDXL image generation
# app.include_router(transcription_router, prefix="/api",tags=["Transcription"]) 
# OpenAI GPT model routes (GPT-4o-mini, configurable models)
app.include_router(openai_router, prefix="/text/response")
# app.include_router(diarization_router, prefix="/api")

app.include_router(share_oai_chats_router, prefix="/retrieve/externalchats")  # route for ChatGPT share conversations; i.e. existing chatgpt shared chats

# app.include_router(media_router, prefix="/media") 

app.include_router(gemini_router, prefix="/post/gemini")  

app.include_router(gemini_socket_router, prefix="/socket/gemini")

app.include_router(user_name_upload_v1_router, prefix="/onboarding/v1") # + /process-audio
app.include_router(user_name_upload_v2_router, prefix="/onboarding/v2") 
app.include_router(user_name_upload_v3_router, prefix="/onboarding/v3") 
# double-try correct user name 
# one-liner & Day in the life Q's
# general diarization, transcription, otherwise route
# media upload should preserve for 1 day min with bucket?
# 
app.include_router(unzip_audio_batch_v1_router) # this is in test for handling zip batches from the client
app.include_router(analyze_truth_lie_v1_router)
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
            ngrok_url = start_ngrok(PORT)
        except Exception as e:
            print(f"Ngrok setup failed: {e}")
            exit(1)

    # ------------------ Start the Uvicorn Server -------------------
    try:
        uvicorn.run(app, host="0.0.0.0", port=PORT)
    except Exception as e:
        print(f"Failed to start the server: {e}")