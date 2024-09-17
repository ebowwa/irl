import requests
import dotenv
import json
import os

dotenv.load_dotenv()  # Load environment variables from .env file

API_KEY = os.getenv('HUME_API_KEY')
BASE_URL = 'https://api.hume.ai/v0/batch/jobs'

headers = {
    'X-Hume-Api-Key': API_KEY
}

def get_job_predictions(job_id):
    response = requests.get(f"{BASE_URL}/{job_id}/predictions", headers=headers)
    
    if response.status_code == 200:
        predictions = response.json()
        print("Predictions retrieved successfully")
        return predictions
    else:
        print(f"Error retrieving predictions: {response.status_code} - {response.text}")
        return None

def print_predictions(predictions):
    if not predictions:
        print("No predictions to display.")
        return

    print(json.dumps(predictions, indent=2))  # Print the entire response for inspection

    if isinstance(predictions, list) and len(predictions) > 0:
        for i, prediction in enumerate(predictions):
            print(f"\nPrediction {i + 1}:")
            if 'results' in prediction:
                results = prediction['results']
                if 'predictions' in results and isinstance(results['predictions'], list):
                    for j, model_prediction in enumerate(results['predictions']):
                        print(f"  Model Prediction {j + 1}:")
                        if 'models' in model_prediction:
                            for model_name, model_data in model_prediction['models'].items():
                                print(f"    {model_name.capitalize()} Model:")
                                if 'grouped_predictions' in model_data:
                                    for group in model_data['grouped_predictions']:
                                        if 'predictions' in group:
                                            for pred in group['predictions']:
                                                if 'emotions' in pred:
                                                    print("      Emotions:")
                                                    for emotion in pred['emotions']:
                                                        print(f"        {emotion['name']}: {emotion['score']}")
                else:
                    print("  No predictions found in results.")
            else:
                print("  No results found in prediction.")
    else:
        print("Predictions is not a list or is empty.")



# Usage - will get abruptly cut off if only printing to console
job_id = os.getenv('EXAMPLE_HUME_JOB_ID') 
predictions = get_job_predictions(job_id)


if predictions:
    print_predictions(predictions)
else:
    print("Failed to retrieve predictions.")