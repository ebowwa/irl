# File: socket/models.py
from pydantic import BaseModel, Field
from typing import List
from route.features.whisper_socket.whisper_constants import TaskEnum, WhisperAvailableLanguagesEnum, ChunkLevelEnum, VersionEnum

class WhisperInput(BaseModel):
    audio_url: str = Field(..., description="URL of the audio file to transcribe. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav or webm.")
    task: TaskEnum = Field(default=TaskEnum.transcribe, description="Task to perform on the audio file. Either transcribe or translate.")
    language: WhisperAvailableLanguagesEnum = Field(default=WhisperAvailableLanguagesEnum.en, description="Language of the audio file. If translate is selected as the task, the audio will be translated to English, regardless of the language selected.")
    chunk_level: ChunkLevelEnum = Field(default=ChunkLevelEnum.segment, description="Level of the chunks to return.")
    version: VersionEnum = Field(default=VersionEnum.v3, description="Version of the model to use. All of the models are the Whisper large variant.")

class WhisperChunk(BaseModel):
    timestamp: List[float] = Field(..., description="Start and end timestamp of the chunk")
    text: str = Field(..., description="Transcription of the chunk")

class WhisperOutput(BaseModel):
    text: str = Field(..., description="Transcription of the audio file")
    chunks: List[WhisperChunk] = Field(..., description="Timestamp chunks of the audio file")
