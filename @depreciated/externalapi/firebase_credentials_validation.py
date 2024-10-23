
import os
import json

# Load the environment variable
firebase_credentials_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
if not firebase_credentials_path:
    raise ValueError("FIREBASE_CREDENTIALS_PATH environment variable is not set")

# Debugging: Read the JSON file manually to ensure it's being parsed correctly
try:
    with open(firebase_credentials_path, 'r') as f:
        credentials_data = json.load(f)
        print("Service account credentials loaded successfully:")
        print(json.dumps(credentials_data, indent=2))  # Pretty-print the JSON
except Exception as e:
    print(f"Error reading the service account JSON file: {e}")
    raise
from firebase_admin import credentials, initialize_app

# Initialize Firebase with the credentials file
try:
    cred = credentials.Certificate(firebase_credentials_path)
    initialize_app(cred)
    print("Firebase Admin SDK initialized successfully.")
except Exception as e:
    print(f"Error initializing Firebase Admin SDK: {e}")
    raise

