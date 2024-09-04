# backend/websocket/routers/LLM/claude.py
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional
import os
from anthropic import Anthropic, AsyncAnthropic

router = APIRouter()

# Initialize Anthropic client
anthropic = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
async_anthropic = AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

class Message(BaseModel):
    role: str
    content: str

class CreateMessageRequest(BaseModel):
    max_tokens: int
    messages: List[Message]
    model: str
    stream: Optional[bool] = False

@router.post("/messages")
async def create_message(request: CreateMessageRequest):
    try:
        if request.stream:
            return StreamingResponse(stream_message(request), media_type="text/event-stream")
        else:
            message = anthropic.messages.create(
                max_tokens=request.max_tokens,
                messages=[m.dict() for m in request.messages],
                model=request.model,
            )
            return {"content": message.content, "usage": message.usage.dict()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def stream_message(request: CreateMessageRequest):
    try:
        stream = await async_anthropic.messages.create(
            max_tokens=request.max_tokens,
            messages=[m.dict() for m in request.messages],
            model=request.model,
            stream=True,
        )
        async for event in stream:
            if event.type == "content_block_start":
                yield f"event: content_block_start\ndata: {event.model_dump_json()}\n\n"
            elif event.type == "content_block_delta":
                yield f"event: content_block_delta\ndata: {event.model_dump_json()}\n\n"
            elif event.type == "content_block_stop":
                yield f"event: content_block_stop\ndata: {event.model_dump_json()}\n\n"
            elif event.type == "message_delta":
                yield f"event: message_delta\ndata: {event.model_dump_json()}\n\n"
            elif event.type == "message_stop":
                yield f"event: message_stop\ndata: {event.model_dump_json()}\n\n"
    except Exception as e:
        yield f"event: error\ndata: {str(e)}\n\n"