import os
import json
import torchaudio
from fastapi import HTTPException
from pyannote.audio import Pipeline
from typing import AsyncGenerator

# Ensure you've set your Hugging Face token in the environment variables
HUGGINGFACE_TOKEN = os.getenv("HUGGINGFACE_ACCESS_TOKEN")

if not HUGGINGFACE_TOKEN:
    raise RuntimeError("Hugging Face token is not set. Please set HUGGINGFACE_ACCESS_TOKEN.")

# Load the speaker diarization pipeline from pyannote.audio
pipeline = Pipeline.from_pretrained(
    "pyannote/speaker-diarization-3.1", 
    use_auth_token=HUGGINGFACE_TOKEN
)

async def load_audio(file_path: str):
    """
    Loads the audio file and ensures it meets the expected format.
    Returns the waveform and sample rate.
    """
    try:
        waveform, sample_rate = torchaudio.load(file_path)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error loading audio: {str(e)}")

    # Ensure the audio is in the correct format (mono, 16kHz)
    if sample_rate != 16000:
        raise HTTPException(status_code=400, detail="Audio must be sampled at 16kHz.")
    if waveform.size(0) != 1:
        raise HTTPException(status_code=400, detail="Audio must be mono.")

    return waveform, sample_rate


async def process_diarization(waveform, sample_rate) -> AsyncGenerator[str, None]:
    """
    Perform speaker diarization on the given audio waveform and stream results.
    """
    total_samples = waveform.size(1)
    processed_samples = 0

    try:
        diarization_result = pipeline({"waveform": waveform, "sample_rate": sample_rate})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Diarization failed: {str(e)}")

    # Iterate over the diarization results and stream progress
    for turn, _, speaker in diarization_result.itertracks(yield_label=True):
        diarization_output = {
            "start": turn.start,
            "end": turn.end,
            "speaker": speaker
        }
        processed_samples += int((turn.end - turn.start) * sample_rate)
        progress_percentage = (processed_samples / total_samples) * 100

        yield json.dumps({
            "diarization_output": diarization_output,
            "progress": progress_percentage
        }) + "\n"
