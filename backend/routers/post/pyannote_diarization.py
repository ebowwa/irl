from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse
from pyannote.audio import Pipeline
from typing import AsyncGenerator
import torchaudio
import os
import json

# Ensure you've set your Hugging Face token in the environment variables
HUGGINGFACE_TOKEN = os.getenv("HUGGINGFACE_ACCESS_TOKEN")

# Load the speaker diarization pipeline from pyannote.audio
pipeline = Pipeline.from_pretrained(
    "pyannote/speaker-diarization-3.1", 
    use_auth_token=HUGGINGFACE_TOKEN
)

router = APIRouter()

import time

async def process_diarization(waveform, sample_rate) -> AsyncGenerator[str, None]:
    total_samples = waveform.size(1)
    processed_samples = 0

    try:
        diarization_result = pipeline({"waveform": waveform, "sample_rate": sample_rate})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Diarization failed: {str(e)}")

    for turn, _, speaker in diarization_result.itertracks(yield_label=True):
        diarization_output = {
            "start": turn.start,
            "end": turn.end,
            "speaker": speaker
        }
        processed_samples += int((turn.end - turn.start) * sample_rate)
        progress_percentage = (processed_samples / total_samples) * 100

        yield json.dumps({"diarization_output": diarization_output, "progress": progress_percentage}) + "\n"


@router.post("/diarization")
async def diarization(file: UploadFile = File(...)) -> StreamingResponse:
    """
    Endpoint for performing speaker diarization on an uploaded audio file, streaming the results.
    Expects a mono audio file, sampled at 16kHz.
    """
    # Load audio file with torchaudio
    try:
        waveform, sample_rate = torchaudio.load(file.file)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error loading audio: {str(e)}")

    # Ensure the audio is in the correct format (16kHz)
    if sample_rate != 16000:
        raise HTTPException(status_code=400, detail="Audio must be sampled at 16kHz")

    # Stream the diarization process
    return StreamingResponse(process_diarization(waveform, sample_rate), media_type="application/json")
