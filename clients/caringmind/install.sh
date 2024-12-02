#!/bin/bash

# Exit on error
set -e

echo "Installing caringmind..."

# Build the package
swift build -c release

# Create installation directories if they don't exist
sudo mkdir -p /usr/local/lib/caringmind
sudo mkdir -p /usr/local/include/caringmind

# Copy the dynamic library
sudo cp .build/release/libcaringmind.dylib /usr/local/lib/caringmind/

# Set up symbolic links
sudo ln -sf /usr/local/lib/caringmind/libcaringmind.dylib /usr/local/lib/libcaringmind.dylib

# Set permissions
sudo chmod 755 /usr/local/lib/caringmind/libcaringmind.dylib

echo "Installation complete!"
