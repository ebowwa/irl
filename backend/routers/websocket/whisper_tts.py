# File: websocket/routers/whisper_tts.py
# TODO: stream updates
from fastapi import APIRouter, UploadFile, WebSocket, WebSocketDisconnect, File, HTTPException
from pydantic import BaseModel, Field
from enum import Enum
import fal_client
import asyncio
import json
import logging
from typing import List, Optional
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

# Set FAL_KEY from environment variable
fal_client.api_key = os.getenv('FAL_KEY') or 'your_api_key'

class TaskEnum(str, Enum):
    transcribe = "transcribe"
    translate = "translate"
# TODO: Modularize this language class rename it to WhisperAvailableLanguagesEnum in its on script or a const script
# needs to be connected to the app settings and other features language related
class LanguageEnum(str, Enum):
    af = "af"
    am = "am"
    ar = "ar"
    as_ = "as"
    az = "az"
    ba = "ba"
    be = "be"
    bg = "bg"
    bn = "bn"
    bo = "bo"
    br = "br"
    bs = "bs"
    ca = "ca"
    cs = "cs"
    cy = "cy"
    da = "da"
    de = "de"
    el = "el"
    en = "en"
    es = "es"
    et = "et"
    eu = "eu"
    fa = "fa"
    fi = "fi"
    fo = "fo"
    fr = "fr"
    gl = "gl"
    gu = "gu"
    ha = "ha"
    haw = "haw"
    he = "he"
    hi = "hi"
    hr = "hr"
    ht = "ht"
    hu = "hu"
    hy = "hy"
    id = "id"
    is_ = "is"
    it = "it"
    ja = "ja"
    jw = "jw"
    ka = "ka"
    kk = "kk"
    km = "km"
    kn = "kn"
    ko = "ko"
    la = "la"
    lb = "lb"
    ln = "ln"
    lo = "lo"
    lt = "lt"
    lv = "lv"
    mg = "mg"
    mi = "mi"
    mk = "mk"
    ml = "ml"
    mn = "mn"
    mr = "mr"
    ms = "ms"
    mt = "mt"
    my = "my"
    ne = "ne"
    nl = "nl"
    nn = "nn"
    no = "no"
    oc = "oc"
    pa = "pa"
    pl = "pl"
    ps = "ps"
    pt = "pt"
    ro = "ro"
    ru = "ru"
    sa = "sa"
    sd = "sd"
    si = "si"
    sk = "sk"
    sl = "sl"
    sn = "sn"
    so = "so"
    sq = "sq"
    sr = "sr"
    su = "su"
    sv = "sv"
    sw = "sw"
    ta = "ta"
    te = "te"
    tg = "tg"
    th = "th"
    tk = "tk"
    tl = "tl"
    tr = "tr"
    tt = "tt"
    uk = "uk"
    ur = "ur"
    uz = "uz"
    vi = "vi"
    yi = "yi"
    yo = "yo"
    yue = "yue"
    zh = "zh"

class ChunkLevelEnum(str, Enum):
    segment = "segment"

class VersionEnum(str, Enum):
    v3 = "3"

class WhisperInput(BaseModel):
    audio_url: str = Field(..., description="URL of the audio file to transcribe. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav or webm.")
    task: TaskEnum = Field(default=TaskEnum.transcribe, description="Task to perform on the audio file. Either transcribe or translate.")
    language: LanguageEnum = Field(default=LanguageEnum.en, description="Language of the audio file. If translate is selected as the task, the audio will be translated to English, regardless of the language selected.")
    chunk_level: ChunkLevelEnum = Field(default=ChunkLevelEnum.segment, description="Level of the chunks to return.")
    version: VersionEnum = Field(default=VersionEnum.v3, description="Version of the model to use. All of the models are the Whisper large variant.")

class WhisperChunk(BaseModel):
    timestamp: List[float] = Field(..., description="Start and end timestamp of the chunk")
    text: str = Field(..., description="Transcription of the chunk")

class WhisperOutput(BaseModel):
    text: str = Field(..., description="Transcription of the audio file")
    chunks: List[WhisperChunk] = Field(..., description="Timestamp chunks of the audio file")

@router.websocket("/ws/WhisperTTS")
async def whisper_websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("WebSocket connection established")

    try:
        while True:
            data = await websocket.receive_text()
            logger.info(f"Received data: {data}")

            try:
                input_data = json.loads(data)
                whisper_input = WhisperInput(**input_data)
                logger.info(f"Validated input: {whisper_input}")

                # Submit the request to fal.ai
                handler = fal_client.submit(
                    "fal-ai/wizper",
                    arguments=whisper_input.dict()
                )

                # Wait for the result
                result = await asyncio.to_thread(handler.get)
                logger.info("Received result from fal.ai")

                # Validate the output
                whisper_output = WhisperOutput(**result)
                logger.info("Validated output")

                # Send the result back to the client
                await websocket.send_json(whisper_output.dict())
                logger.info("Sent result to client")

            except json.JSONDecodeError:
                error_msg = "Invalid JSON received"
                logger.error(error_msg)
                await websocket.send_json({"error": error_msg})

            except ValueError as ve:
                error_msg = f"Invalid input: {str(ve)}"
                logger.error(error_msg)
                await websocket.send_json({"error": error_msg})

            except Exception as e:
                error_msg = f"An error occurred: {str(e)}"
                logger.error(error_msg)
                await websocket.send_json({"error": error_msg})

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected")

    finally:
        logger.info("Closing WebSocket connection")
        await websocket.close()

# File upload functionality
@router.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        url = await asyncio.to_thread(fal_client.upload, contents, file.content_type)
        return {"url": url}
    except Exception as e:
        logger.error(f"File upload failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")
