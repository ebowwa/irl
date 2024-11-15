import ssl
from functools import partial
from typing import Optional
import google.generativeai as genai
import time
import httpx
import asyncio
from contextlib import asynccontextmanager

def configure_ssl_context() -> ssl.SSLContext:
    """Configure SSL context with proper security settings."""
    context = ssl.create_default_context()
    context.set_ciphers('ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256')
    context.options |= ssl.OP_NO_TLSv1 | ssl.OP_NO_TLSv1_1
    return context

def upload_to_gemini_sync(file_path: str, mime_type: Optional[str] = None):
    """Synchronous version of upload to Gemini with SSL retry logic."""
    ssl_context = configure_ssl_context()
    for attempt in range(3):
        try:
            return genai.upload_file(file_path, mime_type=mime_type)
        except ssl.SSLError as e:
            if attempt == 2:
                raise
            time.sleep(1 * (attempt + 1))  # Exponential backoff
