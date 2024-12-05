#!/bin/bash

# Find and remove all __pycache__ directories
find . -type d -name "__pycache__" -exec rm -rf {} +

# Find and remove all .pyc files
find . -type f -name "*.pyc" -exec rm -f {} +

echo "Python cache files have been cleaned!"
