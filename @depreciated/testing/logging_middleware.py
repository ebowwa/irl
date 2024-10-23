# File: backend/middleware/logging_middleware.py
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from fastapi import Request
import logging
import json

logger = logging.getLogger("uvicorn")

class LoggingMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, log_request_body=True, log_response_body=True):
        super().__init__(app)
        self.log_request_body = log_request_body
        self.log_response_body = log_response_body

    async def dispatch(self, request: Request, call_next):
        # Log Request Details
        request_body = await request.body()
        if self.log_request_body:
            logger.debug(f"Request URL: {request.url}")
            logger.debug(f"Request method: {request.method}")
            logger.debug(f"Request headers: {dict(request.headers)}")
            logger.debug(f"Request body: {request_body.decode('utf-8')}")

        # Re-create the request object with the original body so FastAPI can process it
        request = Request(scope=request.scope, receive=request._receive)
        async def receive():
            return {"type": "http.request", "body": request_body}
        request._receive = receive

        # Call the next middleware or route handler
        response = await call_next(request)

        # Log Response Details
        if self.log_response_body:
            response_body = b""
            async for chunk in response.body_iterator:
                response_body += chunk
            logger.debug(f"Response status: {response.status_code}")
            logger.debug(f"Response body: {response_body.decode('utf-8')}")

            # Return the response to the client with the logged response body
            return Response(content=response_body, status_code=response.status_code, headers=dict(response.headers))

        return response