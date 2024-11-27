# backend/services/diarizationService.py
import os
import json
import torchaudio
from fastapi import HTTPException
from pyannote.audio import Pipeline
from typing import AsyncGenerator
import logging

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
    logging.info(f"Attempting to load audio file: {file_path}")
    try:
        waveform, sample_rate = torchaudio.load(file_path)
        logging.info(f"Successfully loaded audio file. Sample rate: {sample_rate}, Channels: {waveform.size(0)}")
    except torchaudio.io.error.NoBackendError as e:
        error_msg = f"Audio backend error: {str(e)}"
        logging.error(error_msg)
        raise HTTPException(status_code=500, detail=error_msg)
    except FileNotFoundError:
        error_msg = "Uploaded file not found."
        logging.error(error_msg)
        raise HTTPException(status_code=404, detail=error_msg)
    except Exception as e:
        error_msg = f"Unexpected error loading audio: {str(e)}"
        logging.error(error_msg)
        raise HTTPException(status_code=400, detail=error_msg)

    # Ensure the audio is in the correct format (mono, 16kHz)
    if sample_rate != 16000:
        error_msg = f"Incorrect sample rate: {sample_rate}. Required: 16000 Hz."
        logging.error(error_msg)
        raise HTTPException(status_code=400, detail=error_msg)
    if waveform.size(0) != 1:
        error_msg = f"Incorrect number of channels: {waveform.size(0)}. Required: 1 (mono)."
        logging.error(error_msg)
        raise HTTPException(status_code=400, detail=error_msg)

    return waveform, sample_rate


async def process_diarization(waveform, sample_rate) -> AsyncGenerator[str, None]:
    """
    Perform speaker diarization on the entire audio waveform and stream results.
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

async def sliding_window_diarization(
    waveform, 
    sample_rate, 
    window_size: float = 5.0, 
    step_size: float = 2.5
) -> AsyncGenerator[str, None]:
    """
    Perform sliding window speaker diarization on the given audio waveform and stream results.
    
    Parameters:
    - window_size: Duration of each window in seconds.
    - step_size: Step size for sliding the window in seconds.
    """
    total_samples = waveform.size(1)
    window_samples = int(window_size * sample_rate)
    step_samples = int(step_size * sample_rate)

    processed_samples = 0
    start_sample = 0

    # To keep track of previous speaker for continuity
    previous_speaker = None

    while start_sample < total_samples:
        end_sample = min(start_sample + window_samples, total_samples)
        window_waveform = waveform[:, start_sample:end_sample]

        try:
            diarization_result = pipeline({"waveform": window_waveform, "sample_rate": sample_rate})
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Diarization failed: {str(e)}")

        # Process each segment in the window
        for turn, _, speaker in diarization_result.itertracks(yield_label=True):
            # Adjust the timing relative to the entire audio
            diarization_output = {
                "start": turn.start + (start_sample / sample_rate),
                "end": turn.end + (start_sample / sample_rate),
                "speaker": speaker
            }

            # Optional: Merge with previous speaker if continuity is detected
            if previous_speaker == speaker:
                # Extend the previous speaker's end time
                # Implement logic to merge segments if necessary
                pass
            else:
                previous_speaker = speaker

            processed_samples += int((turn.end - turn.start) * sample_rate)
            progress_percentage = (processed_samples / total_samples) * 100

            yield json.dumps({
                "diarization_output": diarization_output,
                "progress": progress_percentage
            }) + "\n"

        # Move to the next window
        start_sample += step_samples
