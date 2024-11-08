# File: backend/route/post/geminiflash/gemini_socket.py
# **DO NOT OMIT ANYTHING FROM THE FOLLOWING CONTENT, INCLUDING & NOT LIMITED TO COMMENTED NOTES

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
import google.generativeai as genai
import json
import pathlib
import base64
import os
import logging
from services.geminiService import generate_content, configure_gemini
from utils.gemini_config import MODEL_VARIANTS, SUPPORTED_RESPONSE_MIME_TYPES

# 1. Initialize the Gemini service
configure_gemini()

# 2. Initialize the API router
router = APIRouter()

# 3. Setup directories and logging
upload_dir = pathlib.Path("uploaded_audio")
upload_dir.mkdir(exist_ok=True)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 4. Helper function to save audio files
async def save_audio_file(base64_audio: str, filename: str) -> pathlib.Path:
    """
    Save the base64-encoded audio to a file.
    
    Args:
        base64_audio (str): The base64-encoded audio string.
        filename (str): The name of the file to save.
    
    Returns:
        pathlib.Path: The path to the saved audio file.
    """
    audio_path = upload_dir / filename
    try:
        with open(audio_path, "wb") as audio_file:
            audio_file.write(base64.b64decode(base64_audio))
        return audio_path
    except Exception as e:
        raise HTTPException(status_code=500, detail=json.dumps({"error": f"Failed to save audio file: {e}"}))

# 5. Helper function to upload files to Gemini API
def upload_to_genai(file_path: pathlib.Path, mime_type: str) -> str:
    """
    Upload the audio file to the Gemini API and get the file URI.
    
    Args:
        file_path (pathlib.Path): The path to the audio file.
        mime_type (str): The MIME type of the audio file.
    
    Returns:
        str: The URI of the uploaded file.
    """
    try:
        file_info = genai.upload_file(path=str(file_path), mime_type=mime_type)
        return file_info.uri
    except Exception as e:
        raise HTTPException(status_code=500, detail=json.dumps({"error": f"Failed to upload file to Gemini API: {e}"}))

# 6. WebSocket route for real-time chat
@router.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    # 6.1. Accept the WebSocket connection
    await websocket.accept()
    conversation_history = []

    try:
        while True:
            try:
                # 6.2. Receive data from the WebSocket
                data = await websocket.receive_text()
                message = json.loads(data)

                # 6.3. Handle different message types (text/audio)
                if message.get("type") == "text":
                    role = message.get("role")
                    text = message.get("text")
                    if role != "user" or not text:
                        await websocket.send_text(json.dumps({"error": "Invalid message format. Expected 'role': 'user' and 'text': 'your message'."}))
                        continue
                    conversation_history.append({
                        "role": "user",
                        "parts": [{"text": text}]
                    })
                elif message.get("type") == "audio":
                    audio_base64 = message.get("audio")
                    if not audio_base64:
                        await websocket.send_text(json.dumps({"error": "Invalid audio message format."}))
                        continue
                    # 6.4. Save the audio file
                    audio_path = await save_audio_file(audio_base64, "audio_message.wav")
                    # 6.5. Upload the audio file to Gemini API
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
                else:
                    await websocket.send_text(json.dumps({"error": "Unsupported message type."}))
                    continue

                # 6.6. Extract model name and generation configuration
                model_name = message.get("model_name", "gemini-1.5-flash")
                generation_config = message.get("generation_config", {
                    "temperature": 0.95,
                    "top_p": 0.9,
                    "max_output_tokens": 8192,
                    "candidate_count": 1,
                    "response_mime_type": "text/plain"
                })
                stream = message.get("stream", False)

                # 6.7. Validate the model name and generation configuration
                if model_name not in MODEL_VARIANTS:
                    await websocket.send_text(json.dumps({"error": f"Unsupported model variant. Supported models: {list(MODEL_VARIANTS.keys())}"}))
                    continue
                response_mime_type = generation_config.get("response_mime_type", "text/plain")
                if response_mime_type not in SUPPORTED_RESPONSE_MIME_TYPES:
                    await websocket.send_text(json.dumps({"error": f"Unsupported response MIME type. Supported types: {SUPPORTED_RESPONSE_MIME_TYPES}"}))
                    continue

                # 6.8. Generate the model's response using the service
                try:
                    response = generate_content(
                        model=model_name,
                        contents=conversation_history,
                        config=generation_config,
                        safety_settings={},
                        stream=stream
                    )
                    # 6.9. Append the model's response to the conversation history
                    conversation_history.append({
                        "role": "model",
                        "parts": [{"text": response.text}]
                    })
                    # 6.10. Send the response back to the client
                    await websocket.send_text(json.dumps({"response": response.text}))
                except Exception as e:
                    logger.error(f"Generation failed: {str(e)}")
                    await websocket.send_text(json.dumps({"error": f"Generation failed: {str(e)}"}))

            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({"error": "Invalid JSON format."}))
            except Exception as e:
                logger.error(f"Chat failed: {str(e)}", exc_info=True)
                await websocket.send_text(json.dumps({"error": f"Chat failed: {str(e)}"}))

    except WebSocketDisconnect:
        logger.info("WebSocket connection closed.")
