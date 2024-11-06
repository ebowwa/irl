# File: backend/middleware.py

from fastapi.middleware.cors import CORSMiddleware

def setup_cors(app):
    # CORS Middleware configuration
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Allow requests from all origins
        allow_credentials=True,
        allow_methods=["*"],  # Allow all HTTP methods (GET, POST, etc.)
        allow_headers=["*"],  # Allow all headers
    )
