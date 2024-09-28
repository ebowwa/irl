# SETUP DOCS

## How it works

![How it works](/irlweb/high_level_distribution.jpg)

## Requirements

- **Python**: Ensure you have Python installed on your machine.
- **Xcode**: For building and running the iOS app.
- **ngrok**: To expose local servers to the internet.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ebowwa/irl.git
   ```
   
2. Navigate into the project directory:
   ```bash
   cd irl && cd backend
   ```

3. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure API values
    ```bash
    # Duplicate the env.example file to create a new .env file
    cp env.example .env

    # Open the .env file and add your API keys
    nano .env
    ```
**Get your API KEYs here:**

[OpenAI](https://platform.openai.com), [HumeAI](https://platform.hume.ai/sign-up), [Anthropic](https://console.anthropic.com/), [FAL AI](https://fal.ai/dashboard) 

## Running the App

1. Start the FastAPI server with Uvicorn in development mode:
   ```bash
   uvicorn index:app --reload
   ```
   This will start the FastAPI server on your local machine, enabling automatic reloading during development.

2. Install ngrok if you don't have it already:
   ```bash
   brew install --cask ngrok
   ```
   Alternatively, you can download it from [ngrok's website](https://ngrok.com/download).

3. Expose your local server to the internet using ngrok:
   ```bash
   ngrok http 8000
   ```
   This will generate a public URL for your local server, which can be accessed externally.

4. Open Xcode, build, and run the app.

## Usage

Once your server is running and ngrok is set up, you can connect your iOS app to the public URL provided by ngrok, allowing it to communicate with your backend.
