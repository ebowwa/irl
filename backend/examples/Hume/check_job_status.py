import requests
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

API_KEY = os.getenv('HUME_API_KEY')
BASE_URL = 'https://api.hume.ai/v0/batch/jobs'

def check_job_status(job_id):
    if not API_KEY:
        print("Error: HUME_API_KEY environment variable is not set.")
        return None

    headers = {
        'X-Hume-Api-Key': API_KEY
    }

    # Print headers for debugging (obscure API key for security)
    debug_headers = headers.copy()
    debug_headers['X-Hume-Api-Key'] = debug_headers['X-Hume-Api-Key'][:5] + '...' if debug_headers['X-Hume-Api-Key'] else 'Not set'
    print(f"Request Headers: {debug_headers}")

    try:
        response = requests.get(f"{BASE_URL}/{job_id}", headers=headers)
        
        print(f"Response Status Code: {response.status_code}")
        print(f"Response Headers: {response.headers}")
        
        if response.status_code == 200:
            job_details = response.json()
            status = job_details['state']['status']
            print(f"Job status: {status}")
            return status
        else:
            print(f"Error checking job status: {response.status_code} - {response.text}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"An error occurred while making the request: {e}")
        return None

# Usage
job_id = os.getenv('EXAMPLE_HUME_JOB_ID')
if not job_id:
    print("Error: EXAMPLE_HUME_JOB_ID environment variable is not set.")
else:
    status = check_job_status(job_id)
    if status is None:
        print("Failed to retrieve job status. Please check your API key and job ID.")