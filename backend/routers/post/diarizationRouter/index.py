from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.responses import StreamingResponse
from utils.audioUtils import process_audio_upload, cleanup_tempfile
from services.diarizationService import load_audio, process_diarization

router = APIRouter()

@router.post("/diarization")
async def diarization(background_tasks: BackgroundTasks, file: UploadFile = File(...)) -> StreamingResponse:
    """
    Endpoint for performing speaker diarization on an uploaded audio file, streaming the results.
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

    # Stream the diarization process
    return StreamingResponse(process_diarization(waveform, sample_rate), media_type="application/json")
