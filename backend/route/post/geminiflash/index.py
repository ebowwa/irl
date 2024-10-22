# File: route/post/gemini.py

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from typing import List, Optional
import google.generativeai as genai
import os
import json
import pathlib
import mimetypes
import aiofiles
from dotenv import load_dotenv

# ------------------ Load Environment Variables --------------------
load_dotenv()

# ------------------ Initialize Router ------------------------------
router = APIRouter(
    tags=["Gemini Models"],
    # No prefix here
    responses={401: {"description": "Unauthorized"}}
)

# ------------------ Configure the GenAI Client ----------------------
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    raise ValueError("GOOGLE_API_KEY is not set in the environment variables.")
genai.configure(api_key=GOOGLE_API_KEY)

# ------------------ Supported Model Variants ------------------------
MODEL_VARIANTS = {
    "gemini-1.5-flash": {
        "description": "Fast and versatile performance across a diverse variety of tasks",
        "inputs": ["audio", "images", "videos", "text"],
        "optimized_for": "Most balanced multimodal tasks balancing performance and cost"
    },
    "gemini-1.5-flash-8b": {
        "description": "High volume and lower intelligence tasks",
        "inputs": ["audio", "images", "videos", "text"],
        "optimized_for": "Lower intelligence, high-frequency tasks"
    },
    "gemini-1.5-pro": {
        "description": "Features for a wide variety of reasoning tasks",
        "inputs": ["audio", "images", "videos", "text"],
        "optimized_for": "Complex reasoning tasks requiring more intelligence"
    },
    "gemini-1.0-pro": {
        "description": "Natural language tasks, multi-turn text and code chat, and code generation",
        "inputs": ["text"],
        "optimized_for": "Natural language and code-related tasks"
    },
    "text-embedding-004": {
        "description": "Measuring the relatedness of text strings",
        "inputs": ["text"],
        "optimized_for": "Text embeddings"
    },
    "aqa": {
        "description": "Providing source-grounded answers to questions",
        "inputs": ["text"],
        "optimized_for": "Question answering"
    }
}

# ------------------ Supported Languages -----------------------------
SUPPORTED_LANGUAGES = [
    "ar", "bn", "bg", "zh", "hr", "cs", "da", "nl", "en", "et", "fi",
    "fr", "de", "el", "iw", "hi", "hu", "id", "it", "ja", "ko", "lv",
    "lt", "no", "pl", "pt", "ro", "ru", "sr", "sk", "sl", "es", "sw",
    "sv", "th", "tr", "uk", "vi"
]

# ------------------ Utility Functions -------------------------------

async def save_upload_file(upload_file: UploadFile, destination: pathlib.Path):
    try:
        async with aiofiles.open(destination, 'wb') as out_file:
            while content := await upload_file.read(1024):  # Read in chunks
                await out_file.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save file: {e}")

def upload_to_genai(file_path: pathlib.Path, mime_type: str) -> str:
    try:
        file_info = genai.upload_file(path=str(file_path), mime_type=mime_type)
        return file_info.uri
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to upload file to Gemini API: {e}")

def get_mime_type(filename: str) -> str:
    mime_type, _ = mimetypes.guess_type(filename)
    if not mime_type:
        raise HTTPException(status_code=400, detail="Could not determine the MIME type of the file.")
    return mime_type

# ------------------ API Endpoints -------------------------------------

@router.post("/generate", summary="Generate Content")
async def generate_content(
    model: str = Form(..., description="Model variant to use", example="gemini-1.5-pro"),
    text: Optional[str] = Form(None, description="Input text prompt"),
    language: Optional[str] = Form("en", description="Language code", example="en"),
    candidate_count: int = Form(1, description="Number of candidate responses", ge=1, le=5),
    max_output_tokens: int = Form(500, description="Maximum number of tokens in the output", ge=1, le=8192),
    temperature: float = Form(0.95, description="Sampling temperature", ge=0.0, le=2.0),
    top_p: float = Form(0.9, description="Nucleus sampling parameter", ge=0.0, le=1.0),
    send_files: Optional[List[UploadFile]] = File(None, description="Files to send"),
    audio_files: Optional[List[UploadFile]] = File(None, description="Audio files"),
    image_files: Optional[List[UploadFile]] = File(None, description="Image files"),
    video_files: Optional[List[UploadFile]] = File(None, description="Video files")
):
    """
    Generate content using Gemini models. Supports text, audio, images, and video inputs.
    """
    if model not in MODEL_VARIANTS:
        raise HTTPException(status_code=400, detail=f"Unsupported model variant. Supported models: {list(MODEL_VARIANTS.keys())}")

    if language not in SUPPORTED_LANGUAGES:
        raise HTTPException(status_code=400, detail=f"Unsupported language. Supported languages: {SUPPORTED_LANGUAGES}")

    # Prepare contents
    contents = []
    if text:
        contents.append({
            "role": "user",
            "parts": [{"text": text}]
        })

    # Handle file uploads
    upload_dir = pathlib.Path("uploaded_files")
    upload_dir.mkdir(exist_ok=True)

    async def handle_files(files: Optional[List[UploadFile]], file_type: str):
        for file in files or []:
            destination = upload_dir / file.filename
            await save_upload_file(file, destination)
            mime_type = get_mime_type(file.filename)
            file_uri = upload_to_genai(destination, mime_type)
            contents.append({
                "role": "user",
                "parts": [{
                    "file_data": {
                        "mime_type": mime_type,
                        "file_uri": file_uri
                    }
                }]
            })

    await handle_files(send_files, "send")
    await handle_files(audio_files, "audio")
    await handle_files(image_files, "image")
    await handle_files(video_files, "video")

    # Generation configuration
    generation_config = {
        "temperature": temperature,
        "top_p": top_p,
        "max_output_tokens": max_output_tokens,
        "candidate_count": candidate_count,
        "response_mime_type": "application/json" # additionally available 'text/plain' and 'enum
    }

    # Safety settings (empty for this example, customize as needed)
    safety_settings = {}

    try:
        # Initialize the generative model
        gemini_model = genai.GenerativeModel(model_name=model)

        # Call the model to generate content
        response = gemini_model.generate_content(
            contents=contents,
            generation_config=generation_config,
            safety_settings=safety_settings,
            stream=False
        )

        # Prepare the response
        if candidate_count == 1:
            return {"response": response.text}
        else:
            return {"responses": [candidate.text for candidate in response.candidates]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {e}")

@router.post("/chat", summary="Chat Session")
async def chat_session(
    model: str = Form(..., description="Model variant to use", example="gemini-1.5-pro"),
    messages: str = Form(..., description="Conversation history in JSON format"),
    temperature: float = Form(0.95, description="Sampling temperature", ge=0.0, le=2.0),
    top_p: float = Form(0.9, description="Nucleus sampling parameter", ge=0.0, le=1.0)
):
    """
    Create or continue a chat session with the Gemini model.
    """
    if model not in MODEL_VARIANTS:
        raise HTTPException(status_code=400, detail=f"Unsupported model variant. Supported models: {list(MODEL_VARIANTS.keys())}")

    try:
        conversation = json.loads(messages)
        if not isinstance(conversation, list):
            raise ValueError("Messages must be a list of message objects.")

        # Determine whose turn it is
        model_turn = conversation[-1].get("role", "").lower() == "user"

        # Initialize the generative model
        gemini_model = genai.GenerativeModel(model_name=model)

        if model_turn:
            # User was last, send the last message
            chat = gemini_model.start_chat(history=conversation[:-1])
            last_message = conversation[-1]["parts"][0].get("text", "")
            response = chat.send_message(last_message)
        else:
            # Model was last, continue the conversation
            chat = gemini_model.start_chat(history=conversation)
            response = chat.send_message("")

        return {"response": response.text}
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON format for messages.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat session failed: {e}")

@router.post("/upload", summary="Upload File")
async def upload_file_endpoint(
    file: UploadFile = File(..., description="File to upload"),
    description: Optional[str] = Form(None, description="Description of the file")
):
    """
    Upload a file to the Files API and retrieve its URI.
    """
    upload_dir = pathlib.Path("uploaded_files")
    upload_dir.mkdir(exist_ok=True)
    destination = upload_dir / file.filename

    await save_upload_file(file, destination)

    mime_type = get_mime_type(file.filename)
    file_uri = upload_to_genai(destination, mime_type)

    return {
        "file_uri": file_uri,
        "filename": file.filename,
        "mime_type": mime_type,
        "description": description
    }

@router.get("/models", summary="List Models")
async def list_models():
    """
    List all available Gemini model variants.
    """
    return {"models": MODEL_VARIANTS}

@router.get("/languages", summary="List Supported Languages")
async def list_languages():
    """
    List all supported languages.
    """
    return {"languages": SUPPORTED_LANGUAGES}

