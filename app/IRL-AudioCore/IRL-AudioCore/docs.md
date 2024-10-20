# AudioState Framework SDK Documentation

## Overview

The `AudioState` framework provides a centralized system for managing audio recording, playback, live audio streaming, and speech recognition tasks. The framework encapsulates the complexities of AVFoundation, WebSockets, and Speech recognition into a simple API, allowing developers to easily integrate audio features into their iOS or watchOS applications.

### Key Features:
- **Singleton Pattern**: Centralized `AudioState` class for managing audio across the application.
- **Recording & Playback**: Start, stop, and manage audio recordings with a single call.
- **Live Streaming**: Capture and stream live audio using WebSockets.
- **Speech Recognition**: Analyze recordings to determine the presence of speech.
- **Combine Integration**: Leverage `@Published` properties and Combine publishers to track audio states, errors, and audio levels.

---

## Getting Started

To integrate the `AudioState` framework into your app, follow these steps:

### 1. Installation

Since this framework is not yet hosted as a package, manually include the files in your Xcode project. Import the necessary frameworks (`AVFoundation`, `Speech`, `UIKit`) within your project, and ensure the permissions for audio recording and speech recognition are declared in your app's `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required to record audio.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition access is required to analyze recordings.</string>
```

### 2. Initial Setup

The `AudioState` class is a singleton. Access its instance via `AudioState.shared` to handle all audio operations. Ensure your app initializes the audio session at an appropriate point, like in the app's entry point or when the user accesses audio-related features.

#### Example:
```swift
let audioState = AudioState.shared
```

### 3. Setting Up WebSockets for Live Streaming

If you need to stream live audio, you must provide a `WebSocketManagerProtocol` instance to `AudioState` to handle WebSocket communication.

#### Example:
```swift
let webSocketManager = MyCustomWebSocketManager()
AudioState.shared.setupWebSocket(manager: webSocketManager)
```

### 4. Observing State Changes

The framework uses `@Published` properties, allowing developers to observe changes using Swift's Combine framework.

#### Example (Observing Recording State):
```swift
audioState.$isRecording
    .sink { isRecording in
        print("Recording state changed: \(isRecording)")
    }
    .store(in: &cancellables)
```

### 5. Recording Audio

You can toggle recording using `toggleRecording()`, which automatically switches between starting and stopping recordings based on the current state. It automatically selects between live streaming and file-based recording based on the WebSocket configuration.

#### Example (Start/Stop Recording):
```swift
AudioState.shared.toggleRecording()
```

#### Example (Start Recording with WebSocket):
```swift
AudioState.shared.startRecording()
```

### 6. Playback Control

You can toggle playback of the most recent recording using `togglePlayback()`.

#### Example (Start/Stop Playback):
```swift
AudioState.shared.togglePlayback()
```

### 7. Fetching Local Recordings

You can access the locally saved recordings via the `localRecordings` property, which holds an array of `AudioRecording` objects.

#### Example (Fetching Local Recordings):
```swift
AudioState.shared.fetchRecordings()
let recordings = AudioState.shared.localRecordings
```

### 8. Deleting a Recording

You can delete a specific recording by passing an `AudioRecording` instance to `deleteRecording(_:)`.

#### Example (Delete a Recording):
```swift
if let recording = AudioState.shared.localRecordings.first {
    AudioState.shared.deleteRecording(recording)
}
```

---

## API Reference

### `AudioState`

#### Properties

- **shared**: Singleton instance of `AudioState`.
- **isRecording**: Published property (`Bool`) that tracks whether recording is currently active.
- **isPlaying**: Published property (`Bool`) that tracks whether playback is currently active.
- **recordingTime**: Published property (`TimeInterval`) that tracks the duration of the current recording.
- **recordingProgress**: Published property (`Double`) that tracks the progress of the recording.
- **currentRecording**: Published property (`AudioRecording?`) that holds the current recording.
- **isPlaybackAvailable**: Published property (`Bool`) indicating whether playback is available.
- **errorMessage**: Published property (`String?`) that holds any error message encountered during operations.
- **localRecordings**: Published property (`[AudioRecording]`) that contains a list of local audio recordings.
- **audioLevelPublisher**: A `Combine` publisher that streams audio level changes during recording.

#### Methods

- **setupWebSocket(manager:)**: Assigns a WebSocket manager for live streaming. Must conform to `WebSocketManagerProtocol`.
  - **Parameters**:
    - `manager`: An object that conforms to `WebSocketManagerProtocol`.

- **toggleRecording()**: Starts or stops recording based on the current state.

- **startRecording()**: Starts a new recording session, either live streaming or file-based, depending on WebSocket availability.

- **stopRecording()**: Stops the current recording session.

- **togglePlayback()**: Starts or pauses the playback of the current recording.

- **fetchRecordings()**: Fetches all locally stored recordings and updates the `localRecordings` property.

- **deleteRecording(_:)**: Deletes the specified recording from local storage.
  - **Parameters**:
    - `recording`: The `AudioRecording` instance to be deleted.

#### Helper Methods (Internal)
- **setupAudioSession()**: Configures the AVAudioSession for recording and playback.
- **startLiveStreaming()**: Starts live audio streaming using AVAudioEngine and sends audio data over WebSocket.
- **startFileRecording()**: Starts recording audio to a local file.
- **updateAudioLevels()**: Updates the audio levels during recording using AVAudioRecorder’s metering data.

### `WebSocketManagerProtocol`

A protocol that must be conformed to by any WebSocket manager used for live streaming.

#### Required Methods:
- **sendAudioData(_:)**: Sends captured audio data over WebSocket.
  - **Parameters**:
    - `data`: The `Data` object containing the audio buffer to be sent.

### `AudioRecording`

Represents a local audio recording.

#### Properties:
- **url**: The local file URL of the recording.
- **duration**: The duration of the recording.
- **isSpeechLikely**: An optional `Bool` that indicates whether speech is detected in the recording.

---

## Example Usage

Here’s a full example of how to integrate the `AudioState` framework into an app:

```swift
import SwiftUI
import Combine
import AudioFramework

struct ContentView: View {
    @ObservedObject var audioState = AudioState.shared
    @State private var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        VStack {
            Text("Recording: \(audioState.isRecording ? "Yes" : "No")")
            Text("Playing: \(audioState.isPlaying ? "Yes" : "No")")
            Text("Error: \(audioState.errorMessage ?? "None")")

            Button(action: {
                audioState.toggleRecording()
            }) {
                Text(audioState.isRecording ? "Stop Recording" : "Start Recording")
            }
            
            Button(action: {
                audioState.togglePlayback()
            }) {
                Text(audioState.isPlaying ? "Pause Playback" : "Play Recording")
            }
        }
        .onAppear {
            // Start observing state changes
            audioState.$isRecording
                .sink { isRecording in
                    print("Recording state changed: \(isRecording)")
                }
                .store(in: &cancellables)
        }
    }
}
```
