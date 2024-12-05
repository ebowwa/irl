# CaringMind Scripts

This directory contains utility scripts for managing the CaringMind project. All scripts are automatically made executable when you run `index.sh`.

## Quick Start

To see all available scripts and make them executable:

```bash
./scripts/index.sh
```

## Available Scripts

### index.sh
- **Purpose**: Lists all available scripts and makes them executable
- **Usage**: `./scripts/index.sh`

### clean_pycache.sh
- **Purpose**: Removes Python cache files
- **Usage**: `./scripts/clean_pycache.sh`
- **Details**: Recursively removes `__pycache__` directories and `.pyc` files

### setup_pyenv.sh
- **Purpose**: Sets up Python environment
- **Usage**: `./scripts/setup_pyenv.sh`
- **Details**: Installs pyenv, latest Python version, and creates a virtual environment

### setup-dependencies.sh
- **Purpose**: Sets up project dependencies
- **Usage**: `./scripts/setup-dependencies.sh`
- **Details**: Installs and configures project dependencies

## Adding New Scripts

1. Create your new script in the `scripts` directory
2. Add a description for your script in `index.sh` using the `display_script_info` function
3. Update this README.md with details about your script

## Best Practices

- All scripts should have a clear purpose and be documented
- Use the `index.sh` script to make all scripts executable
- Follow the existing script structure for consistency
- Add appropriate error handling and user feedback
- Use color coding for better readability (see `index.sh` for examples)
