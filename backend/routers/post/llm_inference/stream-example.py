from openai import OpenAI
from dotenv import load_dotenv
import os
import sys
import time
from datetime import datetime

# Load environment variables from .env file
load_dotenv()

# Create OpenAI client
def get_openai_client():
    try:
        client = OpenAI()
        return client
    except Exception as e:
        print(f"Error initializing OpenAI client: {e}")
        sys.exit(1)

# Perform inference
def perform_llm_inference():
    client = get_openai_client()

    start_time = datetime.now()
    print(f"Stream started at: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")

    try:
        completion = client.chat.completions.create(
            model=os.getenv("MODEL_NAME", "gpt-4o-mini"),  # Use environment variable for model name
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Hello!"}
            ],
            stream=True
        )
    except Exception as e:
        print(f"Error in LLM inference: {e}")
        sys.exit(1)

    # Track the content and roles as chunks arrive
    for chunk in completion:
        delta = chunk.choices[0].delta
        if delta.content and delta.content.strip():
            print(f"Received at {datetime.now().strftime('%H:%M:%S')} | {delta.content.strip()}")

    end_time = datetime.now()
    print(f"Stream ended at: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Total duration: {end_time - start_time}")

# Entry point
if __name__ == "__main__":
    perform_llm_inference()
