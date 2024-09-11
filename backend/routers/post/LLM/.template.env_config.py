# backend/websocket/routers/LLM/env_config.py

import os

ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY") or 'api_key'