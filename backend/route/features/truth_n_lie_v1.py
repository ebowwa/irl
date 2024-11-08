import os
import tempfile
import json
import re
import logging
import traceback
from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content
from types import MappingProxyType

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 1. Load environment variables from .env
load_dotenv()

# 2. Initialize the FastAPI router
router = APIRouter(
    tags=["Truth and Lie Analysis"],
    responses={404: {"description": "Not found"}},
)

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

@router.post("/TruthNLie", summary="Process an audio file to determine the truthfulness of statements.")
async def analyze_truth_lie(file: UploadFile = File(...)):
    """
    Endpoint to upload an audio file and process it with Gemini AI to analyze truthfulness.

    Args:
        file (UploadFile): The audio file to process.

    Returns:
        JSONResponse: The analysis result from Gemini AI.
    """
    # 6. Validate MIME type of the uploaded file
    supported_mime_types = [
        "audio/wav",
        "audio/mp3",
        "audio/aiff",
        "audio/aac",
        "audio/ogg",
        "audio/flac",
    ]
    if file.content_type not in supported_mime_types:
        logger.error(f"Unsupported file type: {file.content_type}")
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}",
        )

    temp_file_path = None  # Initialize for cleanup in finally block
    try:
        # 7. Save the uploaded file temporarily on the server using tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            temp_file.write(await file.read())
            temp_file_path = temp_file.name
            logger.info(f"File saved to {temp_file_path}")

        # 8. Upload the file to Gemini and get the file object
        uploaded_file = upload_to_gemini(temp_file_path, mime_type=file.content_type)

        # 9. Define the generation configuration with JSON schema support
        generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 64,
            "max_output_tokens": 8192,
            "response_schema": content.Schema(
                type=content.Type.OBJECT,
                required=[
                    "finalConfidenceScore",
                    "guessJustification",
                    "likelyLieStatementId",
                    "responseMessage",
                    "statementIds",
                    "statements"
                ],
                properties={
                    "finalConfidenceScore": content.Schema(
                        type=content.Type.NUMBER,
                        description="The overall confidence score of the analysis",
                    ),
                    "guessJustification": content.Schema(
                        type=content.Type.STRING,
                        description="The reason or justification for the primary guess of truth or lie",
                    ),
                    "likelyLieStatementId": content.Schema(
                        type=content.Type.INTEGER,
                        description="ID of the statement identified as most likely to be false",
                    ),
                    "responseMessage": content.Schema(
                        type=content.Type.STRING,
                        description="General response message summarizing the analysis",
                    ),
                    "statementIds": content.Schema(
                        type=content.Type.ARRAY,
                        description="List of IDs corresponding to each statement analyzed",
                        items=content.Schema(
                            type=content.Type.INTEGER,
                            description="Unique identifier for each statement",
                        ),
                    ),
                    "statements": content.Schema(
                        type=content.Type.ARRAY,
                        description="Flattened data of each statement's content and analysis",
                        items=content.Schema(
                            type=content.Type.OBJECT,
                            required=[
                                "id",
                                "text",
                                "isTruth",
                                "pitchVariation",
                                "pauseDuration",
                                "stressLevel",
                                "confidenceScore"
                            ],
                            properties={
                                "id": content.Schema(
                                    type=content.Type.INTEGER,
                                    description="Unique identifier for the statement",
                                ),
                                "text": content.Schema(
                                    type=content.Type.STRING,
                                    description="The text of the statement being analyzed",
                                ),
                                "isTruth": content.Schema(
                                    type=content.Type.BOOLEAN,
                                    description="True if the statement is likely truthful, false otherwise",
                                ),
                                "pitchVariation": content.Schema(
                                    type=content.Type.STRING,
                                    description="The level of pitch variation detected",
                                ),
                                "pauseDuration": content.Schema(
                                    type=content.Type.NUMBER,
                                    description="Duration of pauses detected before or after the statement",
                                ),
                                "stressLevel": content.Schema(
                                    type=content.Type.STRING,
                                    description="Stress level detected in the audio statement",
                                ),
                                "confidenceScore": content.Schema(
                                    type=content.Type.NUMBER,
                                    description="Confidence score for this specific statement's classification",
                                ),
                            },
                        ),
                    ),
                },
            ),
            "response_mime_type": "application/json",
        }

        # Initialize the Generative Model
        model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            generation_config=generation_config,
        )

        # 10. Define the chat prompt
        prompt_text = (
            "You are a consciousness companion, former CIA operative, and ice-breaker game engine, "
            "You are playing a game of `Two Truths and a Lie`, as the detective"
            "Please provide the exact three distinct statements as discussed by the user: two truths and one lie. Each statement should be a complete sentence and not a fragment. Ensure that the statements are clear and concise, with no overlapping or repeated content."
            "Speak directly to the user, acting as a mirror for their thoughts and intentions, drawing insight from a deep analysis of their statements."
            "Each step will peel back layers, examining the emotional, psychological, and sociological cues embedded in their responses, ultimately synthesizing all findings for a comprehensive judgment on truthfulness."
            "Be concise, but don’t hold back. Be on the lookout for smooth talkers with small, imperceptible shifts, as users have proven to decieve you."
            "Do not hold absolute conviction; see things from a multi-disciplinary lens, including psychoanalytic.\n\n"

            "### Step 1: Transcription and Fluency Analysis\n"
            "- **Goal**: Accurately transcribe each statement, focusing on identifying hesitation, filler words, "
            "pauses, and fluency.\n"
            "- **Metrics**: Track pause duration, detect filler words (e.g., 'um,' 'like'), and assess overall "
            "fluency of speech.\n"
            "- **Output**: Annotated transcription, marking moments of confidence or hesitation through speech patterns.\n\n"

            "### Step 2: Emotional and Psychological Profiling\n"
            "- **Goal**: Examine the emotional and psychological cues embedded in each statement, looking for "
            "signs of authenticity.\n"
            "- **Metrics**:\n"
            "  - **Tone**: Categorize as neutral, positive, or tense, reflecting the overall emotional undertone.\n"
            "  - **Stress Level**: Analyze vocal stress, classifying as high, medium, or low based on pitch variations, "
            "pauses, and other indicators.\n"
            "  - **Confidence Score**: Assign a truthfulness score from 0 to 1 for each statement, capturing the likelihood "
            "of it being genuine.\n"
            "  - **Cognitive Load Indicators**: Identify signs of cognitive strain, such as hesitations or stumbles, "
            "suggesting increased mental effort.\n"
            "- **Output**: Emotional and psychological profile for each statement, detailing confidence and highlighting "
            "any emotional leakage or cognitive stress.\n\n"

            "### Step 3: Sociological Contextualization\n"
            "- **Goal**: Gauge the plausibility of each statement within a sociological framework, considering social norms "
            "and expected behavior.\n"
            "- **Metrics**:\n"
            "  - **Plausibility**: Assess how believable or realistic the statement appears within societal expectations.\n"
            "  - **Relatability**: Judge whether the statement sounds relatable or fabricated, based on both vocal style and content.\n"
            "- **Output**: Sociological assessment that discusses the statement’s alignment with typical social behavior "
            "and credibility.\n\n"

            "### Step 4: Inference and Final Judgment\n"
            "- **Goal**: Combine insights from all previous steps to reach a conclusion on truthfulness.\n"
            "- **Metrics**:\n"
            "  - **Aggregated Confidence Scores**: Compile confidence scores to gauge overall truthfulness.\n"
            "  - **Likely Lie Index**: Identify the index of any statement most likely to be deceptive.\n"
            "- **Output**: Final assessment, providing a reasoned justification based on emotional, psychological, and "
            "sociological insights. This will include any detected likely lie, with supporting rationale derived from the earlier analyses.\n"
        )

        # 11. Prepare the chat history
        chat_history = [
            {
                "role": "user",
                "parts": [
                    uploaded_file,  # Direct file object
                    prompt_text,    # Prompt string
                ],
            },
        ]

        logger.debug("Chat History:")
        logger.debug(json.dumps(chat_history, indent=2, default=serialize))

        # 12. Start the chat session with the prepared history
        chat_session = model.start_chat(history=chat_history)

        # 13. Send the message to the chat session
        response = chat_session.send_message("Process the audio file and provide your analysis.")

        # 14. Log the response text for debugging
        logger.debug(f"Response text: {response.text}")

        # 15. Extract and parse the JSON response from Gemini
        parsed_result = extract_json_from_response(response.text)

        return JSONResponse(content=parsed_result)

    except HTTPException as he:
        # Re-raise HTTP exceptions directly
        raise he
    except Exception as e:
        logger.error(f"Error processing truth and lie analysis: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Server Error. Please check the server logs.")
    finally:
        # 16. Clean up by removing the temporary audio file if it exists
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
                logger.info(f"Temporary file {temp_file_path} deleted.")
            except Exception as e:
                logger.error(f"Error deleting temporary file: {e}")
                # Not raising an exception since the main processing was successful
