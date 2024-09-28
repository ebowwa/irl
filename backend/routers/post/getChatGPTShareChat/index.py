# backend/routers/post/getChatGPTShareChat.py
# TODO: make this into a route for my backend, the response will be saved in the user's client storage 
import requests
from bs4 import BeautifulSoup
import json
import re

# Function 1: Overall Data Extraction (Metadata, User Info, etc.)
def scrape_chatgpt_conversation(share_link):
    try:
        response = requests.get(share_link)
        response.raise_for_status()  # Ensure we catch bad HTTP responses

        soup = BeautifulSoup(response.text, 'html.parser')
        print("Page fetched successfully!")  # Debugging

        # Search for the script tag containing JSON
        script_tag = soup.find('script', string=re.compile('window.__remixContext'))

        if not script_tag:
            print("Script tag not found in the page.")
            print(response.text[:1000])  # Print the first part of the HTML to inspect if the structure is different
            return None

        # Extract JSON from the script
        json_str = re.search(r'window\.__remixContext\s*=\s*({.*?});', script_tag.string, re.DOTALL)
        if not json_str:
            print("JSON string not found in the script tag.")
            return None
        
        data = json.loads(json_str.group(1))
        print("JSON successfully extracted!")  # Debugging
        
        # Extract metadata and other general information
        loader_data = data.get('state', {}).get('loaderData', {})
        meta_data = loader_data.get('meta', {})
        
        analysis = {
            'meta': {
                'title': meta_data.get('title'),
                'description': meta_data.get('description'),
                'image_src': meta_data.get('imageSrc'),
            },
            'user_info': {},  # Initialize user_info as an empty dict
            'layer_summary': {
                layer_id: {
                    'is_active': layer.get('is_experiment_active'),
                    'is_user_in_experiment': layer.get('is_user_in_experiment'),
                    'parameters': layer.get('value', {})
                } for layer_id, layer in loader_data.get('layer_configs', {}).items()
            }
        }
        
        # Attempt to extract user info if it exists
        user_info = data.get('state', {}).get('user', {})
        if user_info:
            analysis['user_info'] = {
                'country': user_info.get('country'),
                'auth_status': user_info.get('custom', {}).get('auth_status'),
                'user_agent': user_info.get('userAgent'),
            }
        else:
            print("User information is not present in the JSON data.")
        
        return analysis

    except requests.RequestException as e:
        print(f"An error occurred during the request: {e}")
        return None


# Function 2: Chat Messages Extraction (Recursive)
def extract_chat_messages_recursive(nodes, messages, mapping_data):
    """
    Recursively traverses the conversation nodes to extract messages.
    
    Parameters:
        nodes (list): The current list of conversation nodes to process.
        messages (list): The list where chat messages will be stored.
        mapping_data (dict): A dictionary mapping IDs to nodes.
    """
    for node in nodes:
        message = node.get('message', {})
        author = message.get('author', {}).get('role', 'unknown')
        content = message.get('content', {}).get('parts', [''])[0] if message.get('content') else ''
        timestamp = message.get('create_time', 'unknown')
        
        if content:  # Only add messages with actual content
            messages.append({
                'author': author,
                'content': content,
                'timestamp': timestamp
            })
        
        # Recursively process children nodes
        children_ids = node.get('children', [])
        if children_ids:
            # Find child nodes by ID from the mapping structure
            child_nodes = [mapping_data.get(child_id) for child_id in children_ids if child_id in mapping_data]
            # Filter out None values in case a child_id is not found
            child_nodes = [child for child in child_nodes if child]
            extract_chat_messages_recursive(child_nodes, messages, mapping_data)

def extract_chat_messages(share_link):
    try:
        response = requests.get(share_link)
        response.raise_for_status()  # Ensure we catch bad HTTP responses

        soup = BeautifulSoup(response.text, 'html.parser')
        print("Page fetched successfully!")  # Debugging

        # Search for the script tag containing JSON
        script_tag = soup.find('script', string=re.compile('window.__remixContext'))

        if not script_tag:
            print("Script tag not found in the page.")
            print(response.text[:1000])  # Print the first part of the HTML to inspect if the structure is different
            return None

        # Extract JSON from the script
        json_str = re.search(r'window\.__remixContext\s*=\s*({.*?});', script_tag.string, re.DOTALL)
        if not json_str:
            print("JSON string not found in the script tag.")
            return None
        
        data = json.loads(json_str.group(1))
        print("JSON successfully extracted!")  # Debugging

        # Check 'serverResponse data'
        server_response = data.get('state', {}).get('loaderData', {}).get('routes/share.$shareId.($action)', {}).get('serverResponse', {}).get('data', {})
        
        if not server_response:
            print("No 'serverResponse' data found.")
            return None
        
        # Get mapping and linear conversation data
        mapping_data = server_response.get('mapping', {})
        linear_conversation_data = server_response.get('linear_conversation', [])
        
        if not linear_conversation_data:
            print("No conversation data found in 'linear_conversation'.")
            return None
        
        # Extract chat messages by recursively traversing the conversation structure
        chat_messages = []
        extract_chat_messages_recursive(linear_conversation_data, chat_messages, mapping_data)
        
        if not chat_messages:
            print("No chat messages found after extraction.")
        
        return chat_messages

    except requests.RequestException as e:
        print(f"An error occurred during the request: {e}")
        return None


# Example usage of Function 1 (scrape_chatgpt_conversation)
share_link = "https://chatgpt.com/share/66f75220-51b8-800f-a8a7-5e9533058279"
conversation_data = scrape_chatgpt_conversation(share_link)

# Print extracted metadata and user info as JSON
if conversation_data:
    json_output = json.dumps(conversation_data, indent=4)
    print("Conversation Analysis:")
    print(json_output)
else:
    print("No conversation data found.")

# Example usage of Function 2 (extract_chat_messages)
chat_data = extract_chat_messages(share_link)

# Print extracted chat messages as JSON
if chat_data:
    json_output = json.dumps(chat_data, indent=4)
    print("Chat Messages:")
    print(json_output)
else:
    print("No chat messages found.")
