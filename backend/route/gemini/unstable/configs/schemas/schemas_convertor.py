from google.ai.generativelanguage_v1beta.types import content
from typing import Dict
import logging

logger = logging.getLogger(__name__)

def dict_to_schema(schema_dict: Dict) -> content.Schema:
    try:
        schema_type = getattr(content.Type, schema_dict.get('type', 'OBJECT'))
    except AttributeError:
        logger.error(f"Invalid type in schema: {schema_dict.get('type')}")
        schema_type = content.Type.OBJECT  # Default to OBJECT or handle as needed

    required = schema_dict.get('required', [])
    properties = schema_dict.get('properties', {})

    converted_properties = {}
    for prop_name, prop_details in properties.items():
        prop_type = prop_details.get('type', 'STRING')
        try:
            if prop_type == 'OBJECT':
                converted_properties[prop_name] = dict_to_schema(prop_details)
            elif prop_type == 'ARRAY':
                items = prop_details.get('items', {})
                if items.get('type') == 'OBJECT':
                    item_schema = dict_to_schema(items)
                else:
                    try:
                        item_type = getattr(content.Type, items.get('type', 'STRING'))
                        item_schema = content.Schema(type=item_type)
                    except AttributeError:
                        logger.error(f"Invalid item type in schema: {items.get('type')}")
                        item_schema = content.Schema(type=content.Type.STRING)  # Default or handle as needed
                converted_properties[prop_name] = content.Schema(
                    type=content.Type.ARRAY,
                    items=item_schema,
                    description=prop_details.get('description', '')
                )
            else:
                try:
                    field_type = getattr(content.Type, prop_type)
                except AttributeError:
                    logger.error(f"Invalid property type in schema: {prop_type}")
                    field_type = content.Type.STRING  # Default or handle as needed
                converted_properties[prop_name] = content.Schema(
                    type=field_type,
                    description=prop_details.get('description', '')
                )
        except AttributeError as e:
            logger.error(f"Error processing property '{prop_name}': {e}")
            # Handle or skip the property as needed

    return content.Schema(
        type=schema_type,
        required=required,
        properties=converted_properties
    )
