---

# IRL

![IRL](irlweb/7LIk_g_yRE2jVpeDe9Vxng.jpeg)

## About

IRL (In Real Life) is an AI-powered project that functions as an augmented memory assistant, human interpreter, advocate, and more. This app is designed to elevate human-AI interaction by providing real-time support and insights to users in various contexts.

## Features

- **Augmented Memory**: Helps users by storing and retrieving information as needed.
- **Human Interpreter**: Provides contextual interpretations based on real-time input.
- **Advocacy**: Acts as a digital advocate to assist users in navigating complex situations.
- **AI Companion**: Serves as your personal AI assistant for various tasks.

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
   cd irl
   ```

3. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure API values
    ```bash
    # Rename the template.env file to .env
    mv template.env .env

    # Open the .env file and add your API keys
    nano .env
    ```

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

## Contributing

We welcome contributions! Feel free to submit issues or pull requests to help improve the project.

---
