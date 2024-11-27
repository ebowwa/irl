# api/routes.py
from fastapi import APIRouter, File, UploadFile, Query, HTTPException
from fastapi.responses import JSONResponse
from typing import List
import asyncio
import logging
from ..configs.schemas import SchemaManager
from ..services.audio_service import AudioService
from ..services.gemini_service import GeminiService

logger = logging.getLogger(__name__)

# Initialize services
try:
    schema_manager = SchemaManager()
    audio_service = AudioService()
    gemini_service = GeminiService(schema_manager)
except Exception as e:
    logger.error(f"Failed to initialize services: {e}")
    raise

router = APIRouter()

@router.post("/process-audio")
async def process_audio(
    files: List[UploadFile] = File(...),
    prompt_type: str = Query("transcription_v1", description="Type of prompt to use"),
    batch: bool = Query(False, description="Process files in batch if True"),
    model_name: str = Query("gemini-1.5-flash", description="Gemini model to use"),
    temperature: float = Query(1.0, description="Temperature parameter"),
    top_p: float = Query(0.95, description="Top-p parameter"),
    top_k: int = Query(40, description="Top-k parameter"),
    max_output_tokens: int = Query(8192, description="Maximum output tokens")
):
    try:
        # Process files concurrently
        tasks = [audio_service.process_file(file) for file in files]
        uploaded_files = await asyncio.gather(*tasks, return_exceptions=True)

        # Handle results
        results = []
        valid_files = []

        for file, result in zip(files, uploaded_files):
            if isinstance(result, Exception):
                logger.error(f"Failed to process file {file.filename}: {result}")
                results.append({
                    "file": file.filename,
                    "status": "failed",
                    "error": str(result)
                })
            else:
                valid_files.append((file.filename, result))

        if not valid_files:
            logger.warning("No valid files to process")
            return JSONResponse(content={"results": results})

        # Process with Gemini
        try:
            gemini_results = await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: gemini_service.process_audio(
                    [f[1] for f in valid_files],
                    prompt_type,
                    batch,
                    model_name,
                    temperature,
                    top_p,
                    top_k,
                    max_output_tokens
                )
            )

            # Add successful results
            if batch:
                results.append({
                    "files": [f[0] for f in valid_files],
                    "status": "processed",
                    "data": gemini_results
                })
            else:
                for filename, _ in valid_files:
                    results.append({
                        "file": filename,
                        "status": "processed",
                        "data": gemini_results
                    })

        except Exception as e:
            logger.error(f"Gemini processing failed: {e}")
            for filename, _ in valid_files:
                results.append({
                    "file": filename,
                    "status": "failed",
                    "error": str(e)
                })

        return JSONResponse(content={"results": results})

    except Exception as e:
        logger.error(f"Error in process_audio endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))
