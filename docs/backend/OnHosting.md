# Notes on Hosting 

- choose `Linux Ubuntu` if possible

## If Hetzner, DO NOT USE `us-west` as most western internet will give a 403 error for library packages, or other requests, i.e. ollama

https://dashboard.ngrok.com/get-started/setup/linux

    ```
    sudo apt update
    curl -fsSL https://ollama.com/install.sh | sh
    ollama pull llama3.2:1b
    apt install python3-pip
    sudo apt install python3.12-venv
    python3 -m venv venv
    source venv/bin/activate
    sudo apt update
    ```
[see-ollama](docs/SetupREADME.md)

# Production Server
Run Gunicorn Using the Virtual Environment's Executable
To ensure that Gunicorn uses the correct environment, you can specify the full path to the Gunicorn executable within your virtual environment.

Run Gunicorn with Full Path:
i.e.
    ```
    /root/irl/backend/PRODvenv/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 index:app
    ```
