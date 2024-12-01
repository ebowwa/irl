#!/bin/bash

# Exit on error
set -e

echo "Installing mahdi..."

# Build the package
swift build -c release

# Create installation directories if they don't exist
sudo mkdir -p /usr/local/lib/mahdi
sudo mkdir -p /usr/local/include/mahdi

# Copy the dynamic library
sudo cp .build/release/libmahdi.dylib /usr/local/lib/mahdi/

# Set up symbolic links
sudo ln -sf /usr/local/lib/mahdi/libmahdi.dylib /usr/local/lib/libmahdi.dylib

# Set permissions
sudo chmod 755 /usr/local/lib/mahdi/libmahdi.dylib

echo "Installation complete!"
