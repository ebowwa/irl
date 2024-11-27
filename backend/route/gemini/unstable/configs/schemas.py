# configs/schemas.py
import os
from typing import Dict
import json
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

class SchemaManager:
    def __init__(self):
        # Get the absolute path to the prompts directory
        self.config_dir = Path(__file__).parent / "prompts"
        self.configs = self._load_configurations()

    def _load_configurations(self) -> Dict[str, Dict]:
        configurations = {}
        
        if not self.config_dir.exists():
            logger.error(f"Config directory not found: {self.config_dir}")
            raise FileNotFoundError(f"Config directory not found: {self.config_dir}")

        for file_path in self.config_dir.glob("*.json"):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    prompt_type = file_path.stem  # Get filename without extension
                    configurations[prompt_type] = config
                logger.info(f"Loaded configuration '{prompt_type}' from {file_path.name}")
            except Exception as e:
                logger.error(f"Failed to load configuration '{file_path.name}': {e}")
                
        if not configurations:
            logger.warning("No configuration files found in the prompts directory")
            
        return configurations

    def get_config(self, prompt_type: str) -> Dict:
        if prompt_type not in self.configs:
            logger.warning(f"Configuration not found for prompt_type: {prompt_type}")
        return self.configs.get(prompt_type)
