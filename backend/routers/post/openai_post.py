from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, HttpUrl
import openai  # Import the entire openai module
import tiktoken  # For counting tokens
import subprocess  # To call local model like Ollama
from typing import Optional, Dict, Any
import json
import os

router = APIRouter()
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
    api_url: HttpUrl = Field(..., description="API URL for OpenAI or other provider")
    api_key: Optional[str] = Field(None, description="API Key for authentication, can fallback to environment")
    model: str = Field(..., description="Model to use (e.g., gpt-4o-mini, llama3.2:1b, etc.)")
    system_prompt: Optional[str] = Field(None, description="System prompt to set the role/context of the model")
    prompt: str = Field(..., description="User prompt text to send to the model")
    temperature: Optional[float] = 0.7  # Default temperature
    max_tokens: Optional[int] = 256  # Default token limit
    top_p: Optional[float] = 1.0  # Default is full probability distribution
    frequency_penalty: Optional[float] = 0.0  # Avoid repeating content
    presence_penalty: Optional[float] = 0.0  # Encourage novel topics
    stop: Optional[list] = None  # Optional stopping sequences
    n: Optional[int] = 1  # Number of completions to generate
    logit_bias: Optional[Dict[str, int]] = None  # Control bias of individual tokens
    stream: Optional[bool] = False  # Enable streaming responses if needed
    user: Optional[str] = None  # For tracking purposes (e.g., personalization)
    extra_params: Optional[Dict[str, Any]] = None  # Custom params for any edge case

# Token counter function using tiktoken to check token usage before sending requests
def count_tokens(model: str, prompt: str) -> int:
    if "ollama" not in model:  # Only for OpenAI models
        enc = tiktoken.encoding_for_model(model)
        return len(enc.encode(prompt))
    return 0  # Ollama natively counts tokens


# Function to handle local Ollama model requests
def run_ollama(prompt: str, model: str, options: Optional[Dict[str, Any]] = None) -> str:
    """Run a local model using Ollama with advanced options."""
    command = ["ollama", "run", model, "--prompt", prompt]
    
    # Add advanced options as necessary (e.g., temperature, top_p)
    if options:
        for option, value in options.items():
            command.append(f"--{option}")
            command.append(str(value))
    
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        raise HTTPException(status_code=500, detail="Error running local Ollama model.")
    return result.stdout.strip()


# Route to handle OpenAI API or Local Ollama API requests dynamically
@router.post("/generate-text/")
async def generate_text(config: OpenAIRequestConfig):
    try:
        if "ollama" in str(config.api_url):
            # Add context to the prompt for conversational memory
            if config.extra_params and "context" in config.extra_params:
                prompt_with_context = {"prompt": config.prompt, "context": config.extra_params["context"]}
            else:
                prompt_with_context = {"prompt": config.prompt}

            response = run_ollama(**prompt_with_context, model=config.model)
            response_data = parse_ollama_response(response)
            return {"result": response_data}
        # Otherwise, use OpenAI API or other remote provider
        # Set the API key from request or environment variable
        api_key = config.api_key or os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise HTTPException(status_code=401, detail="API Key is missing and not found in environment variables")
        
        # Ensure the API URL is passed as a string
        api_url = str(config.api_url)

        # Instantiate the OpenAI client with the provided API key and base URL
        client = openai.OpenAI(api_key=api_key, base_url=api_url)

        # Token counting to prevent exceeding model limits
        token_count = count_tokens(config.model, config.prompt)
        if token_count > config.max_tokens:
            raise HTTPException(status_code=400, detail=f"Token count {token_count} exceeds max_tokens limit")

        # Construct the message structure for GPT-4o-mini models using system prompts
        if config.system_prompt:
            messages = [
                {"role": "system", "content": config.system_prompt},
                {"role": "user", "content": config.prompt}
            ]
        else:
            messages = [{"role": "user", "content": config.prompt}]

        # Construct the request dynamically with all possible parameters
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
            "user": config.user
        }

        # Add any extra parameters
        if config.extra_params:
            completion_args.update(config.extra_params)

        # Handle streaming if enabled
        if config.stream:
            response = []
            stream = client.chat.completions.create(stream=True, **completion_args)
            for chunk in stream:
                response.append(chunk.choices[0].delta.get("content", ""))
            return {"streamed_response": ''.join(response)}
        else:
            # Standard OpenAI completion
            response = client.chat.completions.create(**completion_args)
            # Access the content attribute directly
            return {"result": response.choices[0].message.content.strip()}

    except openai.APIError as e:
        raise HTTPException(status_code=500, detail=f"OpenAI API Error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server Error: {str(e)}")
