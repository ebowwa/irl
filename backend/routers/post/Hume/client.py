# backend/routers/post/Hume/client.py
import os
import requests
import json
from typing import List, Optional
from urllib.parse import urlparse

class HumeClient:
    def __init__(self, api_key, callback_url) -> None:
        self.api_key = api_key
        self.callback_url = callback_url
        self.base_url = "https://api.hume.ai/v0/batch"

    def is_url(self, path: str) -> bool:
        try:
            result = urlparse(path)
            return all([result.scheme, result.netloc])
        except ValueError:
            return False

    def request_user_expression_measurement(self, paths: List[str], json_config: Optional[str] = None):
        """
        This method handles both URLs and local files. URLs are sent directly,
        while local files are read and sent as multipart/form-data.
        """
        files = []

        # Handle file paths
        for path in paths:
            if os.path.exists(path):
                file_data = open(path, 'rb')  # Open the file without immediately closing it
                files.append(('files', (os.path.basename(path), file_data, 'audio/mpeg')))
            else:
                return {"error": f"Local file not found: {path}"}

        # Prepare the json payload
        if json_config:
            json_data = {'json': json_config}
        else:
            # Default configuration if none is provided
            json_payload = {
                "models": {
                    "prosody": {
                        "granularity": "utterance"
                    }
                }
            }
            json_data = {'json': json.dumps(json_payload)}

        # Send them as multipart/form-data
        try:
            resp = requests.post(f"{self.base_url}/jobs", data=json_data, files=files, headers={
                'X-Hume-Api-Key': self.api_key,
            }, timeout=300)

            # Close all files after the request is done
            for _, (_, file_data, _) in files:
                file_data.close()

        except requests.RequestException as e:
            # Close all files if an exception occurs
            for _, (_, file_data, _) in files:
                file_data.close()
            return {"error": f"RequestException: {str(e)}"}

        if resp.status_code != 200:
            return {"error": {"status": resp.status_code, "message": resp.text}}

        return resp.json()

    def list_jobs(self, limit: Optional[int] = 10, status: Optional[str] = None, sort_by: Optional[str] = "created",
                  direction: Optional[str] = "desc", created_before: Optional[int] = None, created_after: Optional[int] = None):
        params = {
            "limit": limit,
            "sort_by": sort_by,
            "direction": direction,
        }
        if status:
            params["status"] = status
        if created_before:
            params["when"] = "created_before"
            params["timestamp_ms"] = created_before
        if created_after:
            params["when"] = "created_after"
            params["timestamp_ms"] = created_after

        try:
            resp = requests.get(f"{self.base_url}/jobs", headers={
                'X-Hume-Api-Key': self.api_key,
            }, params=params, timeout=300)

            if resp.status_code != 200:
                return {"error": {"status": resp.status_code, "message": resp.text}}

            return resp.json()
        except requests.RequestException as e:
            return {"error": f"RequestException: {str(e)}"}

    def get_job_details(self, job_id: str):
        try:
            resp = requests.get(f"{self.base_url}/jobs/{job_id}", headers={
                'X-Hume-Api-Key': self.api_key,
            }, timeout=300)

            if resp.status_code != 200:
                return {"error": {"status": resp.status_code, "message": resp.text}}

            return resp.json()
        except requests.RequestException as e:
            return {"error": f"RequestException: {str(e)}"}

    def get_job_predictions(self, job_id: str):
        try:
            resp = requests.get(f"{self.base_url}/jobs/{job_id}/predictions", headers={
                'X-Hume-Api-Key': self.api_key,
            }, timeout=300)

            if resp.status_code != 200:
                return {"error": {"status": resp.status_code, "message": resp.text}}

            return resp.json()
        except requests.RequestException as e:
            return {"error": f"RequestException: {str(e)}"}

    def get_job_artifacts(self, job_id: str):
        try:
            resp = requests.get(f"{self.base_url}/jobs/{job_id}/artifacts", headers={
                'X-Hume-Api-Key': self.api_key,
            }, timeout=300)

            if resp.status_code == 200:
                with open(f"{job_id}_artifacts.zip", 'wb') as f:
                    f.write(resp.content)
                return {"message": f"Artifacts saved as {job_id}_artifacts.zip"}
            else:
                return {"error": {"status": resp.status_code, "message": resp.text}}
        except requests.RequestException as e:
            return {"error": f"RequestException: {str(e)}"}

# Instantiate the client object
hume_client = HumeClient(
    api_key=os.getenv('HUME_API_KEY'),
    callback_url=os.getenv('HUME_CALLBACK_URL'),
)
