# iOS Simulator and VSCode Development Guide

## Table of Contents
- [Basic Simulator Commands](#basic-simulator-commands)
- [Recording and Media](#recording-and-media)
- [Building and Running](#building-and-running)
- [VSCode Integration](#vscode-integration)
- [Debugging](#debugging)
- [Troubleshooting](#troubleshooting)

## Basic Simulator Commands

### List All Simulators
```bash
xcrun simctl list devices
```

### Manage Simulators
```bash
# Boot a specific simulator
xcrun simctl boot BC6E19BF-3E95-4E02-82D1-E07968F483E2

# Shutdown all simulators
xcrun simctl shutdown all

# Erase all simulators (reset content and settings)
xcrun simctl erase all

# Open Simulator app
open -a Simulator
```

### App Installation and Launch
```bash
# Install app to booted simulator
xcrun simctl install booted /path/to/your.app

# Launch app on booted simulator
xcrun simctl launch booted com.your.bundleidentifier

# Uninstall app
xcrun simctl uninstall booted com.your.bundleidentifier
```

## Recording and Media

### Screenshot Commands
```bash
# Take a screenshot of booted simulator
xcrun simctl io booted screenshot ~/Desktop/screenshot.png

# Take a screenshot with specific format
xcrun simctl io booted screenshot --type=png ~/Desktop/screenshot.png
```

### Video Recording
```bash
# Basic video recording
xcrun simctl io booted recordVideo ~/Desktop/recording.mp4

# Record with specific codec
xcrun simctl io booted recordVideo --codec=h264 ~/Desktop/recording.mp4

# Record with mask to show device frame
xcrun simctl io booted recordVideo --mask=ignored ~/Desktop/recording.mp4

# Record with specific dimensions (e.g., 1080p)
xcrun simctl io booted recordVideo --force-large ~/Desktop/recording.mp4
```

### Audio Recording
```bash
# Record video with device audio
xcrun simctl io booted recordVideo --mic ~/Desktop/recording_with_audio.mp4

# Record video with system audio
xcrun simctl io booted recordVideo --system ~/Desktop/recording_with_system_audio.mp4

# Record both mic and system audio
xcrun simctl io booted recordVideo --mic --system ~/Desktop/recording_full_audio.mp4
```

## Building and Running

### Basic Build Commands
```bash
# Build for specific simulator
xcodebuild -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone 16,OS=18.1" build

# Build and run
xcodebuild -scheme YourScheme -destination "id=BC6E19BF-3E95-4E02-82D1-E07968F483E2" build run

# Clean build
xcodebuild clean
```

### Testing
```bash
# Run all tests
xcodebuild test -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone 16"

# Run specific test
xcodebuild test -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:YourTestTarget/YourTestClass/testMethodName
```

## VSCode Integration

### Essential Extensions
1. "Swift" by Swift Server Work Group
2. "Swift for Visual Studio Code" by Swift Foundation
3. "iOS Simulator" by Mateusz Matrejek

### VSCode Settings
Add to settings.json:
```json
{
    "swift.path": "/usr/bin/swift",
    "sourcekit-lsp.serverPath": "/usr/bin/sourcekit-lsp",
    "sourcekit-lsp.toolchainPath": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
}
```

### Keyboard Shortcuts
- `Cmd + P`: Quick file navigation
- `Cmd + Shift + P`: Command palette
- `Cmd + Shift + F`: Search in all files
- `Cmd + .`: Code actions/quick fixes
- `F5`: Start debugging
- `Shift + Cmd + B`: Build project
- `F12`: Go to definition
- `Option + Click`: Show definition preview

## Debugging

### Launch Configuration
Create .vscode/launch.json:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "lldb",
            "request": "launch",
            "name": "Debug App",
            "program": "${workspaceFolder}/.build/debug/YourApp",
            "args": [],
            "cwd": "${workspaceFolder}",
            "preLaunchTask": "swift-build"
        }
    ]
}
```

### Debug Console Commands
```bash
# Print current app state
po YourVariable

# Examine memory
memory read address

# Print backtrace
bt

# Continue execution
c
```

## Troubleshooting

### Common Issues and Solutions

1. Simulator Won't Boot
```bash
# Kill all simulator processes
killall Simulator
killall -9 com.apple.CoreSimulator.CoreSimulatorService

# Reset simulator content
xcrun simctl erase all
```

2. Build Failures
```bash
# Clean DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean build folder
xcodebuild clean
```

3. Code Completion Not Working
```bash
# Restart SourceKit-LSP
killall sourcekit-lsp
```

### Checking System Status
```bash
# Check Xcode path
xcode-select -p

# Verify Swift installation
swift --version

# Check sourcekit-lsp installation
which sourcekit-lsp

# List developer tools
xcode-select --install
```

### Log Collection
```bash
# Collect simulator logs
xcrun simctl spawn booted log show --predicate 'processImagePath contains "YourApp"'

# Export simulator device logs
xcrun simctl spawn booted log collect --output ~/Desktop/device_logs.logarchive
```