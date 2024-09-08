# backend/websocket/routers/LLM/claude.py
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional
import os
from anthropic import Anthropic, AsyncAnthropic
import logging
import json

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

# Initialize Anthropic client
anthropic = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY") or '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')
async_anthropic = AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY") or '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')

class Message(BaseModel):
    role: str
    content: str

class CreateMessageRequest(BaseModel):
    max_tokens: int
    messages: List[Message]
    model: str
    stream: Optional[bool] = False
    system: Optional[str] = None  # Add this line to include the system prompt

@router.post("/messages")
async def create_message(request: CreateMessageRequest):
    # Input: CreateMessageRequest object containing:
    # - max_tokens: int
    # - messages: List[Message]
    # - model: str
    # - stream: Optional[bool]
    # - system: Optional[str]
    # logger.info(f"Received POST request: {json.dumps(request.dict(), indent=2)}")
    try:
        if request.stream:
            # Output: StreamingResponse object for streaming responses
            logger.info("Streaming response requested")
            return StreamingResponse(stream_message(request), media_type="text/event-stream")
        else:
            # Output: Dictionary containing:
            # - content: str (generated message content)
            # - usage: dict (token usage information)
            logger.info("Non-streaming response requested")
            message = anthropic.messages.create(
                max_tokens=request.max_tokens,
                messages=[m.dict() for m in request.messages],
                model=request.model,
                system=request.system,
            )
            response = {
                "content": message.content[0].text if message.content else "",
                "usage": {
                    "input_tokens": message.usage.input_tokens,
                    "output_tokens": message.usage.output_tokens
                }
            }
            # logger.info(f"Response: {json.dumps(response, indent=2)}")
            return response
    except Exception as e:
        # Output: HTTPException with status code 500 and error details
        logger.error(f"Error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

async def stream_message(request: CreateMessageRequest):
    # Input: CreateMessageRequest object (same as create_message)
    # Output: Generator yielding SSE (Server-Sent Events) formatted strings
    try:
        stream = await async_anthropic.messages.create(
            max_tokens=request.max_tokens,
            messages=[m.dict() for m in request.messages],
            model=request.model,
            system=request.system,
            stream=True,
        )
        async for event in stream:
            # Yield different event types based on the streaming response
            event_json = event.model_dump_json()
            logger.info(f"Streaming event: {event_json}")
            if event.type == "content_block_start":
                yield f"event: content_block_start\ndata: {event_json}\n\n"
            elif event.type == "content_block_delta":
                yield f"event: content_block_delta\ndata: {event_json}\n\n"
            elif event.type == "content_block_stop":
                yield f"event: content_block_stop\ndata: {event_json}\n\n"
            elif event.type == "message_delta":
                yield f"event: message_delta\ndata: {event_json}\n\n"
            elif event.type == "message_stop":
                yield f"event: message_stop\ndata: {event_json}\n\n"
    except Exception as e:
        # Yield an error event if an exception occurs
        logger.error(f"Error in streaming: {str(e)}")
        yield f"event: error\ndata: {str(e)}\n\n"