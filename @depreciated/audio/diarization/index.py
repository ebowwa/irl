from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks, Query
from fastapi.responses import StreamingResponse
from backend.utils.audio_utils import process_audio_upload, cleanup_tempfile
from services.diarizationService import load_audio, process_diarization, sliding_window_diarization

router = APIRouter()

@router.post("/diarization")
async def diarization(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...)
) -> StreamingResponse:
    """
    Endpoint for performing speaker diarization on an uploaded audio file using the original process_diarization method.
    Streams the diarization results as JSON.
    Expects a mono audio file, sampled at 16kHz.
    """
    # Process the uploaded file and save it temporarily
    temp_file_path = await process_audio_upload(file)

    try:
        # Load the audio file and ensure correct format
        waveform, sample_rate = await load_audio(temp_file_path)
    finally:
        # Schedule the cleanup of the temporary file
        background_tasks.add_task(cleanup_tempfile, temp_file_path)

    # Stream the original diarization process
    return StreamingResponse(
        process_diarization(waveform, sample_rate),
        media_type="application/json"
    )

@router.post("/diarization_sliding_window")
async def diarization_sliding_window(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...),
    window_size: float = Query(5.0, description="Size of each window in seconds"),
    step_size: float = Query(2.5, description="Step size for the sliding window in seconds")
) -> StreamingResponse:
    """
    Endpoint for performing speaker diarization on an uploaded audio file using a sliding window approach.
    Streams the diarization results as JSON.
    Expects a mono audio file, sampled at 16kHz.
    
    - **window_size**: Duration of each audio window in seconds (default: 5.0).
    - **step_size**: Step size for the sliding window in seconds (default: 2.5).
    """
    # Process the uploaded file and save it temporarily
    temp_file_path = await process_audio_upload(file)

    try:
        # Load the audio file and ensure correct format
        waveform, sample_rate = await load_audio(temp_file_path)
    finally:
        # Schedule the cleanup of the temporary file
        background_tasks.add_task(cleanup_tempfile, temp_file_path)

    # Stream the sliding window diarization process
    return StreamingResponse(
        sliding_window_diarization(waveform, sample_rate, window_size, step_size),
        media_type="application/json"
    )
