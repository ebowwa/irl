# System Dependencies and Configuration

## Core System Requirements

### Development Environment
1. **Xcode and Command Line Tools**
   - Required for iOS development and building native components
   - Install Xcode from App Store
   - Install Command Line Tools: `xcode-select --install`

2. **Python Environment**
   - Python 3.12+: `brew install python@3.12`
   - Poetry (dependency management): `curl -sSL https://install.python-poetry.org | python3 -`

3. **Node.js Environment**
   - Node.js: `brew install node`
   - pnpm (package manager): `brew install pnpm`

4. **Development Tools**
   - Visual Studio Code: `brew install --cask visual-studio-code`
   - SourceKit LSP (Swift language support)
   - Git: Usually pre-installed on macOS

### Media Processing Tools
1. **Audio Processing**
   - sox (Sound eXchange): `brew install sox`
     - Includes: mad, opusfile
   - ffmpeg (media processing): `brew install ffmpeg`
     - Required for audio/video conversion and processing

2. **Image Processing**
   - ImageMagick: `brew install imagemagick`
   - WebP utilities: `brew install webp`

### Network Tools
1. **Development Proxy**
   - ngrok: `brew install --cask ngrok`
   - curl: Usually pre-installed on macOS
   - wget: `brew install wget`

2. **API Testing**
   - jq (JSON processor): `brew install jq`
   - httpie (HTTP client): `brew install httpie`

### Database Tools
1. **SQLite Tools**
   - sqlite3: Usually pre-installed on macOS
   - DB Browser for SQLite: `brew install --cask db-browser-for-sqlite`

2. **Python Database Libraries**
   - SQLAlchemy: `pip install sqlalchemy`
   - AsyncPG: `pip install asyncpg`
   - AioSQLite: `pip install aiosqlite`
   - Greenlet: `pip install greenlet`
   - Databases: `pip install databases`

### Security Tools
1. **Certificate Management**
   - mkcert: `brew install mkcert`
   - openssl: Usually pre-installed on macOS

## Python Package Dependencies
Key packages include:
- FastAPI
- Pydantic V2
- Google Generative AI
- aiohttp
- uvicorn
- SQLAlchemy
- python-multipart
- python-jose[cryptography]

## Node.js Package Dependencies
Managed via pnpm:
- React
- Next.js
- TypeScript
- TailwindCSS

## Development Setup

1. Install Homebrew (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install Xcode and Command Line Tools:
   ```bash
   # Install Xcode from App Store first, then:
   xcode-select --install
   ```

3. Install system dependencies:
   ```bash
   # Core development tools
   brew install python@3.12 node
   brew install --cask visual-studio-code
   
   # Media processing tools
   brew install sox ffmpeg imagemagick webp
   
   # Network and testing tools
   brew install --cask ngrok
   brew install wget jq httpie
   
   # Database tools
   brew install --cask db-browser-for-sqlite
   
   # Security tools
   brew install mkcert
   
   # Install Poetry
   curl -sSL https://install.python-poetry.org | python3 -
   
   # Install pnpm
   brew install pnpm
   ```

4. Configure development environment:
   ```bash
   # Configure git
   git config --global pull.rebase true
   
   # Install VS Code extensions
   code --install-extension ms-python.python
   code --install-extension sourcegraph.cody-ai
   code --install-extension dbaeumer.vscode-eslint
   ```

5. Project setup:
   ```bash
   git clone <repository-url>
   cd caringmind
   
   # Install Python dependencies
   poetry install
   
   # Install Node.js dependencies
   pnpm install
   
   # Build frontend
   pnpm build
   ```

## Testing

1. Run API tests:
   ```bash
   ./tests/test_api_port.sh
   ```

2. Run frontend tests:
   ```bash
   pnpm test
   ```

3. Run iOS tests (requires Xcode):
   ```bash
   xcodebuild test -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone 16"
   ```

## Maintenance

- Keep Xcode and Command Line Tools updated
- Regularly update brew packages: `brew update && brew upgrade`
- Update Python packages: `poetry update`
- Update Node.js packages: `pnpm update`

## Common Issues

1. **Sox Installation Issues**
   - If sox fails to install, try: `brew install sox --with-flac --with-lame --with-libvorbis`

2. **Python Version Conflicts**
   - Use `pyenv` to manage multiple Python versions: `brew install pyenv`

3. **Node.js Version Issues**
   - Use `nvm` to manage Node.js versions: `brew install nvm`
