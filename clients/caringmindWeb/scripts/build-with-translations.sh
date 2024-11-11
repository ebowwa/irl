#!/bin/bash

# Run translations first
echo "Generating translations..."
pnpm translate

# Then build the application
echo "Building application..."
pnpm build
