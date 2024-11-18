# File: backend/index.py **DO NOT OMIT ANYTHING FROM THE FOLLOWING CONTENT, INCLUDING & NOT LIMITED TO COMMENTED NOTES
# You can make an audio file available to Gemini in either of the following ways:\n\nUpload the audio file prior to making the prompt request.\nProvide the audio file as inline data to the prompt request.
import logging
import os
# TODO: need endpoint to have server update clients(nextjs website, swift apps) on the servers url and other constants
import ngrok
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.responses import JSONResponse
from database.device_registration import database
from route.whisper_socket import whisper_tts
from utils.server.middleware import setup_cors
from utils.server.ngrok_command import router as ngrok_commands_router
from utils.server.ngrok_utils import start_ngrok

# ------------------ Load Environment Variables --------------------
load_dotenv()
# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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

from route.dev import socket_ping
app.include_router(socket_ping.router)  # Ping route for WebSocket health check
app.include_router(whisper_tts.router)  # Whisper TTS WebSocket route

# Post
from route.text_response.llm_inference.claude import router as claude_router
app.include_router(claude_router, prefix="/v3/claude")
from route.humeclient import router as hume_router
app.include_router(hume_router, prefix="/api/v1/hume")  # Hume AI route (speech prosody, emotional analysis)
from route.text_response.embedding.index import router as embeddings_router
app.include_router(embeddings_router, prefix="/text/embeddings")  # , prefix="/embeddings")
from route.image_generation.fast_sdxl import router as sdxl_router 
app.include_router(sdxl_router, prefix="/image/generation")  # Fast-SDXL image generation
from route.text_response.llm_inference.OpenAIRoute import router as openai_router
app.include_router(openai_router, prefix="/text/response")
from route.text_response.chatgpt_share.index import router as share_oai_chats_router
app.include_router(share_oai_chats_router, prefix="/retrieve/externalchats")  # route for ChatGPT share conversations; i.e. existing chatgpt shared chats
# app.include_router(ngrok_commands_router, prefix="/ngrok")


### ----------------------------------------------------------------------
##      NEXT.JS SITE
from route.website_services.waitlist_router import router as web_waitlist_crud_router
app.include_router(web_waitlist_crud_router) # CRUD backend/data/waitlist_data.db

### -----------------------------------------------------------------------
##      ONBOARDING (NO-AUTH)
from route.gemini.user_name_upload_v3 import router as user_name_upload_v3_router
app.include_router(user_name_upload_v3_router, prefix="/onboarding/v3")   # + /process-audio; TODO: on client side implement double-try correct user name
from route.gemini.user_name_upload_v5 import router as user_name_upload_v5_router
app.include_router(user_name_upload_v5_router, prefix="/onboarding/v5")   # + /process-audio; TODO: on client side implement double-try correct user name
from route.gemini.gemini_audio_handling_preview import router as gemini_audio_handling_router
app.include_router(gemini_audio_handling_router, prefix="/onboarding/v6")
from route.gemini.gemini_audio_handling_v3 import router as gemini_audio_handling_v3_router
app.include_router(gemini_audio_handling_v3_router, prefix="/onboarding/v8")


from route.gemini.truth_n_lie_v1 import router as analyze_truth_lie_v1_router
app.include_router(analyze_truth_lie_v1_router)

# TODO: one-liner & Day in the life Q's
# -------------------------------------------------------------------------
## Auth 
from route.device.device_registration import router as device_registration_router

app.include_router(device_registration_router, prefix="/v1/device") # CRUD backend/data/device_registration.db `http://server/v1/device/register/..`
from route.device.device_registration_v2 import router as device_registration_v2_router
app.include_router(device_registration_v2_router, prefix="/v2/device") # CRUD backend/data/device_registration.db `http://server/v2/device/register/..`
### ------------------------------------------------------------------------
##      GEMINI
# app.include_router(gemini_transcription_v1_router, prefix="/gemini")  # + add `/ws/transcribe`
from route.gemini.google_media_upload import router as google_media_upload_router
app.include_router(google_media_upload_router) # `https://server/upload-to-gemini`
from route.gemini.google_media_upload_v2 import router as google_media_upload_v2_router
app.include_router(google_media_upload_v2_router, prefix="/v2") # `https://server/v2/upload-to-gemini`
from route.gemini.google_media_upload_v3 import router as google_media_upload_v3_router
app.include_router(google_media_upload_v3_router, prefix="/v3")


# Event handlers for database connection
@app.on_event("startup")
async def startup():
    """
    Event handler for application startup. Connects to the database.
    """
    logger.info("Connecting to the database.")
    try:
        await database.connect()
        logger.info("Database connected successfully.")
    except Exception as e:
        logger.error(f"Error connecting to the database: {e}")
        raise

@app.on_event("shutdown")
async def shutdown():
    """
    Event handler for application shutdown. Disconnects from the database.
    """
    logger.info("Disconnecting from the database.")
    try:
        await database.disconnect()
        logger.info("Database disconnected successfully.")
    except Exception as e:
        logger.error(f"Error disconnecting from the database: {e}")

# ------------------ OpenAPI & Swagger UI ---------------------------
# Serve the OpenAPI schema separately
from utils.server.docs import router as server_docs_router
app.include_router(server_docs_router)



# ------------------ Main Program Entry Point -----------------------
if __name__ == "__main__":
    import uvicorn

    # Get the port from environment or use default 9090
    PORT = int(os.getenv("PORT", 9090))
    from utils.server.FindTerminateServerPIDs import FindTerminateServerPIDs # sees If port is open if so closes the port so the server can init

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
