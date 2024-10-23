from typing import Dict, Any

def multiply(a: float, b: float) -> float:
    """Returns the product of two numbers."""
    return a * b

# Metadata for the Gemini API
FUNCTION_METADATA = {
    "name": "multiply",
    "description": "Returns the product of two numbers.",
    "parameters": {
        "type": "object",
        "properties": {
            "a": {
                "type": "number",
                "description": "First number to multiply."
            },
            "b": {
                "type": "number",
                "description": "Second number to multiply."
            }
        },
        "required": ["a", "b"]
    }
}
