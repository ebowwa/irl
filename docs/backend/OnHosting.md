# Notes on Hosting
## If Hetzner, DO NOT USE `us-west` as most western internet will give a 403 error for library packages, or other requests, i.e. ollama


sudo apt update
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b
apt install python3-pip
sudo apt install python3.12-venv

python3 -m venv venv

source venv/bin/activate
