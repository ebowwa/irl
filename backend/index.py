# File: backend/index.py **DO NOT OMIT ANYTHING FROM THE FOLLOWING CONTENT, INCLUDING & NOT LIMITED TO COMMENTED NOTES
# You can make an audio file available to Gemini in either of the following ways:\n\nUpload the audio file prior to making the prompt request.\nProvide the audio file as inline data to the prompt request.
import logging
import os
# TODO: need some way to have server update clients(nextjs website, swift apps) on the servers url and other constants
import ngrok
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.responses import JSONResponse
from route.dev import socket_ping
# from route.post.audio.transcription.falIndex import router as transcription_router removed to use gemini
from route.features.gemini.gemini_post_v1 import router as gemini_router
from route.features.gemini.gemini_post_v1B import router as gemini_v1B_router
# from route.features.gemini.gemini_post_v2 import router as gemini_post_v2_router
from route.features.gemini.gemini_postv3 import router as gemini_post_v3_router
from route.features.gemini.gemini_socket import router as gemini_socket_router
from route.features.gemini.gemini_transcription_v1 import router as gemini_transcription_v1_router
from route.features.gemini.truth_n_lie_v1 import router as analyze_truth_lie_v1_router
from route.features.gemini.user_name_upload_v1 import router as user_name_upload_v1_router
from route.features.gemini.user_name_upload_v2 import router as user_name_upload_v2_router
from route.features.gemini.user_name_upload_v3 import router as user_name_upload_v3_router
from route.features.gemini.user_name_upload_v4 import router as user_name_upload_v4_router
from route.features.gemini.user_name_upload_v5 import router as user_name_upload_v5_router
from route.features.gemini.user_name_upload_v6 import router as user_name_upload_v6_router
from route.features.gemini.google_media_upload import router as google_media_upload_router
from route.features.humeclient import router as hume_router
from route.features.gemini.google_media_upload_v2 import router as google_media_upload_v2_router
from route.features.gemini.google_media_upload_v3 import router as google_media_upload_v3_router
from route.features.image_generation.fast_sdxl import router as sdxl_router 
from route.features.text.chatgpt_share.index import router as share_oai_chats_router
from route.features.text.embedding.index import router as embeddings_router
from route.features.text.llm_inference.claude import router as claude_router
from route.features.text.llm_inference.OpenAIRoute import router as openai_router
from route.features.unzip_audiobatch import router as unzip_audio_batch_v1_router
from route.features.whisper_socket import whisper_tts
from route.website_services.waitlist_router import router as web_waitlist_crud_router
from route.features.device_registration import router as device_registration_router
from utils.server.FindTerminateServerPIDs import FindTerminateServerPIDs # sees If port is open if so closes the port so the server can init
from utils.server.middleware import setup_cors
from utils.server.ngrok_command import router as ngrok_commands_router
from utils.server.ngrok_utils import start_ngrok

# ------------------ Load Environment Variables --------------------
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
    redoc_url=None,  # Disable default ReDoc UI
)

# ------------------ Middleware Setup ------------------------------

setup_cors(app)

# ------------------ API Routes -------------------------------------

##      EXTERNAL SERVICES (OLD TBD INTEGRATION)
# Socket-based routes (ping, whisper-tts)
app.include_router(socket_ping.router)  # Ping route for WebSocket health check
app.include_router(whisper_tts.router)  # Whisper TTS WebSocket route
# Post
app.include_router(claude_router, prefix="/v3/claude")
app.include_router(hume_router, prefix="/api/v1/hume")  # Hume AI route (speech prosody, emotional analysis)
app.include_router(embeddings_router, prefix="/text/embeddings")  # , prefix="/embeddings")
app.include_router(sdxl_router, prefix="/image/generation")  # Fast-SDXL image generation
app.include_router(openai_router, prefix="/text/response")
app.include_router(share_oai_chats_router, prefix="/retrieve/externalchats")  # route for ChatGPT share conversations; i.e. existing chatgpt shared chats
# app.include_router(ngrok_commands_router, prefix="/ngrok")


### ----------------------------------------------------------------------
##      NEXT.JS SITEß
app.include_router(web_waitlist_crud_router) # CRUD backend/data/waitlist_data.db

### -----------------------------------------------------------------------
##      ONBOARDING (NO-AUTH)
app.include_router(user_name_upload_v3_router, prefix="/onboarding/v3")  # + /process-audio; TODO: on client side implement double-try correct user name
app.include_router(user_name_upload_v4_router, prefix="/onboarding/v4")  # + /process-audio; TODO: on client side implement double-try correct user name
app.include_router(user_name_upload_v5_router, prefix="/onboarding/v5") 
app.include_router(user_name_upload_v6_router, prefix="/onboarding/v6")
app.include_router(analyze_truth_lie_v1_router)
# TODO: one-liner & Day in the life Q's
# -------------------------------------------------------------------------
## Auth 
app.include_router(device_registration_router, prefix="/device") # CRUD backend/data/device_registration.db `http://server/register/..`

### ------------------------------------------------------------------------
##      GEMINI
app.include_router(gemini_router, prefix="/v1/post/gemini")
app.include_router(gemini_v1B_router, prefix="/v1B/post/gemini")

# app.include_router(gemini_post_v2_router, prefix="/v2/post/gemini")
app.include_router(gemini_socket_router, prefix="/socket/gemini")
app.include_router(gemini_transcription_v1_router, prefix="/gemini")  # + add `/ws/transcribe`
app.include_router(google_media_upload_router) # `https://server/upload-to-gemini`
app.include_router(google_media_upload_v2_router, prefix="/v2") # `https://server/v2/upload-to-gemini`
app.include_router(google_media_upload_v3_router, prefix="/v3")
app.include_router(gemini_post_v3_router, prefix="/v3") 


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
        title="caringmind api docs",
        swagger_favicon_url="https://fastapi.tiangolo.com/img/favicon.png",  # Optional custom favicon
    )


# ------------------ Main Program Entry Point -----------------------
if __name__ == "__main__":
    import uvicorn

    # Get the port from environment or use default 9090
    PORT = int(os.getenv("PORT", 9090))

    # Initialize the ServerManager for handling the port
    server_manager = FindTerminateServerPIDs(port=PORT)

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


# each user main app should have a uuid, we want to be able to verify the device in the server with it in the case we handle monetization outside the perview of apple
