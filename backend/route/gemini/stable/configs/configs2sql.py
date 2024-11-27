import os
import json
import sqlite3

# Directory containing JSON files
directory = '/home/pi/caringmind/backend/route/gemini/configs'  # Replace with the actual directory path

# SQLite database file
database_file = 'prompt_schema.db'

# Connect to SQLite database
conn = sqlite3.connect(database_file)
cursor = conn.cursor()

# Create the prompt_schema table
cursor.execute('''
CREATE TABLE IF NOT EXISTS prompt_schema (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_name TEXT NOT NULL,
    prompt_text TEXT NOT NULL,
    response_schema TEXT NOT NULL
);
''')

# Iterate over JSON files in the directory
errors = []
for file_name in os.listdir(directory):
    if file_name.endswith('.json'):
        file_path = os.path.join(directory, file_name)
        file_base_name = os.path.splitext(file_name)[0]  # Remove `.json` extension
        try:
            with open(file_path, 'r') as file:
                data = json.load(file)
                prompt_text = data.get('prompt_text', '')
                response_schema = json.dumps(data.get('response_schema', {}))  # Convert schema to string
                cursor.execute('''
                    INSERT INTO prompt_schema (file_name, prompt_text, response_schema)
                    VALUES (?, ?, ?);
                ''', (file_base_name, prompt_text, response_schema))
        except Exception as e:
            errors.append((file_name, str(e)))

# Commit changes and close the database connection
conn.commit()
conn.close()

# Output any errors
if errors:
    print("Errors occurred while processing the following files:")
    for error in errors:
        print(f"File: {error[0]} - Error: {error[1]}")
else:
    print("All JSON files successfully processed and stored in the SQLite database.")
