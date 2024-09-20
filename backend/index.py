# File: backend/index.py

# i have all these router functions that i intend to call with my app, im not sure that i want to log anything as provacy is important and all data will mostly be stored on client, but maybe i need to so this is my question!   
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers.websocket import ping, whisper_tts
from routers.post.llm_inference.claude import router as claude_router
from routers.humeclient import router as hume_router
from routers.post.embeddings.index import router as embeddings_router  # New import
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = FastAPI()

# Add CORS middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Internal: Ping Route for Status Checks ** this is a websocket ** 
app.include_router(ping.router)

# Whisper TTS Router ** this is a websocket ** 
app.include_router(whisper_tts.router)
# maybe need to set up a post

# Claude/OpenAI/Gemini LLM Router ** this is a post ** 
# TODO: ADD OPENROUTER would like access to the Nous Models
app.include_router(claude_router, prefix="/v3/claude")

# Hume AI Router ** this is a post, but websocket is available ** 
app.include_router(hume_router, prefix="/api/v1/hume")
# speech prosody
# Embeddings Router ** this is a post **
app.include_router(embeddings_router, prefix="/embeddings")
# small & large
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

"""
DETAILED NOTES ON PREVIOUS VERSIONS AND ISSUES:

1. Original Intent:
   - The original script attempted to create a backend service with batch processing capabilities.
   - It aimed to use Firebase for data persistence and Redis for caching.
   - The backend was designed to handle multiple users and process data in batches.

2. Firebase Integration:
   - Firebase was initially included for data storage, but the implementation was incomplete.
   - The Firebase credentials were loaded from an environment variable, which is a good security practice.
   - However, the actual usage of Firebase (storing processed batch data) was commented out, indicating unfinished implementation.

3. Redis Integration:
   - Redis was implemented for caching batch processing results.
   - The implementation included proper connection setup and teardown in the FastAPI lifecycle events.
   - However, the caching logic was tied to the batch processing feature, which itself was not fully implemented.

4. Batch Processing:
   - A batch processing function and endpoint were defined, but the core logic was missing.
   - The code included TODO comments indicating that the actual processing logic was yet to be implemented.
   - It's unclear what the batch data was supposed to represent or how it should be processed.

5. Key Issues:
   a. Incomplete Implementation:
      - The batch processing feature was a skeleton without actual functionality.
      - Firebase storage was set up but not utilized.
   b. Lack of Clear Purpose:
      - The purpose and structure of the batch data were not defined.
      - It's unclear what processing was intended to be done on this data.
   c. Potential Performance Concerns:
      - The comment about "many active users calling the backend a lot" suggests potential scalability issues.
      - The Redis caching was likely added to address this, but without clear processing logic, its effectiveness is questionable.
   d. Code Clarity:
      - The presence of TODO comments and placeholder logic made the code's intention unclear.
      - The mix of implemented and unimplemented features could lead to confusion for developers.

6. Resolution:
   - All batch processing, Firebase, and Redis related code has been removed.
   - The script has been simplified to focus on the core FastAPI setup and existing routers.
   - This clean-up allows for a fresh start if batch processing or data persistence features are needed in the future.

7. Lessons Learned:
   - Implement features completely before integrating them into the main codebase.
   - Clearly document the purpose and structure of data being processed.
   - Ensure that performance optimizations (like caching) are tied to actual, implemented functionality.
   - Regularly review and clean up unused or partially implemented features to maintain code clarity.

8. Moving Forward:
   - If batch processing is needed, clearly define the data structure and processing requirements before implementation.
   - Consider implementing a simpler data persistence solution before scaling up to Firebase, if required.
   - Implement caching only when there's a clear performance benefit for specific, implemented features.
   - Maintain clear documentation of the API's purpose and functionality.
"""