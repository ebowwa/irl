from typing import Dict, Any

def find_theaters(location: str, movie: str = "") -> Dict[str, Any]:
    """Find theaters based on location and optionally movie title."""
    # Placeholder implementation. Replace with actual logic or API calls.
    theaters = [
        {
            "name": "AMC Mountain View 16",
            "address": "2000 W El Camino Real, Mountain View, CA 94040"
        },
        {
            "name": "Regal Edwards 14",
            "address": "245 Castro St, Mountain View, CA 94040"
        }
    ]
    if movie:
        theaters = [theater for theater in theaters if movie.lower() in theater["name"].lower()]
    return {"location": location, "theaters": theaters}

# Metadata for the Gemini API
FUNCTION_METADATA = {
    "name": "find_theaters",
    "description": "Find theaters based on location and optionally movie title currently playing.",
    "parameters": {
        "type": "object",
        "properties": {
            "location": {
                "type": "string",
                "description": "The city and state, e.g., San Francisco, CA or a zip code."
            },
            "movie": {
                "type": "string",
                "description": "Any movie title."
            }
        },
        "required": ["location"]
    }
}
