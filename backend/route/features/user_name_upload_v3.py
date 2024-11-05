# backend/route/features/user_name_upload_v3.py
# FastAPI router for processing audio using Google Gemini

import os
import tempfile
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content
import json
import traceback
from types import MappingProxyType
import logging
import re  # Added for regex operations

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 1. Load environment variables from .env
load_dotenv()

# 2. Initialize the FastAPI router
router = APIRouter()

# 3. Retrieve and configure the Gemini API key
google_api_key = os.getenv("GOOGLE_API_KEY")
if not google_api_key:
    raise EnvironmentError("GEMINI_API_KEY not found in environment variables.")

genai.configure(api_key=google_api_key)

def upload_to_gemini(file_path: str, mime_type: str = None):
    """
    Uploads the given file to Gemini.

    Args:
        file_path (str): Path to the file to upload.
        mime_type (str, optional): MIME type of the file. Defaults to None.

    Returns:
        Uploaded file object.
    """
    try:
        uploaded_file = genai.upload_file(file_path, mime_type=mime_type)
        logger.info(f"Uploaded file '{uploaded_file.display_name}' as: {uploaded_file.uri}")
        return uploaded_file  # Return the file object directly
    except Exception as e:
        logger.error(f"Error uploading file: {e}")
        raise

def serialize(obj):
    if isinstance(obj, MappingProxyType):
        return dict(obj)
    elif hasattr(obj, '__dict__'):
        return obj.__dict__
    elif isinstance(obj, list):
        return [serialize(item) for item in obj]
    else:
        return str(obj)

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
    # Attempt to find JSON within code blocks
    json_pattern = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL)
    match = json_pattern.search(response_text)
    if match:
        json_str = match.group(1)
        try:
            return json.loads(json_str)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decoding error: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to decode JSON: {e}")
    else:
        # If no code block, assume the entire response is JSON
        try:
            return json.loads(response_text)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decoding error: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to decode JSON: {e}")

@router.post("/process-audio")
async def process_audio(file: UploadFile = File(...)):
    """
    Endpoint to upload an audio file, process it with Gemini, and return the analysis.

    Args:
        file (UploadFile): The audio file to process.

    Returns:
        JSONResponse: The analysis result from Gemini.
    """
    # 4. Validate MIME type of the uploaded file
    supported_mime_types = [
        "audio/wav",
        "audio/mp3",
        "audio/aiff",
        "audio/aac",
        "audio/ogg",
        "audio/flac",
    ]
    if file.content_type not in supported_mime_types:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}",
        )

    try:
        # 5. Save the uploaded file temporarily on the server using tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            temp_file.write(await file.read())
            temp_file_path = temp_file.name

        # 6. Upload the file to Gemini and get the file object
        uploaded_file = upload_to_gemini(temp_file_path, mime_type=file.content_type)

        # 7. Define the updated generation configuration with the new JSON schema
        generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 64,
            "max_output_tokens": 8192,
            "response_schema": content.Schema(
                type=content.Type.OBJECT,
                required=[
                    "name",
                    "prosody",
                    "feeling",
                    "confidence_score",
                    "confidence_reasoning",
                    "psychoanalysis",
                    "location_background",
                ],
                properties={
                    "name": content.Schema(
                        type=content.Type.STRING,
                        description="The user's full name.",
                    ),
                    "prosody": content.Schema(
                        type=content.Type.STRING,
                        description="An analysis of the user's speech characteristics, including pronunciation and any noticeable inflections.",
                    ),
                    "feeling": content.Schema(
                        type=content.Type.STRING,
                        description="An interpretation of the user's emotional tone based on their speech pattern.",
                    ),
                    "confidence_score": content.Schema(
                        type=content.Type.INTEGER,
                        description="Confidence score out of 100 on the accuracy of hearing, understanding, and transcribing the user's name.",
                    ),
                    "confidence_reasoning": content.Schema(
                        type=content.Type.STRING,
                        description="Explanation for the assigned confidence score, detailing factors that influenced the level of confidence.",
                    ),
                    "psychoanalysis": content.Schema(
                        type=content.Type.STRING,
                        description="A deeper psychological interpretation of the user's speech delivery, tone, and context, providing insights into potential emotional or personality traits based on observed vocal patterns.",
                    ),
                    "location_background": content.Schema(
                        type=content.Type.STRING,
                        description="Details about the user's current environment or setting, focusing on any auditory or contextual factors that may influence the analysis of speech and prosody.",
                    ),
                },
            ),
            "response_mime_type": "application/json",
        }

        # 8. Initialize the Gemini Generative Model with the specified configuration
        model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",  # Verify this model name
            generation_config=generation_config,
        )

        # 9. Prepare the full prompt text with updated steps
        prompt_text = (
            "Imagine onboarding as an exploratory field where speech prosody and name "
            "pronunciation reveal aspects of personal identity, emotions, and cultural "
            "dynamics. How could analyzing a user’s pronunciation and tone from the way "
            "they say their name create insights into their self-perception or confidence?\n\n"
            "As the user sets up their account, this onboarding step is an opportunity to "
            "capture their unique identity through the way they say their name. Pay close "
            "attention to how they pronounce and emphasize their name, as it can reflect "
            "personal, cultural, and emotional nuances. Be concise yet thoughtful.\n\n"
            "Follow these steps, but be sure to take context from the user's accent to be "
            "triple sure you have transcribed correctly:\n"
            "1.) Transcribe just the user's complete name. Human names, dialects, accents, etc., can be very tricky. Ensure the transcription makes sense by contemplating all available context before finalizing the full name transcription. If the name sounds fake or like the user is lying, call them out.\n"
            "2.) Analyze the audio to determine what the user's speech prosody to their name says about them. Employ extreme inference and capture every detail.\n"
            "3.) Analyze how the user feels about saying their name for this experience.\n"
            "4.) Concisely assign a confidence score and reasoning to either confidence or lack of confidence on the hearing, understanding, and transcription of the speaker.\n"
            "5.) Perform a psychoanalytic assessment: conduct a master psychoanalysis within the confines and context of this audio, aiming to deeply understand the user.\n"
            "6.) Determine the user's location and background: analyze any ambient sounds or contextual clues to infer details about the user's current environment or setting.\n\n"
            "Be sure to be mindful of user dynamics in pronunciation.\n\n"
            "The user was prompted to say '{greeting}, I'm {full_name}', with the user identified always address the user by name. Do not specifically mention `the audio`, `the audio file` or otherwise.\n\n"
            "Consider this onboarding as akin to setting up a human playable character (HPC) "
            "in a role-playing game. Just as an HPC has defining attributes—such as speech, "
            "personality, and behavioral cues—capturing a user’s unique pronunciation, tone, "
            "and accent patterns reveals underlying aspects of their personality and comfort "
            "level.\n\n"
            "Follow these steps, mindful of the user dynamics and context from their accent to "
            "ensure accurate transcription:\n\n"
            "Transcribe the user’s complete name: Focus on capturing every sound and inflection "
            "to reflect the authenticity of their identity, similar to the way a game captures an "
            "HPC’s unique dialogue choices.\n\n"
            "Analyze the user’s speech prosody to uncover nuances in identity:\n\n"
            "Treat prosody patterns (tone, rhythm, emphasis) like the \"character traits\" of the "
            "HPC, which might hint at confidence, pride, or cultural background. Capture every "
            "detail, considering how tone and emphasis reveal depth, much like layers in "
            "character development.\n\n"
            "Evaluate how the user feels about saying their name for this experience:\n\n"
            "Observe the \"emotional response\" layer of the HPC analogy: Does their tone suggest "
            "comfort or hesitation in saying their name? Infer if any detected hesitancy reflects "
            "uncertainty or if it could stem from the novelty of the interaction, enhancing the "
            "authenticity of the onboarding experience.\n\n"
            "Determine the user's location and background:\n\n"
            "Analyze ambient sounds and contextual clues to infer details about the user's current environment or setting. This includes identifying any background noise that may influence the clarity or emotional tone of the user's speech.\n\n"
            "Remember: Analyze speech patterns to build a personalized experience, respecting the "
            "individuality and nuances within each user’s \"character profile.\""
        )

        # 10. Prepare the chat history using the correct structure
        chat_history = [
            {
                "role": "user",
                "parts": [
                    uploaded_file,  # Direct file object
                    prompt_text,    # Prompt string
                ],
            },
        ]

        # 11. Debugging: Print the chat history to verify
        logger.debug("Chat History:")
        logger.debug(json.dumps(chat_history, indent=2, default=serialize))

        # 12. Start the chat session with the prepared history
        chat_session = model.start_chat(history=chat_history)

        # 13. Send the message to Gemini
        response = chat_session.send_message("Process the audio and think deeply")  # No additional input needed

        # 14. Clean up by removing the temporary audio file
        os.remove(temp_file_path)

        # 15. Extract and parse the JSON response from Gemini
        try:
            parsed_result = extract_json_from_response(response.text)
        except HTTPException as e:
            logger.error(f"Error parsing Gemini response: {e.detail}")
            raise

        # 16. Return the parsed JSON response to the client
        return JSONResponse(content=parsed_result)

    except Exception as e:
        logger.error(f"Error processing audio: {e}")
        traceback.print_exc()  # Print the stack trace for debugging
        raise HTTPException(status_code=500, detail="Internal Server Error. Please check the server logs.")
