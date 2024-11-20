# backend/route/features/gemini/gemini_audio_handling.py
# Stateless API Design

# audio handling

# client - manage the file urls to send included in the requests.. to manage chats/longer context

# GEMINI RULES: Each project can store up to 20GB of files, with each individual file not exceeding 2GB in size, Prompt Constraints: While there's no explicit limit on the number of audio files in a single prompt, the combined length of all audio files in a prompt must not exceed 9.5 hours.

import os
import asyncio
import json
from datetime import datetime
from typing import List, Optional, Tuple, Union

from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from fastapi.responses import JSONResponse

from dotenv import load_dotenv
import google.generativeai as genai

import logging
import traceback

from tenacity import retry, stop_after_attempt, wait_exponential

from .gemini_process_webhook_v2 import process_with_gemini_webhook  # Ensure this module exists and is correctly implemented

# Configure logging for this module
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Import the database module and tables
from database.db_modules_v2 import (
    database,
    device_registration_table,
    processed_audio_files_table
)

# Initialize FastAPI router
router = APIRouter()

# Configure Gemini API
google_api_key = os.getenv("GOOGLE_API_KEY")

if not google_api_key:
    logger.critical("GOOGLE_API_KEY not found in environment variables.")
    raise EnvironmentError("GOOGLE_API_KEY not found in environment variables.")

genai.configure(api_key=google_api_key)

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def upload_to_gemini(file_content: bytes, mime_type: Optional[str] = None) -> object:
    """
    Uploads the given file content directly to Gemini with retry logic.
    This function is synchronous and should be called within the event loop without using run_in_executor.
    """
    try:
        import io
        file_obj = io.BytesIO(file_content)
        logger.debug("Uploading file to Gemini...")
        uploaded_file = genai.upload_file(file_obj, mime_type=mime_type)
        logger.info(f"Successfully uploaded file as: {uploaded_file.uri}")
        return uploaded_file
    except genai.HttpError as e:
        logger.error(f"HTTPError uploading file: {e.response.content}")
        traceback.print_exc()
        raise
    except Exception as e:
        logger.error(f"Unexpected error uploading file: {e}")
        traceback.print_exc()
        raise

async def process_single_file(file: UploadFile) -> object:
    """
    Process a single file asynchronously.
    """
    try:
        logger.debug(f"Starting to process file: {file.filename}")
        content = await file.read()
        logger.debug(f"Read {len(content)} bytes from {file.filename}")

        # Directly call upload_to_gemini without run_in_executor
        uploaded_file = upload_to_gemini(content, file.content_type)

        logger.debug(f"Uploaded file to Gemini: {uploaded_file.uri}")
        return uploaded_file
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Error processing file {file.filename}: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process file {file.filename}: {str(e)}"
        )

def process_individual_file(filename: str, uploaded_file: object, prompt_type: str) -> Union[Tuple[str, object], Exception]:
    """
    Synchronously process an individual file with Gemini webhook.
    Returns a tuple of (filename, result) or an Exception.
    """
    try:
        logger.debug(f"Processing with Gemini webhook for file: {filename}")
        gemini_result = process_with_gemini_webhook(
            uploaded_file,
            prompt_type=prompt_type,
            batch=False
        )
        logger.debug(f"Gemini processing successful for file: {filename}")
        return (filename, gemini_result)
    except Exception as e:
        logger.error(f"Error in Gemini processing for file {filename}: {e}")
        traceback.print_exc()
        return e

async def store_processed_file(user_id: int, file_name: str, gemini_result: object):
    """
    Stores the processed file information in the database.
    """
    try:
        query = processed_audio_files_table.insert().values(
            user_id=user_id,
            file_name=file_name,
            gemini_result=json.dumps(gemini_result),
            uploaded_at=datetime.utcnow(),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        await database.execute(query)
        logger.info(f"Stored processed file {file_name} for user ID {user_id}.")
    except Exception as e:
        logger.error(f"Error storing processed file {file_name}: {e}")
        traceback.print_exc()
        # Optionally, handle the exception as needed

async def store_processed_files(user_id: int, file_names: List[str], gemini_result: object):
    """
    Stores the processed files information in the database for batch processing.
    """
    try:
        for file_name in file_names:
            await store_processed_file(user_id, file_name, gemini_result)
    except Exception as e:
        logger.error(f"Error storing processed files: {e}")
        traceback.print_exc()
        # Optionally, handle the exception as needed

@router.post("/process-audio")
async def process_audio(
    files: List[UploadFile] = File(...),
    prompt_type: str = Query("default", description="Type of prompt and schema to use"),
    batch: bool = Query(False, description="Process files in batch if True"),
    google_account_id: Optional[str] = Query(None, description="Google Account ID for user identification"),
    device_uuid: Optional[str] = Query(None, description="Device UUID for user identification")
):
    """
    Process multiple audio files concurrently with improved error handling.
    """
    supported_mime_types = {
        "audio/wav", "audio/mp3", "audio/aiff",
        "audio/aac", "audio/ogg", "audio/flac"
    }

    if not files:
        logger.warning("No files uploaded in the request.")
        raise HTTPException(status_code=400, detail="No files uploaded.")

    # Validate all files
    for file in files:
        if file.content_type not in supported_mime_types:
            logger.warning(f"Unsupported file type: {file.content_type} for file {file.filename}.")
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type: {file.content_type}. Supported types: {supported_mime_types}"
            )

    # User identification
    if not google_account_id and not device_uuid:
        logger.warning("No user identification provided.")
        raise HTTPException(status_code=400, detail="User identification required.")

    # Build the query based on provided identifiers
    query = device_registration_table.select()
    if google_account_id and device_uuid:
        query = query.where(
            (device_registration_table.c.google_account_id == google_account_id) &
            (device_registration_table.c.device_uuid == device_uuid)
        )
    elif google_account_id:
        query = query.where(device_registration_table.c.google_account_id == google_account_id)
    elif device_uuid:
        query = query.where(device_registration_table.c.device_uuid == device_uuid)

    # Execute the query
    user_entry = await database.fetch_one(query)
    if not user_entry:
        logger.warning("User not registered.")
        raise HTTPException(status_code=401, detail="User not registered.")

    user_id = user_entry['id']
    logger.info(f"Processing audio files for user ID {user_id}.")

    try:
        # Process files concurrently for uploading
        processing_tasks = [process_single_file(file) for file in files]
        uploaded_files = await asyncio.gather(*processing_tasks, return_exceptions=True)

        # Check for any exceptions in uploaded_files
        errors = []
        valid_uploaded_files = []
        for file, uploaded_file in zip(files, uploaded_files):
            if isinstance(uploaded_file, Exception):
                logger.error(f"Error processing file {file.filename}: {uploaded_file}")
                errors.append({
                    "file": file.filename,
                    "status": "failed",
                    "error": str(uploaded_file)
                })
            else:
                valid_uploaded_files.append((file.filename, uploaded_file))

        if not valid_uploaded_files:
            logger.warning("All file uploads failed.")
            return JSONResponse(content={"results": errors})

        results = errors.copy()

        if batch:
            # Process with Gemini webhook with batch=True
            try:
                logger.debug("Starting batch processing with Gemini webhook.")
                gemini_result = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: process_with_gemini_webhook(
                        [uploaded_file for _, uploaded_file in valid_uploaded_files],
                        prompt_type=prompt_type,
                        batch=True
                    )
                )
                results.append({
                    "files": [filename for filename, _ in valid_uploaded_files],
                    "status": "processed",
                    "data": gemini_result
                })
                logger.debug("Batch processing with Gemini webhook successful.")
                # Store the result in the database
                await store_processed_files(user_id, [filename for filename, _ in valid_uploaded_files], gemini_result)
            except Exception as e:
                logger.error(f"Error in Gemini processing (batch): {e}")
                traceback.print_exc()
                raise HTTPException(status_code=500, detail="Gemini processing failed.")
        else:
            # Process each file individually
            processing_tasks = []
            for filename, uploaded_file in valid_uploaded_files:
                processing_tasks.append(
                    asyncio.get_event_loop().run_in_executor(
                        None,
                        lambda fn=filename, uf=uploaded_file: process_individual_file(fn, uf, prompt_type)
                    )
                )

            individual_results = await asyncio.gather(*processing_tasks, return_exceptions=True)

            for original_file, result in zip(valid_uploaded_files, individual_results):
                filename, _ = original_file
                if isinstance(result, Exception):
                    logger.error(f"Error in Gemini processing for file {filename}: {result}")
                    results.append({
                        "file": filename,
                        "status": "failed",
                        "error": str(result)
                    })
                elif isinstance(result, tuple):
                    fname, gemini_result = result
                    results.append({
                        "file": fname,
                        "status": "processed",
                        "data": gemini_result
                    })
                    # Store the result in the database
                    await store_processed_file(user_id, fname, gemini_result)
                else:
                    logger.error(f"Unexpected result type for file {filename}: {result}")
                    results.append({
                        "file": filename,
                        "status": "failed",
                        "error": "Unexpected processing result."
                    })

        return JSONResponse(content={"results": results})

    except Exception as e:
        logger.error(f"Unexpected error in process_audio: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail="Internal Server Error. Please check the server logs."
        )


@router.get("/test-user")
async def test_user(google_account_id: str, device_uuid: str):
    logger.debug(f"Testing user lookup for google_account_id: {google_account_id} and device_uuid: {device_uuid}")

    query = device_registration_table.select().where(
        (device_registration_table.c.google_account_id == google_account_id) &
        (device_registration_table.c.device_uuid == device_uuid)
    )
    user_entry = await database.fetch_one(query)

    if user_entry:
        logger.debug(f"User found: {user_entry}")
        return {"user_found": True, "user_id": user_entry['id']}
    else:
        logger.debug("User not found.")
        return {"user_found": False}
