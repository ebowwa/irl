# backend/route/features/gemini_transcription_v1.py

import os
import tempfile
import json
import re
import logging
import traceback
import socket
import time
from fastapi import APIRouter, UploadFile, File, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Any
from dotenv import load_dotenv
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

# Initialize FastAPI router
router = APIRouter(
    prefix="/transcribe",
    tags=["Transcription"],
    responses={404: {"description": "Not found"}},
)

# Retrieve and configure the Gemini API key
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise EnvironmentError("GOOGLE_API_KEY not set in environment variables.")

genai.configure(api_key=API_KEY)

# Define Pydantic models for response validation

class Timestamp(BaseModel):
    start: float
    end: float

class TranscriptionSegment(BaseModel):
    speaker: str
    timestamp: Timestamp
    transcription: str

class TranscriptionResponse(BaseModel):
    transcriptions: List[TranscriptionSegment]

# Define the JSON schema for the response configuration
response_schema = content.Schema(
    type=content.Type.ARRAY,
    items=content.Schema(
        type=content.Type.OBJECT,
        required=["timestamp", "speaker", "transcription"],
        properties={
            "timestamp": content.Schema(
                type=content.Type.OBJECT,
                required=["start", "end"],
                properties={
                    "start": content.Schema(type=content.Type.NUMBER),
                    "end": content.Schema(type=content.Type.NUMBER),
                },
            ),
            "speaker": content.Schema(type=content.Type.STRING),
            "transcription": content.Schema(type=content.Type.STRING),
        },
    ),
)

# Define the generation configuration
generation_config = {
    "temperature": 1,
    "top_p": 0.95,
    "top_k": 64,
    "max_output_tokens": 8192,
    "response_schema": response_schema,
    "response_mime_type": "application/json",
}

# Initialize the Generative Model with the specified configuration
model = genai.GenerativeModel(
    model_name="gemini-1.5-flash",
    generation_config=generation_config,
)

def upload_to_gemini(file_path: str, mime_type: str, retries: int = 3, backoff_factor: float = 2.0) -> Any:
    """
    Uploads the given file to Gemini with retry logic for handling timeouts.

    Args:
        file_path (str): Path to the file to upload.
        mime_type (str): MIME type of the file.
        retries (int): Number of retry attempts.
        backoff_factor (float): Factor by which the delay increases after each retry.

    Returns:
        Uploaded file object.

    Raises:
        Exception: If all retry attempts fail.
    """
    attempt = 0
    delay = 1  # Initial delay in seconds

    while attempt < retries:
        try:
            uploaded_file = genai.upload_file(file_path, mime_type=mime_type)
            logger.info(f"Uploaded file '{uploaded_file.display_name}' as: {uploaded_file.uri}")
            return uploaded_file
        except socket.timeout as e:
            attempt += 1
            logger.warning(f"Timeout during file upload (Attempt {attempt}/{retries}): {e}")
            if attempt < retries:
                logger.info(f"Retrying in {delay} seconds...")
                time.sleep(delay)
                delay *= backoff_factor
            else:
                logger.error("All retry attempts failed due to timeout.")
                raise HTTPException(
                    status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                    detail="Failed to upload file to Gemini API due to a timeout.",
                )
        except Exception as e:
            logger.error(f"Error uploading file to Gemini: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error uploading file to Gemini: {e}",
            )

def extract_json_from_response(response_text: str) -> dict:
    """
    Extracts JSON content from Gemini's response.

    Args:
        response_text (str): The raw response text from Gemini.

    Returns:
        dict: The extracted JSON object.

    Raises:
        HTTPException: If JSON cannot be extracted or parsed.
    """
    # Attempt to find JSON within code blocks (handles both objects and arrays)
    json_pattern = re.compile(r"```json\s*(\{.*?\}|\[.*?\])\s*```", re.DOTALL)
    match = json_pattern.search(response_text)
    if match:
        json_str = match.group(1)
    else:
        # If no code block, assume the entire response is JSON
        json_str = response_text

    try:
        return json.loads(json_str)
    except json.JSONDecodeError as e:
        logger.error(f"JSON decoding error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to decode JSON from Gemini API response: {e}",
        )

def serialize(obj):
    """
    Custom serializer for objects not serializable by default JSON code.

    Args:
        obj: The object to serialize.

    Returns:
        A serializable representation of the object.
    """
    if hasattr(obj, '__dict__'):
        return obj.__dict__
    elif isinstance(obj, list):
        return [serialize(item) for item in obj]
    elif hasattr(obj, 'uri'):
        return obj.uri
    else:
        return str(obj)

@router.post(
    "/",
    response_model=TranscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Upload an audio file for transcription and diarization.",
    description="Uploads an audio file to Gemini API and returns structured transcriptions with speaker information and timestamps.",
)
async def transcribe_audio(file: UploadFile = File(...)):
    """
    Endpoint to handle audio file uploads, process them with Gemini API, and return structured JSON transcriptions.

    - **file**: Audio file to be transcribed. Supported formats: WAV, MP3, AIFF, AAC, OGG Vorbis, FLAC.
    """
    supported_mime_types = [
        "audio/wav",
        "audio/mpeg",  
        "audio/aiff",
        "audio/aac",
        "audio/ogg",
        "audio/flac",
    ]

    if file.content_type not in supported_mime_types:
        logger.error(f"Unsupported file type: {file.content_type}")
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type: {file.content_type}. Supported types: {', '.join(supported_mime_types)}",
        )

    temp_file_path = None  # Initialize for cleanup in finally block
    try:
        # Save the uploaded file temporarily using tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name
            logger.info(f"File saved to temporary path: {temp_file_path}")
            logger.info(f"File size: {len(content)} bytes")

        # Check file size (e.g., limit to 50 MB)
        max_file_size = 50 * 1024 * 1024  # 50 MB
        if os.path.getsize(temp_file_path) > max_file_size:
            logger.error("File size exceeds the maximum allowed limit.")
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="File size exceeds the maximum allowed limit of 50 MB.",
            )

        # Upload the file to Gemini with retry logic
        uploaded_file = upload_to_gemini(temp_file_path, mime_type=file.content_type)

        # Define the chat prompt
        prompt_text = (
            "Generate audio diarization, including transcriptions and speaker information for each transcription, "
            "organized by the time they occurred. Aim for the cleanest transcription."
        )

        # Prepare the chat history
        chat_history = [
            {
                "role": "user",
                "parts": [
                    prompt_text,
                    uploaded_file,
                ],
            },
        ]

        logger.debug("Chat History:")
        logger.debug(json.dumps(chat_history, indent=2, default=serialize))

        # Start the chat session
        chat_session = model.start_chat(history=chat_history)

        # Send a message to trigger the diarization
        response = chat_session.send_message("Please provide the audio diarization for the uploaded file.")

        logger.info("Gemini API response received.")

        # Parse the response text to extract JSON
        response_text = response.text.strip()
        logger.debug(f"Gemini API response: {response_text}")

        transcriptions = extract_json_from_response(response_text)

        # Validate and structure the response using Pydantic models
        structured_transcriptions = []
        for segment in transcriptions:
            # Ensure all required fields are present
            if not all(k in segment for k in ("speaker", "timestamp", "transcription")):
                logger.error("Missing fields in transcription segment.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Missing fields in transcription segment.",
                )
            if not all(k in segment["timestamp"] for k in ("start", "end")):
                logger.error("Missing timestamp fields in transcription segment.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Missing timestamp fields in transcription segment.",
                )

            timestamp = Timestamp(start=segment["timestamp"]["start"], end=segment["timestamp"]["end"])
            transcription_segment = TranscriptionSegment(
                speaker=segment["speaker"],
                timestamp=timestamp,
                transcription=segment["transcription"],
            )
            structured_transcriptions.append(transcription_segment)

        return TranscriptionResponse(transcriptions=structured_transcriptions)

    except HTTPException as he:
        # Re-raise HTTP exceptions directly
        raise he
    except FileNotFoundError as fnf_error:
        logger.error(f"File not found error: {fnf_error}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(fnf_error))
    except json.JSONDecodeError as json_error:
        logger.error(f"JSON decode error: {json_error}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to parse JSON from Gemini API response.")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Internal Server Error: {e}")
    finally:
        # Clean up by removing the temporary audio file if it exists
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
                logger.info(f"Temporary file {temp_file_path} deleted.")
            except Exception as e:
                logger.error(f"Error deleting temporary file: {e}")
"""
curl -X POST "http://127.0.0.1:9090/transcribe/" \
  -H "accept: application/json" \
  -F "file=@/Users/ebowwa/Downloads/audio_file.ogg;type=audio/ogg"
"""

# Import WebSocket-related dependencies
from fastapi import WebSocket, WebSocketDisconnect

@router.websocket("/ws/transcribe")
async def websocket_transcribe(websocket: WebSocket):
    """
    WebSocket endpoint for live audio transcription and diarization.
    Expects an audio file as binary data through WebSocket messages.
    """
    await websocket.accept()
    try:
        # Loop to handle incoming data chunks or commands
        temp_file_path = None

        # Define supported mime types
        supported_mime_types = [
            "audio/wav",
            "audio/mpeg",
            "audio/aiff",
            "audio/aac",
            "audio/ogg",
            "audio/flac",
        ]

        # Receive and handle initial file metadata
        file_metadata = await websocket.receive_json()
        file_name = file_metadata.get("file_name", "audio_file.ogg")
        mime_type = file_metadata.get("mime_type", "audio/ogg")
        if mime_type not in supported_mime_types:
            await websocket.send_json({
                "error": f"Unsupported file type: {mime_type}. Supported types: {', '.join(supported_mime_types)}"
            })
            return

        # Save incoming binary data to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file_name)[1]) as temp_file:
            temp_file_path = temp_file.name
            while True:
                # Receive data chunks and write to file
                data = await websocket.receive_bytes()
                if not data:
                    break  # Stop if no more data is received
                temp_file.write(data)

        # File saved, proceed to upload and process it
        uploaded_file = upload_to_gemini(temp_file_path, mime_type=mime_type)

        # Prepare chat prompt and initiate chat session
        prompt_text = (
            "Generate audio diarization, including transcriptions and speaker information for each transcription, "
            "organized by the time they occurred. Aim for the cleanest transcription."
        )
        chat_history = [
            {
                "role": "user",
                "parts": [
                    prompt_text,
                    uploaded_file,
                ],
            },
        ]

        chat_session = model.start_chat(history=chat_history)
        response = chat_session.send_message("Please provide the audio diarization for the uploaded file.")
        response_text = response.text.strip()

        # Extract and parse the JSON transcription response
        transcriptions = extract_json_from_response(response_text)
        structured_transcriptions = []
        for segment in transcriptions:
            timestamp = Timestamp(start=segment["timestamp"]["start"], end=segment["timestamp"]["end"])
            transcription_segment = TranscriptionSegment(
                speaker=segment["speaker"],
                timestamp=timestamp,
                transcription=segment["transcription"],
            )
            structured_transcriptions.append(transcription_segment)

        # Send transcription results back through WebSocket
        await websocket.send_json({
            "status": "complete",
            "transcriptions": [transcription_segment.dict() for transcription_segment in structured_transcriptions]
        })

    except WebSocketDisconnect:
        logger.info("WebSocket connection closed by client.")
    except Exception as e:
        logger.error(f"Error during WebSocket transcription: {e}")
        await websocket.send_json({
            "error": f"Internal Server Error: {e}"
        })
    finally:
        # Clean up the temporary file
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
                logger.info(f"Temporary file {temp_file_path} deleted.")
            except Exception as e:
                logger.error(f"Error deleting temporary file: {e}")
