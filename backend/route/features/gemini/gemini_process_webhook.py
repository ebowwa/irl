# backend/route/features/gemini_process_webhook.py
# Module for handling Gemini webhook processing and JSON extraction

import logging
import re
import json
from fastapi import HTTPException
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content

# Configure logging
logger = logging.getLogger(__name__)

def process_with_gemini_webhook(uploaded_file):
    """
    Internal webhook to process audio file using Gemini's generative capabilities.

    Args:
        uploaded_file: The uploaded file object from Gemini.

    Returns:
        dict: Parsed JSON response from Gemini.
    """
    try:
        # Prepare the prompt and model configuration
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
                    "name": content.Schema(type=content.Type.STRING, description="The user's full name."),
                    "prosody": content.Schema(type=content.Type.STRING, description="Speech analysis."),
                    "feeling": content.Schema(type=content.Type.STRING, description="Emotional tone."),
                    "confidence_score": content.Schema(type=content.Type.INTEGER, description="Confidence score."),
                    "confidence_reasoning": content.Schema(type=content.Type.STRING, description="Reasoning."),
                    "psychoanalysis": content.Schema(type=content.Type.STRING, description="Psychological insights."),
                    "location_background": content.Schema(type=content.Type.STRING, description="Environment details."),
                },
            ),
            "response_mime_type": "application/json",
        }

        model = genai.GenerativeModel(model_name="gemini-1.5-flash", generation_config=generation_config)

        # Prepare the full prompt text with updated steps
        prompt_text = (
            "# Context Setting\n"
            "Imagine onboarding as an exploratory field where speech prosody and name "
            "pronunciation reveal aspects of personal identity, emotions, and cultural "
            "dynamics. Consider this onboarding as akin to setting up a human playable "
            "character (HPC) in a real-life role-playing game. Just as an HPC has defining "
            "attributes—such as speech, personality, and behavioral cues—capturing a user's "
            "unique pronunciation, tone, and accent patterns reveals underlying aspects of "
            "their personality and comfort level.\n\n"
            
            "# Interaction Format\n"
            "The user was prompted to say '{greeting}, I'm {full_name}', with the user identified always address the user by name.\n\n"
            
            "# Analysis Steps\n\n"
            "1.) Transcribe just the user's complete name. Human names, dialects, accents, etc., "
            "can be very tricky. Ensure the transcription makes sense by contemplating all "
            "available context before finalizing the full name transcription. If the name "
            "sounds fake or like the user is lying, call them out. Focus on capturing every "
            "sound and inflection to reflect the authenticity of their identity. Be mindful "
            "of user dynamics in pronunciation.\n\n"
            
            "2.) Analyze the audio to determine what the user's speech prosody to their name "
            "says about them. Employ extreme inference and capture every detail. Treat prosody "
            "patterns (tone, rhythm, emphasis) like the 'character traits' of the HPC, which "
            "might hint at confidence, pride, or cultural background. Consider how tone and "
            "emphasis reveal depth, much like layers in character development.\n\n"
            
            "3.) Analyze how the user feels about saying their name for this experience. "
            "Observe the 'emotional response' layer of the HPC analogy. Evaluate if their "
            "tone suggests comfort or hesitation. Infer if any detected hesitancy reflects "
            "uncertainty or stems from the novelty of the interaction.\n\n"
            
            "4.) Concisely assign a confidence score and reasoning to either confidence or "
            "lack of confidence on hearing, understanding, and transcription of the speaker. "
            "DO NOT BE OVERLY OPTIMISTIC ABOUT PREDICTIONS. Return nulls if not enough info "
            "(i.e., speech isn't detected or a name isn't spoken). Do not imagine names or "
            "hallucinate information.\n\n"
            
            "5.) Perform a psychoanalytic assessment: conduct a master psychoanalysis within "
            "the confines and context of this audio, aiming to deeply understand the user.\n\n"
            
            "6.) Determine the user's location and background: analyze ambient sounds and "
            "contextual clues to infer details about the user's current environment or setting. "
            "This includes identifying any background noise that may influence the clarity or "
            "emotional tone of the user's speech.\n\n"
            
            "# Important Notes\n"
            "- Take context from the user's accent to be triple sure of correct transcription\n"
            "- Do not specifically mention 'the audio', 'the audio file' or otherwise\n"
            "- Analyze speech patterns to build a personalized experience\n"
            "- Respect the individuality and nuances within each user's 'character profile'\n"
            "- BE SURE TO NOT LIE OR HALLUCINATE\n"
        )

        # Create chat history with the uploaded file and prompt
        chat_history = [{"role": "user", "parts": [uploaded_file, prompt_text]}]
        chat_session = model.start_chat(history=chat_history)

        # Send a message to the model
        response = chat_session.send_message("Process the audio and think deeply")

        # Extract JSON from the response
        parsed_result = extract_json_from_response(response.text)

        return parsed_result

    except Exception as e:
        logger.error(f"Error in Gemini webhook processing: {e}")
        raise HTTPException(status_code=500, detail="Gemini processing failed")

def extract_json_from_response(response_text: str) -> dict:
    """
    Extracts JSON content from Gemini response text.

    Args:
        response_text (str): The text response from Gemini.

    Returns:
        dict: Parsed JSON object.
    """
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
        try:
            return json.loads(response_text)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decoding error: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to decode JSON: {e}")
