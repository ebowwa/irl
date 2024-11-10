# CaringMind Development Setup Guide

This guide explains the development environment setup and configuration for both the backend (FastAPI) and frontend (Next.js) components of CaringMind.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Configuration](#detailed-configuration)
  - [Backend Configuration](#backend-configuration)
  - [Frontend Configuration](#frontend-configuration)
- [Development Tools](#development-tools)
- [Code Quality and Standards](#code-quality-and-standards)

## Prerequisites

Before starting, ensure you have:
- Python 3.9 or higher
- Node.js 16 or higher
- Git

## Quick Start

The easiest way to set up the development environment is using our setup script:

```bash
./setup-dev.sh
```

This script will:
1. Install Poetry (Python dependency management)
2. Install pnpm (Node.js package management)
3. Set up backend dependencies and environment
4. Set up frontend dependencies and build
5. Configure all development tools

## Detailed Configuration

### Backend Configuration

The backend uses modern Python tools for dependency management and code quality:

#### Poetry Configuration (pyproject.toml)
```toml
[tool.poetry]
name = "caringmind-backend"
version = "0.1.0"
description = "CaringMind Backend API"

[tool.poetry.dependencies]
python = "^3.9"
fastapi = "*"
uvicorn = {extras = ["standard"], version = "*"}
# ... other dependencies

[tool.black]
line-length = 88
target-version = ['py39']

[tool.isort]
profile = "black"
multi_line_output = 3
```

#### Pre-commit Hooks (.pre-commit-config.yaml)
```yaml
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.5.0
  hooks:
    - id: trailing-whitespace
    - id: end-of-file-fixer
    - id: check-yaml
    # ... other hooks

- repo: https://github.com/psf/black
  rev: 23.10.1
  hooks:
    - id: black
```

### Frontend Configuration

The Next.js frontend uses modern JavaScript/TypeScript tools:

#### Prettier Configuration (.prettierrc)
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
```

## Development Tools

### Backend Tools
- **Poetry**: Modern Python dependency management
- **Black**: Code formatting
- **isort**: Import sorting
- **flake8**: Code linting
- **pre-commit**: Automated code quality checks

### Frontend Tools
- **pnpm**: Fast, disk space efficient package manager
- **ESLint**: JavaScript/TypeScript linting
- **Prettier**: Code formatting
- **TypeScript**: Type checking

## Code Quality and Standards

### Python Code Standards
- Line length: 88 characters (Black default)
- Sorting imports using isort
- PEP 8 compliance via flake8
- Type hints encouraged
- Docstrings required for public functions

### JavaScript/TypeScript Standards
- Line length: 100 characters
- Single quotes for strings
- Semi-colons required
- TypeScript strict mode enabled
- ES6+ features preferred

## Starting Development

After running the setup script:

### Start Backend
```bash
cd backend
poetry shell
uvicorn index:app --reload
```

### Start Frontend
```bash
cd clients/caringmindWeb
pnpm dev
```

## Environment Configuration

1. Backend (.env):
   - Copy `.env.example` to `.env`
   - Fill in required API keys and configuration

2. Frontend (if needed):
   - Environment variables can be added to `.env.local`

## Common Issues and Solutions

### Poetry Installation
If Poetry installation fails:
```bash
curl -sSL https://install.python-poetry.org | python3 -
```

### pnpm Installation
If pnpm installation fails:
```bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

### Pre-commit Hooks
If pre-commit hooks aren't running:
```bash
poetry run pre-commit install
```

## Contributing

1. Ensure all tests pass
2. Run pre-commit hooks before committing
3. Follow the code style guidelines
4. Update documentation as needed

## Additional Resources

- [Poetry Documentation](https://python-poetry.org/docs/)
- [pnpm Documentation](https://pnpm.io/motivation)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Next.js Documentation](https://nextjs.org/docs)