import os
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def convert_types_to_lowercase(data):
    """
    Recursively traverse the JSON data and convert "type" values to lowercase.
    """
    if isinstance(data, dict):
        for key in data:
            if key == "type":
                if isinstance(data[key], str):
                    data[key] = data[key].lower()
                    logger.info(f"Converted 'type' value to lowercase in {data}")
            elif isinstance(data[key], (dict, list)):
                convert_types_to_lowercase(data[key])
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, (dict, list)):
                convert_types_to_lowercase(item)

def process_json_files(directory):
    """
    Process all JSON files in the specified directory and its subdirectories.
    """
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                file_path = os.path.join(root, file)
                logger.info(f"Processing file: {file_path}")
                try:
                    with open(file_path, 'r') as f:
                        data = json.load(f)
                    # Convert "type" values to lowercase
                    convert_types_to_lowercase(data)
                    # Save the modified data back to the file
                    with open(file_path, 'w') as f:
                        json.dump(data, f, indent=4)
                    logger.info(f"File {file_path} has been updated.")
                except json.JSONDecodeError as e:
                    logger.error(f"Failed to parse JSON in {file_path}: {e}")
                except Exception as e:
                    logger.error(f"An error occurred processing {file_path}: {e}")

if __name__ == "__main__":
    # Specify the directory containing the JSON files
    directory_path = '/home/pi/caringmind/backend/route/gemini/configs'
    process_json_files(directory_path)