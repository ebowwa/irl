# utils/schema_converter.py
from google.ai.generativelanguage_v1beta.types import content
from typing import Dict

def dict_to_schema(schema_dict: Dict) -> content.Schema:
    schema_type = getattr(content.Type, schema_dict.get('type', 'OBJECT'))
    required = schema_dict.get('required', [])
    properties = schema_dict.get('properties', {})

    converted_properties = {}
    for prop_name, prop_details in properties.items():
        prop_type = prop_details.get('type', 'STRING')
        if prop_type == 'OBJECT':
            converted_properties[prop_name] = dict_to_schema(prop_details)
        elif prop_type == 'ARRAY':
            items = prop_details.get('items', {})
            item_schema = dict_to_schema(items) if items.get('type') == 'OBJECT' else \
                         content.Schema(type=getattr(content.Type, items.get('type', 'STRING')))
            converted_properties[prop_name] = content.Schema(
                type=content.Type.ARRAY,
                items=item_schema,
                description=prop_details.get('description', '')
            )
        else:
            converted_properties[prop_name] = content.Schema(
                type=getattr(content.Type, prop_type),
                description=prop_details.get('description', '')
            )

    return content.Schema(
        type=schema_type,
        required=required,
        properties=converted_properties
    )