# CaringMind Scripts

This directory contains utility scripts for managing the CaringMind project. Scripts are organized into the following categories:

## Directory Structure

- `core/`: Essential utility scripts
  - `index.sh`: Lists all available scripts and makes them executable
  - `clean_pycache.sh`: Removes Python cache files
  - `cleanup.sh`: General cleanup utility

- `dev/`: Development-related scripts
  - `git_smart.sh`: Enhanced git operations
  - `dev_aliases.sh`: Development aliases and shortcuts

- `build/`: Build and run scripts
  - `build_irlapp.sh`: Builds the IRL application
  - `run_backend.sh`: Runs the backend server

- `server/`: Server management
  - `server_cleanup.sh`: Server maintenance and cleanup

- `setup/`: Installation and setup scripts
  - `setup-dependencies.sh`: Project dependency setup
  - `setup-backend.sh`: Backend setup
  - `setup-frontend.sh`: Frontend setup
  - `setup-linux-full.sh`: Full Linux environment setup
  - `setup-macos-full.sh`: Full macOS environment setup
  - `check-dependencies.sh`: Dependency verification

## Quick Start

To see all available scripts and make them executable:

```bash
./scripts/core/index.sh
```

## Adding New Scripts

1. Create your new script in the appropriate category directory
2. Add a description for your script in `core/index.sh` using the `display_script_info` function
3. Update this README.md with details about your script

## Best Practices

- All scripts should have a clear purpose and be documented
- Use the `core/index.sh` script to make all scripts executable
- Follow the existing script structure for consistency
- Add appropriate error handling and user feedback
- Use color coding for better readability (see `core/index.sh` for examples)
