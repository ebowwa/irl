# File: backend/route/post/geminiflash/gemini_socket.py
# **DO NOT OMIT ANYTHING FROM THE FOLLOWING CONTENT, INCLUDING & NOT LIMITED TO COMMENTED NOTES

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
import google.generativeai as genai
import base64
import json
import os
import pathlib
import logging
from utils.gemini_config import MODEL_VARIANTS, SUPPORTED_LANGUAGES, SUPPORTED_RESPONSE_MIME_TYPES

# Router and constants setup
router = APIRouter()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    raise ValueError("GOOGLE_API_KEY is not set in the environment variables.")
genai.configure(api_key=GOOGLE_API_KEY)

# Directories and logging setup
upload_dir = pathlib.Path("uploaded_audio")
upload_dir.mkdir(exist_ok=True)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Helper functions for file handling, API interaction, and validation

async def save_audio_file(base64_audio: str, filename: str) -> pathlib.Path:
    """
    Save the base64-encoded audio to a file.
    """
    audio_path = upload_dir / filename
    try:
        with open(audio_path, "wb") as audio_file:
            audio_file.write(base64.b64decode(base64_audio))
        return audio_path
    except Exception as e:
        raise HTTPException(status_code=500, detail=json.dumps({"error": f"Failed to save audio file: {e}"}))

def upload_to_genai(file_path: pathlib.Path, mime_type: str) -> str:
    """
    Upload the audio file to the Gemini API and get the file URI.
    """
    try:
        file_info = genai.upload_file(path=str(file_path), mime_type=mime_type)
        return file_info.uri
    except Exception as e:
        raise HTTPException(status_code=500, detail=json.dumps({"error": f"Failed to upload file to Gemini API: {e}"}))

def validate_model_name(model_name: str) -> None:
    """
    Validate the model name against supported variants.
    """
    if model_name not in MODEL_VARIANTS:
        raise HTTPException(status_code=400, detail=json.dumps({"error": f"Unsupported model variant. Supported models: {list(MODEL_VARIANTS.keys())}"}))

def validate_generation_config(generation_config: dict) -> str:
    """
    Validate the generation configuration, particularly the response MIME type.
    """
    response_mime_type = generation_config.get("response_mime_type", "text/plain")
    if response_mime_type not in SUPPORTED_RESPONSE_MIME_TYPES:
        raise HTTPException(status_code=400, detail=json.dumps({"error": f"Unsupported response MIME type. Supported types: {SUPPORTED_RESPONSE_MIME_TYPES}"}))
    return response_mime_type

async def handle_text_message(message: dict, conversation_history: list) -> None:
    """
    Handle incoming text message and update conversation history.
    """
    role = message.get("role")
    text = message.get("text")
    if role != "user" or not text:
        raise HTTPException(status_code=400, detail=json.dumps({"error": "Invalid message format. Expected 'role': 'user' and 'text': 'your message'."}))

    conversation_history.append({
        "role": "user",
        "parts": [{"text": text}]
    })

async def handle_audio_message(message: dict, conversation_history: list) -> None:
    """
    Handle incoming audio message, save the file, upload to Gemini, and update conversation history.
    """
    audio_base64 = message.get("audio")
    if not audio_base64:
        raise HTTPException(status_code=400, detail=json.dumps({"error": "Invalid audio message format."}))

    audio_path = await save_audio_file(audio_base64, "audio_message.wav")
    audio_file_uri = upload_to_genai(audio_path, mime_type="audio/wav")

    conversation_history.append({
        "role": "user",
        "parts": [{
            "file_data": {
                "mime_type": "audio/wav",
                "file_uri": audio_file_uri
            }
        }]
    })

async def generate_gemini_response(conversation_history: list, model_name: str, generation_config: dict, stream: bool) -> str:
    """
    Call the Gemini model to generate a response based on the conversation history.
    """
    gemini_model = genai.GenerativeModel(model_name=model_name)
    response = gemini_model.generate_content(
        contents=conversation_history,
        generation_config=generation_config,
        safety_settings={},
        stream=stream
    )
    return response.text

# Main WebSocket route for real-time chat
@router.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    await websocket.accept()
    conversation_history = []

    try:
        while True:
            try:
                data = await websocket.receive_text()
                message = json.loads(data)

                # Message handling (text/audio)
                if message.get("type") == "text":
                    await handle_text_message(message, conversation_history)
                elif message.get("type") == "audio":
                    await handle_audio_message(message, conversation_history)
                else:
                    await websocket.send_text(json.dumps({"error": "Unsupported message type."}))
                    continue

                # Validate model and configuration
                model_name = message.get("model_name", "gemini-1.5-flash")
                generation_config = message.get("generation_config", {
                    "temperature": 0.95,
                    "top_p": 0.9,
                    "max_output_tokens": 8192,
                    "candidate_count": 1,
                    "response_mime_type": "text/plain"
                })
                stream = message.get("stream", False)

                validate_model_name(model_name)
                validate_generation_config(generation_config)

                # Generate and send the model's response
                model_response_text = await generate_gemini_response(conversation_history, model_name, generation_config, stream)
                conversation_history.append({
                    "role": "model",
                    "parts": [{"text": model_response_text}]
                })

                await websocket.send_text(json.dumps({"response": model_response_text}))

            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({"error": "Invalid JSON format."}))
            except Exception as e:
                logger.error(f"Chat failed: {str(e)}", exc_info=True)
                await websocket.send_text(json.dumps({"error": f"Chat failed: {str(e)}"}))

    except WebSocketDisconnect:
        logger.info("WebSocket connection closed.")

# cd /Users/ebowwa/irl/backend/route/post/geminiflash
# python3 -m http.server 8000

# python '/Users/ebowwa/irl/backend/index.py'
