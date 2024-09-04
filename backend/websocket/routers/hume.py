from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import base64
import json
import websockets
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()
HUME_API_KEY = "5pWMCZa4nJ9cKjVK4VwtfBbb3fK4SgUKGfHja2IxQubbWzpU"  # Replace with your actual Hume API key
HUME_WS_URL = "wss://api.hume.ai/v0/stream/models"

@router.websocket("/ws/hume")
async def hume_websocket(websocket: WebSocket):
    await websocket.accept()
    logger.info("Client WebSocket connection accepted")

    try:
        async with websockets.connect(
            HUME_WS_URL,
            extra_headers={"X-Hume-Api-Key": HUME_API_KEY}
        ) as hume_ws:
            logger.info("Connected to Hume API WebSocket")

            while True:
                data = await websocket.receive_text()
                
                hume_message = {
                    "data": base64.b64encode(data.encode()).decode(),
                    "models": {
                        "face": {},
                        "prosody": {},
                        "language": {
                            "granularity": "word"
                        }
                    }
                }

                await hume_ws.send(json.dumps(hume_message))
                hume_response = await hume_ws.recv()
                await websocket.send_text(hume_response)

    except websockets.exceptions.InvalidStatusCode as e:
        logger.error(f"Failed to connect to Hume API: Status code {e.status_code}")
        await websocket.send_text(json.dumps({"error": f"Failed to connect to Hume API: {e.status_code}"}))
    except WebSocketDisconnect:
        logger.info("Client WebSocket disconnected")
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        await websocket.send_text(json.dumps({"error": f"Unexpected error: {str(e)}"}))