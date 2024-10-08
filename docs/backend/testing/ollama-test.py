import ollama
import asyncio
from typing import List, Dict, Union

def get_ollama_response(
    model: str = 'llama3.2:1b',
    messages: List[Dict[str, str]] = None,
    stream: bool = False,
    async_mode: bool = False,
    temperature: float = 0.7,
) -> Union[str, None]:
    """
    Function to get a response from the Ollama model.
    
    Parameters:
    - model (str): The name of the model to use (default is 'llama3.2:1b').
    - messages (List[Dict[str, str]]): A list of messages in the format [{"role": "user", "content": "message"}].
    - stream (bool): Whether to stream the response (default is False).
    - async_mode (bool): Whether to use asynchronous response handling.
    - temperature (float): Temperature parameter for response creativity.
    
    Returns:
    - Union[str, None]: The model's response as a string or None in case of an error.
    """
    
    try:
        if messages is None:
            raise ValueError("Messages list cannot be empty.")
        
        if async_mode:
            return asyncio.run(async_ollama_chat(model, messages, stream))
        else:
            return sync_ollama_chat(model, messages, stream, temperature)
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return None

def sync_ollama_chat(model: str, messages: List[Dict[str, str]], stream: bool, temperature: float):
    """
    Handles synchronous chat with Ollama.
    """
    response = ""
    
    if stream:
        # Streaming mode
        stream = ollama.chat(
            model=model, 
            messages=messages, 
            stream=True,
            temperature=temperature
        )
        for chunk in stream:
            response += chunk['message']['content']
    else:
        # Non-streaming
        result = ollama.chat(
            model=model, 
            messages=messages,
            temperature=temperature
        )
        response = result['message']['content']
    
    return response

async def async_ollama_chat(model: str, messages: List[Dict[str, str]], stream: bool):
    """
    Handles asynchronous chat with Ollama.
    """
    client = ollama.AsyncClient()

    if stream:
        # Async streaming
        async for part in await client.chat(model=model, messages=messages, stream=True):
            print(part['message']['content'], end='', flush=True)
    else:
        # Async non-streaming
        result = await client.chat(model=model, messages=messages)
        print(result['message']['content'])


# Example usage

if __name__ == "__main__":
    prompt = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain the concept of quantum physics."}
    ]
    
    response = get_ollama_response(
        model='llama3.2:1b',  # Using the llama3.2:1b model
        messages=prompt,
        stream=False,
        async_mode=False,
        temperature=0.6
    )
    
    print(f"Ollama Response: {response}")
