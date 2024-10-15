# backend/services/falWhisperv3Transcription.py
import os
import time
import fal_client
from typing import Dict, Any
from dotenv import load_dotenv

# Load environment variables from a .env file if present
load_dotenv()

class TranscriptionError(Exception):
    """Custom exception for transcription-related errors."""
    pass

def set_fal_client_api_key():
    """
    Sets the API key for fal_client from the environment variable or uses a default.
    """
    fal_client.api_key = os.getenv('FAL_KEY') or 'your_api_key'
    if fal_client.api_key == 'your_api_key':
        print("Warning: Using default API key. Please set the FAL_KEY environment variable.")

def transcribe_audio(
    audio_url: str,
    task: str = "transcribe",
    language: str = "en",
    chunk_level: str = "segment",
    version: str = "3",
    max_retries: int = 30,
    retry_interval: int = 5
) -> Dict[str, Any]:
    """
    Transcribes an audio file using the Whisper model via the fal-client API.

    Args:
        audio_url (str): URL of the audio file to transcribe.
        task (str, optional): Task to perform ("transcribe" or "translate"). Defaults to "transcribe".
        language (str, optional): Language of the audio file. Defaults to "en".
        chunk_level (str, optional): Level of chunks to return. Defaults to "segment".
        version (str, optional): Model version to use. Defaults to "3".
        max_retries (int, optional): Maximum number of status checks. Defaults to 30.
        retry_interval (int, optional): Seconds between status checks. Defaults to 5.

    Returns:
        Dict[str, Any]: Transcription result containing 'text' and 'chunks'.

    Raises:
        TranscriptionError: If any step of the transcription process fails.
    """
    set_fal_client_api_key()

    try:
        # Submit the transcription request
        handler = fal_client.submit(
            "fal-ai/wizper",
            arguments={
                "audio_url": audio_url,
                "task": task,
                "language": language,
                "chunk_level": chunk_level,
                "version": version
            },
        )
        request_id = handler.request_id
        if not request_id:
            raise TranscriptionError("Failed to obtain request_id from submission.")
    except Exception as e:
        raise TranscriptionError(f"Error submitting transcription request: {e}")

    # Poll for status
    for attempt in range(max_retries):
        try:
            status_response = fal_client.status("fal-ai/wizper", request_id, with_logs=True)
            status = status_response.status

            if status == "completed":
                break
            elif status in ["failed", "error"]:
                raise TranscriptionError(f"Transcription failed with status: {status}")
            else:
                # Status is still in progress
                print(f"Transcription status: {status}. Retrying in {retry_interval} seconds...")
                time.sleep(retry_interval)
        except Exception as e:
            raise TranscriptionError(f"Error checking transcription status: {e}")
    else:
        raise TranscriptionError("Transcription request timed out.")

    # Fetch the result
    try:
        result = fal_client.result("fal-ai/wizper", request_id)
        if "text" not in result or "chunks" not in result:
            raise TranscriptionError("Transcription result is missing expected fields.")
        return {
            "text": result["text"],
            "chunks": result["chunks"]
        }
    except Exception as e:
        raise TranscriptionError(f"Error fetching transcription result: {e}")
