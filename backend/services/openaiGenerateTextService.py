# backend/services/openai_generate_text_service.py
# -------------------------------------
# DO NOT REVERT BACK TO OPENAI>1.0
# -------------------------------------
# Service for OpenAI and Ollama LLM inference
# Handles dynamic API requests and streaming responses
# -------------------------------------

from fastapi import HTTPException
from pydantic import BaseModel, Field, HttpUrl, validator
from typing import Optional, List, Dict, Any
from openai import OpenAI, OpenAIError  # Import the OpenAI module for LLM interactions
import tiktoken  # For counting tokens used in prompts
import json
import os

# -------------------------------------
# Constants
# -------------------------------------
# Define maximum token limits for various models
MODEL_MAX_TOKENS = {
    "gpt-4": 8192,
    "gpt-3.5-turbo": 4096,  # Deprecated; DO NOT USE
    "gpt-4o-mini": 8192,  # Placeholder; adjust actual max token limit
    # TODO: Add additional models such as llama3.2 or others
}

# -------------------------------------
# Utility Function: Parse Ollama Response
# -------------------------------------
def parse_ollama_response(response: str) -> dict:
    """Parses JSON response from Ollama API."""
    try:
        response_json = json.loads(response)
        parsed_response = {
            "model": response_json.get("model"),
            "response": response_json.get("response"),
            "total_duration": response_json.get("total_duration"),
            "prompt_eval_count": response_json.get("prompt_eval_count"),
            "eval_count": response_json.get("eval_count"),
            "load_duration": response_json.get("load_duration"),
            "context": response_json.get("context"),
            # Optional: Add token per second calculation or other derived metrics
        }
        return parsed_response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error parsing Ollama response: {str(e)}")


# -------------------------------------
# Pydantic Model for API Configuration
# -------------------------------------
class OpenAIRequestConfig(BaseModel):
    """Pydantic Model for Request Configuration - supports OpenAI and Ollama API"""
    
    api_url: HttpUrl = Field(..., description="API URL for OpenAI or Ollama provider")
    api_key: Optional[str] = Field(None, description="API Key for authentication (can fallback to environment)")
    model: str = Field(..., description="Model to use (e.g., gpt-4, llama3.2:1b, etc.)")
    system_prompt: Optional[str] = Field(None, description="System prompt to define the role/context")
    prompt: Optional[str] = Field(None, description="User prompt text to send to the model")
    messages: Optional[List[Dict[str, str]]] = Field(None, description="Messages for multi-turn conversations.")
    temperature: Optional[float] = Field(0.7, description="Response randomness (0-1). Higher value for more randomness.")
    max_tokens: Optional[int] = Field(256, description="Max tokens to generate in response (for Ollama).")
    max_completion_tokens: Optional[int] = Field(None, description="Max tokens for completion (for OpenAI).")
    top_p: Optional[float] = Field(1.0, description="Nucleus sampling (0-1). Lower values reduce output diversity.")
    frequency_penalty: Optional[float] = Field(0.0, description="Penalty for repeated tokens (discourages repetition).")
    presence_penalty: Optional[float] = Field(0.0, description="Penalty for new topics (higher values encourage novelty).")
    stop: Optional[List[str]] = Field(None, description="Sequences where API will stop generating further tokens.")
    n: Optional[int] = Field(1, description="Number of completions to generate per prompt.")
    logit_bias: Optional[Dict[str, float]] = Field(None, description="Bias for specified token likelihood.")
    stream: Optional[bool] = Field(False, description="Enable or disable streaming responses.")
    user: Optional[str] = Field(None, description="User ID for tracking (OpenAI only).")
    extra_params: Optional[Dict[str, Any]] = Field(None, description="Additional custom parameters.")

    # -------------------------------------
    # Validators for Parameter Constraints
    # -------------------------------------
    @validator('temperature')
    def temperature_must_be_between_0_and_1(cls, v):
        """Ensure temperature is between 0 and 1"""
        if not 0 <= v <= 1:
            raise ValueError('Temperature must be between 0 and 1.')
        return v

    @validator('top_p')
    def top_p_must_be_between_0_and_1(cls, v):
        """Ensure top_p is between 0 and 1"""
        if not 0 <= v <= 1:
            raise ValueError('Top_p must be between 0 and 1.')
        return v

    @validator('n')
    def n_must_be_positive(cls, v):
        """Ensure n is a positive integer"""
        if v < 1:
            raise ValueError('n must be a positive integer.')
        return v


# -------------------------------------
# Utility Function: Count Tokens
# -------------------------------------
def count_tokens(model: str, prompt: str) -> int:
    """Uses tiktoken to count tokens based on model and prompt."""
    try:
        enc = tiktoken.encoding_for_model(model)
    except KeyError:
        # Use default encoding if model is not recognized
        enc = tiktoken.get_encoding("cl100k_base")
    return len(enc.encode(prompt))


# -------------------------------------
# Service Function: Generate Text
# -------------------------------------
def generate_text_service(config: OpenAIRequestConfig):
    """Service function to handle text generation via OpenAI or Ollama models."""
    try:
        # Determine if using Ollama based on API URL or model name
        is_ollama = "ollama" in str(config.api_url).lower() or "llama" in config.model.lower()

        # -------------------------------------
        # Handle Ollama Requests
        # -------------------------------------
        if is_ollama:
            api_key = config.api_key or os.getenv("OLLAMA_API_KEY")
            if not api_key:
                raise HTTPException(status_code=401, detail="OLLAMA_API_KEY is missing and not found in environment variables")
            client = OpenAI(api_key=api_key, base_url=str(config.api_url))

            # Construct messages with optional system prompt and user prompt
            messages = config.messages or []
            if config.system_prompt:
                messages.append({"role": "system", "content": config.system_prompt})
            if config.prompt:
                messages.append({"role": "user", "content": config.prompt})
            if not messages:
                raise HTTPException(status_code=400, detail="Either messages or prompt must be provided.")

            # Prepare arguments for the request
            completion_args = {
                "model": config.model,
                "messages": messages,
                "temperature": config.temperature,
                "max_tokens": config.max_tokens,
                "top_p": config.top_p,
                "frequency_penalty": config.frequency_penalty,
                "presence_penalty": config.presence_penalty,
                "stop": config.stop,
                "n": config.n,
                "logit_bias": config.logit_bias,
                "stream": config.stream
            }

            # Add extra parameters if present
            if config.extra_params:
                completion_args.update(config.extra_params)

            # Filter unsupported parameters for Ollama
            ollama_supported_params = {
                "model", "messages", "temperature", "max_tokens", "top_p", "frequency_penalty", "presence_penalty",
                "stop", "n", "logit_bias", "stream"
            }
            completion_args = {k: v for k, v in completion_args.items() if k in ollama_supported_params}

            # Handle streaming responses
            if config.stream:
                def stream_generator():
                    try:
                        stream = client.chat.completions.create(**completion_args)
                        for chunk in stream:
                            if chunk.choices and len(chunk.choices) > 0:
                                delta = chunk.choices[0].delta
                                content = getattr(delta, 'content', None)
                                if content:
                                    yield content
                    except OpenAIError as e:
                        yield f"\nError during streaming: {str(e)}"
                return stream_generator()
            else:
                # Standard Ollama response
                response = client.chat.completions.create(**completion_args)
                if response.choices and len(response.choices) > 0:
                    return {"result": response.choices[0].message.content.strip()}
                else:
                    raise HTTPException(status_code=500, detail="No response from Ollama model.")

        # -------------------------------------
        # Handle OpenAI Requests
        # -------------------------------------
        else:
            api_key = config.api_key or os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise HTTPException(status_code=401, detail="API Key is missing and not found in environment variables")

            client = OpenAI(api_key=api_key, base_url=str(config.api_url))

            # Count tokens to prevent exceeding model limits
            token_count = 0
            if config.prompt:
                token_count += count_tokens(config.model, config.prompt)
            if config.system_prompt:
                token_count += count_tokens(config.model, config.system_prompt)
            if config.messages:
                for message in config.messages:
                    token_count += count_tokens(config.model, message.get('content', ''))

            # Determine max tokens for completion
            config.max_completion_tokens = config.max_completion_tokens or config.max_tokens or MODEL_MAX_TOKENS.get(config.model, 4096)
            if token_count > config.max_completion_tokens:
                raise HTTPException(status_code=400, detail=f"Token count {token_count} exceeds max_completion_tokens limit.")

            # Construct message structure
            messages = config.messages or []
            if config.system_prompt:
                messages.append({"role": "system", "content": config.system_prompt})
            if config.prompt:
                messages.append({"role": "user", "content": config.prompt})
            if not messages:
                raise HTTPException(status_code=400, detail="Either messages or prompt must be provided.")

            # Prepare completion arguments
            completion_args = {
                "model": config.model,
                "messages": messages,
                "temperature": config.temperature,
                "max_tokens": config.max_completion_tokens,
                "top_p": config.top_p,
                "frequency_penalty": config.frequency_penalty,
                "presence_penalty": config.presence_penalty,
                "stop": config.stop,
                "n": config.n,
                "logit_bias": config.logit_bias,
                "user": config.user,
                "stream": config.stream
            }

            if config.extra_params:
                completion_args.update(config.extra_params)

            # Handle streaming responses
            if config.stream:
                def stream_generator():
                    try:
                        stream = client.chat.completions.create(**completion_args)
                        for chunk in stream:
                            if chunk.choices and len(chunk.choices) > 0:
                                delta = chunk.choices[0].delta
                                content = getattr(delta, 'content', None)
                                if content:
                                    yield content
                    except OpenAIError as e:
                        yield f"\nError during streaming: {str(e)}"
                return stream_generator()
            else:
                # Standard OpenAI response
                response = client.chat.completions.create(**completion_args)
                if response.choices and len(response.choices) > 0:
                    return {"result": response.choices[0].message.content.strip()}
                else:
                    raise HTTPException(status_code=500, detail="No response from OpenAI model.")

    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"OpenAI API Error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server Error: {str(e)}")
