from fastapi import APIRouter, UploadFile, File, HTTPException
from pyannote.audio import Pipeline
from typing import Dict
import torchaudio
import os

# Ensure you've set your Hugging Face token in the environment variables
HUGGINGFACE_TOKEN = os.getenv("HUGGINGFACE_ACCESS_TOKEN")

# Load the speaker diarization pipeline from pyannote.audio
pipeline = Pipeline.from_pretrained(
    "pyannote/speaker-diarization-3.1", 
    use_auth_token=HUGGINGFACE_TOKEN
)

router = APIRouter()

@router.post("/diarization")
async def diarization(file: UploadFile = File(...)) -> Dict:
    """
    Endpoint for performing speaker diarization on an uploaded audio file.
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

    # Run the diarization pipeline on the loaded waveform
    try:
        diarization_result = pipeline({"waveform": waveform, "sample_rate": sample_rate})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Diarization failed: {str(e)}")

    # Convert the result to a human-readable format (segments and speakers)
    diarization_output = []
    for turn, _, speaker in diarization_result.itertracks(yield_label=True):
        diarization_output.append({
            "start": turn.start,
            "end": turn.end,
            "speaker": speaker
        })

    return {"diarization": diarization_output}
