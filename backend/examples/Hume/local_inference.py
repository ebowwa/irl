import requests
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

API_KEY = os.getenv('HUME_API_KEY')
BASE_URL = 'https://api.hume.ai/v0/batch/jobs'

headers = {
    'X-Hume-Api-Key': API_KEY
}

def start_inference_job(file_path=None, url=None):
    if not API_KEY:
        print("Error: HUME_API_KEY environment variable is not set.")
        return None

    if file_path and url:
        print("Error: Please provide either a file path or a URL, not both.")
        return None
    
    if not file_path and not url:
        print("Error: Please provide either a file path or a URL.")
        return None

    data = {
        "models": {
            "face": {},
            "prosody": {},
            "language": {}
        },
        "notify": True
    }

    files = None
    
    if url:
        data["urls"] = [url]
    elif file_path:
        if not os.path.exists(file_path):
            print(f"Error: File not found at {file_path}")
            return None
        files = {'file': open(file_path, 'rb')}

    try:
        if files:
            response = requests.post(BASE_URL, headers=headers, data={'json': json.dumps(data)}, files=files)
        else:
            response = requests.post(BASE_URL, headers=headers, json=data)

        if response.status_code == 200:
            job_id = response.json()['job_id']
            print(f"Job started successfully. Job ID: {job_id}")
            return job_id
        else:
            print(f"Error starting job: {response.status_code} - {response.text}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"An error occurred while making the request: {e}")
        return None
    finally:
        if files:
            files['file'].close()

# Usage 
# https://uppbeat.io/browse/sfx/voice-clips
file_path = '/Users/ebowwa/Downloads/nice-enthusiastic-male-dan-barracuda-1-00-02.mp3'  # Replace with your local file path
# url = 'https://example.com/your-media-file.mp4'  # Uncomment and use this for URL instead of file_path

job_id = start_inference_job(file_path=file_path)
# job_id = start_inference_job(url=url)  # Uncomment and use this for URL instead of file_path

if job_id:
    print(f"You can use this job_id to check the status and retrieve results later: {job_id}")
else:
    print("Failed to start the job. Please check your inputs and try again.")