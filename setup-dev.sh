#!/bin/bash

echo "🚀 Setting up CaringMind Development Environment..."

# Check if Poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "📦 Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
fi

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "📦 Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Backend Setup
echo "🔧 Setting up Backend..."
cd backend

# Initialize Poetry and install dependencies
echo "📚 Installing Python dependencies..."
poetry install

# Setup pre-commit hooks
echo "🔨 Setting up pre-commit hooks..."
poetry run pre-commit install

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env from example..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your actual configuration values"
fi

# Frontend Setup
echo "🎨 Setting up Frontend..."
cd ../clients/caringmindWeb

# Install frontend dependencies
echo "📚 Installing Node.js dependencies..."
pnpm install

# Build the frontend
echo "🏗️  Building frontend..."
pnpm build

echo "✨ Setup completed! Here's how to start development:"
echo "
Backend:
1. cd backend
2. poetry shell
3. uvicorn index:app --reload

Frontend:
1. cd clients/caringmindWeb
2. pnpm dev

Note: Make sure to configure your .env files with the correct values before starting the services.
"