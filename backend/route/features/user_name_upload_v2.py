# app/routers/gemini_router.py
# FastAPI router for processing audio using Google Gemini

import os
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content
import json

# 1. Load environment variables from the .env file
load_dotenv()

# 2. Initialize the FastAPI router
router = APIRouter()

# 3. Retrieve and configure the Gemini API key
google_api_key = os.getenv("GOOGLE_API_KEY")
if not google_api_key:
    raise EnvironmentError("GOOGLE_API_KEY not found in environment variables.")

genai.configure(api_key=google_api_key)

def upload_to_gemini(file_path: str, mime_type: str = None):
    """
    4. Uploads the given file to Gemini.

    Args:
        file_path (str): Path to the file to upload.
        mime_type (str, optional): MIME type of the file. Defaults to None.

    Returns:
        Uploaded file object.
    """
    try:
        # 4.1. Upload the file using Gemini's API
        uploaded_file = genai.upload_file(file_path, mime_type=mime_type)
        print(f"Uploaded file '{uploaded_file.display_name}' as: {uploaded_file.uri}")
        return uploaded_file
    except Exception as e:
        # 4.2. Log and re-raise any exceptions that occur during upload
        print(f"Error uploading file: {e}")
        raise

@router.post("/process-audio")
async def process_audio(file: UploadFile = File(...)):
    """
    5. Endpoint to upload an audio file, process it with Gemini, and return the analysis.

    Args:
        file (UploadFile): The audio file to process.

    Returns:
        JSONResponse: The analysis result from Gemini.
    """
    # 5.1. Validate MIME type of the uploaded file
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
        # 5.2. Save the uploaded file temporarily on the server
        temp_file_path = f"/tmp/{file.filename}"
        with open(temp_file_path, "wb") as temp_file:
            content_bytes = await file.read()
            temp_file.write(content_bytes)

        # 5.3. Upload the file to Gemini
        uploaded_file = upload_to_gemini(temp_file_path, mime_type=file.content_type)

        # 5.4. Define the updated generation configuration with the new JSON schema
        generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 64,
            "max_output_tokens": 8192,
            "response_schema": content.Schema(
                type=content.Type.OBJECT,
                # 5.4.1. Define required fields as a list of strings
                required=[
                    "name",
                    "prosody",
                    "feeling",
                    "confidence_score",
                    "confidence_reasoning",
                    "Psychoanalysis"
                ],
                # 5.4.2. Define properties with their respective types and descriptions
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
                    "Psychoanalysis": content.Schema(
                        type=content.Type.STRING,
                        description="A deeper psychological interpretation of the user's speech delivery, tone, and context, providing insights into potential emotional or personality traits based on observed vocal patterns.",
                    ),
                },
            ),
            # 5.4.3. Specify the response MIME type as JSON
            "response_mime_type": "application/json",
        }

        # 5.5. Initialize the Gemini Generative Model with the specified configuration
        model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            generation_config=generation_config,
        )

        # 5.6. Prepare the chat session history with the updated prompt
        # 5.6.1. Define the prompt text with actual values, removing placeholders
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
            "1.) Transcribe just the user's complete name. Human names, dialects, accents, etc., can be very tricky. Ensure the transcription makes sense by contemplating all available context before finalizing the full name transcription.\n"
            "2.) Analyze the audio to determine what the user's speech prosody to their name says about them. Employ extreme inference and capture every detail.\n"
            "3.) Analyze how the user feels about saying their name for this experience.\n"
            "4.) Concisely assign a confidence score and reasoning to either confidence or lack of confidence on the hearing, understanding, and transcription of the speaker.\n"
            "5.) Perform a psychoanalytic assessment: conduct a master psychoanalysis within the confines and context of this audio, aiming to deeply understand the user.\n\n"
            "Be sure to be mindful of user dynamics in pronunciation.\n\n"
            "The user was prompted to say 'Hello, I'm Elijah Cornelius RB.'"
        )

        # 5.6.2. Initialize the chat session with the prepared history
        chat_history = [
            {
                "role": "user",
                "parts": [
                    uploaded_file,
                    prompt_text,
                ],
            },
            # 5.6.3. Remove any model responses from the history to prevent instructing the model to use code blocks
            # Do not include model responses in the history
        ]

        # 5.7. Start the chat session with the prepared history
        chat_session = model.start_chat(history=chat_history)

        # 5.8. Send the message to Gemini
        # Since the prompt includes all necessary instructions, no additional input is needed
        response = chat_session.send_message("")  # No additional input needed

        # 5.9. Clean up by removing the temporary audio file
        os.remove(temp_file_path)

        # 5.10. Parse the JSON response from Gemini
        try:
            # Directly parse the response text as JSON since 'response_mime_type' is set to 'application/json'
            parsed_result = json.loads(response.text)
        except json.JSONDecodeError as e:
            # 5.10.1. Handle JSON parsing errors
            raise HTTPException(status_code=500, detail=f"Failed to parse Gemini response: {e}")

        # 5.11. Return the parsed JSON response to the client
        return JSONResponse(content=parsed_result)

    except Exception as e:
        # 5.12. Handle any unexpected errors during processing
        print(f"Error processing audio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


"""
# Example curl Command to Test the Endpoint

curl -X POST "http://127.0.0.1:9090/gemini/process-audio" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/Users/ebowwa/Desktop/Recorded_Audio_October_27_2024_9_59PM.ogg;type=audio/ogg"
"""
