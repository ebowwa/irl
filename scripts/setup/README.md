# Setup Scripts

This directory contains all setup-related scripts organized into the following categories:

## Directory Structure

### env/
Environment setup and dependency management:
- `setup_pyenv.sh`: Python environment setup
- `setup-dependencies.sh`: Project dependencies installation
- `check-dependencies.sh`: Dependency verification tool

### platform/
Platform-specific setup scripts:
- `setup-linux-full.sh`: Complete setup for Linux environments
- `setup-macos-full.sh`: Complete setup for macOS environments

### components/
Individual component setup:
- `setup-backend.sh`: Backend setup and configuration
- `setup-frontend.sh`: Frontend setup and configuration

## Usage

1. For a complete setup on your platform:
   - macOS: Run `platform/setup-macos-full.sh`
   - Linux: Run `platform/setup-linux-full.sh`

2. For individual component setup:
   - Backend only: Run `components/setup-backend.sh`
   - Frontend only: Run `components/setup-frontend.sh`

3. For environment setup:
   - Python environment: Run `env/setup_pyenv.sh`
   - Project dependencies: Run `env/setup-dependencies.sh`
   - Check dependencies: Run `env/check-dependencies.sh`

## Best Practices
- Run the platform-specific script first for a new installation
- Use individual component scripts for updating specific parts
- Always check dependencies before running setup scripts
