# backend/routers/post/llm_inference/openai_post.py
## DO NOT REVERT BACK TO OPENAI>1.0

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field, HttpUrl, validator
from typing import Optional, List, Dict, Any
from openai import OpenAI, OpenAIError  # Import the OpenAI module
import tiktoken  # For counting tokens
import json
import os

router = APIRouter()

MODEL_MAX_TOKENS = {
    "gpt-4": 8192,
    "gpt-3.5-turbo": 4096, # depreciated; DO NOT USE
    "gpt-4o-mini": 8192,  # need to add the actual MAX
    # TODO: add llama3.2, and other models
}

def parse_ollama_response(response: str) -> dict:
    try:
        response_json = json.loads(response)  # Assuming response is a JSON string.
        parsed_response = {
            "model": response_json.get("model"),
            "response": response_json.get("response"),
            "total_duration": response_json.get("total_duration"),
            "prompt_eval_count": response_json.get("prompt_eval_count"),
            "eval_count": response_json.get("eval_count"),
            "load_duration": response_json.get("load_duration"),
            "context": response_json.get("context"),
            # Optionally: calculate tokens per second or other derived stats.
        }
        return parsed_response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error parsing Ollama response: {str(e)}")

# Pydantic Model for Request Configuration with all parameters
class OpenAIRequestConfig(BaseModel):
    api_url: HttpUrl = Field(..., description="API URL for OpenAI or Ollama provider")
    api_key: Optional[str] = Field(None, description="API Key for authentication, can fallback to environment")
    model: str = Field(..., description="Model to use (e.g., gpt-4, llama3.2:1b, etc.)")
    system_prompt: Optional[str] = Field(None, description="System prompt to set the role/context of the model")
    prompt: Optional[str] = Field(None, description="User prompt text to send to the model")
    messages: Optional[List[Dict[str, str]]] = Field(None, description="List of message dictionaries for multi-turn conversations.")
    temperature: Optional[float] = Field(0.7, description="Controls the randomness of the response, between 0 and 1. Higher values make output more random.")
    max_tokens: Optional[int] = Field(256, description="Maximum number of tokens to generate in the response. Applies to Ollama models.")
    max_completion_tokens: Optional[int] = Field(None, description="Maximum number of tokens for completion in OpenAI models.")
    top_p: Optional[float] = Field(1.0, description="Controls the diversity via nucleus sampling. 0.5 means half of all likelihood-weighted options are considered.")
    frequency_penalty: Optional[float] = Field(0.0, description="Penalty for repeated tokens. Higher values discourage repetition.")
    presence_penalty: Optional[float] = Field(0.0, description="Penalty for using new topics. Higher values encourage novelty.")
    stop: Optional[List[str]] = Field(None, description="Up to 4 sequences where the API will stop generating further tokens.")
    n: Optional[int] = Field(1, description="Number of completions to generate for each prompt.")
    logit_bias: Optional[Dict[str, float]] = Field(None, description="Modify the likelihood of specified tokens appearing in the completion.")
    stream: Optional[bool] = Field(False, description="Enable or disable streaming responses.") 
    user: Optional[str] = Field(None, description="User ID for tracking purposes (not supported in Ollama).")
    extra_params: Optional[Dict[str, Any]] = Field(None, description="Custom parameters for edge cases or provider-specific functionality.")

    # Validators to enforce parameter constraints
    @validator('temperature')
    def temperature_must_be_between_0_and_1(cls, v):
        if not 0 <= v <= 1:
            raise ValueError('temperature must be between 0 and 1')
        return v

    @validator('top_p')
    def top_p_must_be_between_0_and_1(cls, v):
        if not 0 <= v <= 1:
            raise ValueError('top_p must be between 0 and 1')
        return v

    @validator('n')
    def n_must_be_positive(cls, v):
        if v < 1:
            raise ValueError('n must be a positive integer')
        return v

    # Additional validators can be added as needed

# Token counter function using tiktoken to check token usage before sending requests
def count_tokens(model: str, prompt: str) -> int:
    try:
        enc = tiktoken.encoding_for_model(model)
    except KeyError:
        # If the model is not recognized by tiktoken, use a default encoding
        enc = tiktoken.get_encoding("cl100k_base")
    return len(enc.encode(prompt))

# Route to handle OpenAI API or Ollama API requests dynamically
@router.post("/generate-text/")
async def generate_text(config: OpenAIRequestConfig):
    try:
        # Determine if the request is for Ollama based on the API URL or model name
        # NOTE: The API URL may not contain 'ollama', and the model may not always contain 'llama'
        # the api will really say `:11434/v1` not ollama and the model may not always say llama often times it wont it'll be named otherwise 
        is_ollama = "ollama" in str(config.api_url).lower() or "llama" in config.model.lower()

        if is_ollama:
            # Handle Ollama model request
            api_key = config.api_key or os.getenv("OLLAMA_API_KEY")
            if not api_key:
                raise HTTPException(status_code=401, detail="OLLAMA_API_KEY is missing and not found in environment variables")
            client = OpenAI(
                api_key=api_key,
                base_url=str(config.api_url)
            )

            # Construct the message structure for Ollama models using system prompts
            # NOTE: What if the message structure involves multi-messages, additionally what if the messages are not entirely sequential
            if config.messages:
                messages = config.messages
            else:
                messages = []
                if config.system_prompt:
                    messages.append({"role": "system", "content": config.system_prompt})
                if config.prompt:
                    messages.append({"role": "user", "content": config.prompt})
                if not messages:
                    raise HTTPException(status_code=400, detail="Either messages or prompt must be provided")

            # Construct the request dynamically with all possible parameters
            # NOTE: I worry all the parameters may not send in the request as of now..
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
                # "user": config.user,  # User not supported in Ollama?
                "stream": config.stream  # Include the stream parameter here
            }

            # Add any extra parameters
            if config.extra_params:
                completion_args.update(config.extra_params)

            # Filter out parameters that are not supported by Ollama
            ollama_supported_params = {
                "model", "messages", "temperature", "max_tokens", "top_p", "frequency_penalty", "presence_penalty",
                "stop", "n", "logit_bias", "stream"
            }
            completion_args = {k: v for k, v in completion_args.items() if k in ollama_supported_params}

            # Handle streaming if enabled
            if config.stream:
                # Handle streaming response
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
                return StreamingResponse(stream_generator(), media_type='text/plain')
            else:
                # Standard Ollama completion
                response = client.chat.completions.create(**completion_args)
                if response.choices and len(response.choices) > 0:
                    return {"result": response.choices[0].message.content.strip()}
                else:
                    raise HTTPException(status_code=500, detail="No response from Ollama model.")

        else:
            # Handle OpenAI API or other remote provider requests
            # Set the API key from request or environment variable
            api_key = config.api_key or os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise HTTPException(status_code=401, detail="API Key is missing and not found in environment variables")

            # Instantiate the OpenAI client with the provided API key and base URL
            client = OpenAI(
                api_key=api_key,
                base_url=str(config.api_url)
            )

            # Token counting to prevent exceeding model limits
            token_count = 0
            if config.prompt:
                token_count += count_tokens(config.model, config.prompt)
            if config.system_prompt:
                token_count += count_tokens(config.model, config.system_prompt)
            if config.messages:
                for message in config.messages:
                    token_count += count_tokens(config.model, message.get('content', ''))

            if config.max_completion_tokens is None:
                config.max_completion_tokens = config.max_tokens or MODEL_MAX_TOKENS.get(config.model, 4096)
            if token_count > config.max_completion_tokens:
                raise HTTPException(status_code=400, detail=f"Token count {token_count} exceeds max_completion_tokens limit")

            # Construct the message structure for GPT-4 or similar models using system prompts
            # NOTE: i worry this message structure will not allow for the best scale to conversations or other purposes
            if config.messages:
                messages = config.messages
            else:
                messages = []
                if config.system_prompt:
                    messages.append({"role": "system", "content": config.system_prompt})
                if config.prompt:
                    messages.append({"role": "user", "content": config.prompt})
                if not messages:
                    raise HTTPException(status_code=400, detail="Either messages or prompt must be provided")

            # Construct the request dynamically with all possible parameters
            completion_args = {
                "model": config.model,
                "messages": messages,
                "temperature": config.temperature,
                "max_tokens": config.max_completion_tokens,  # OpenAI uses 'max_tokens' for completion
                "top_p": config.top_p,
                "frequency_penalty": config.frequency_penalty,
                "presence_penalty": config.presence_penalty,
                "stop": config.stop,
                "n": config.n,
                "logit_bias": config.logit_bias,
                "user": config.user,
                "stream": config.stream  # Include the stream parameter here
            }

            # Add any extra parameters
            if config.extra_params:
                completion_args.update(config.extra_params)

            # Handle streaming if enabled
            # TODO: THIS CURRENTLY FAILS; it has no response but the request is made and reported to the server as a 200, we have an example of this done independently from the rest of the script
            if config.stream:
                # Handle streaming response
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
                return StreamingResponse(stream_generator(), media_type='text/plain')
            else:
                # Standard OpenAI completion
                response = client.chat.completions.create(**completion_args)
                if response.choices and len(response.choices) > 0:
                    return {"result": response.choices[0].message.content.strip()}
                else:
                    raise HTTPException(status_code=500, detail="No response from OpenAI model.")

    except OpenAIError as e:
        raise HTTPException(status_code=500, detail=f"OpenAI API Error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server Error: {str(e)}")
