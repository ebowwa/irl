# Audio Management Module Documentation

This documentation provides a comprehensive overview of the **Audio Management Module** developed for your Swift application. The module is responsible for managing audio recordings, handling live streaming via WebSockets, maintaining audio state, and managing local audio files. It leverages various Apple frameworks such as `AVFoundation`, `Combine`, and `Speech` to deliver robust audio functionalities.

## Table of Contents

1. [Overview](#overview)
2. [Modules and Components](#modules-and-components)
    - [AudioFileManager](#audiofilemanager)
    - [WebSocketManagerProtocol](#websocketmanagerprotocol)
    - [WebSocketManager](#websocketmanager)
    - [AudioRecordingModel](#audiorecordingmodel)
    - [AudioState](#audiostate)
3. [Usage Examples](#usage-examples)
4. [Error Handling](#error-handling)
5. [Dependencies](#dependencies)
6. [License](#license)

---

## Overview

The Audio Management Module is designed to handle various aspects of audio recording and playback within your Swift application. It provides functionalities for:

- Managing local audio files (saving, updating, deleting).
- Recording audio either to a file or streaming live via WebSockets.
- Playing back recorded audio.
- Handling audio session configurations.
- Integrating speech recognition to analyze audio recordings.
- Publishing audio levels and other relevant state information using Combine.

This modular approach ensures separation of concerns, making the codebase maintainable and scalable.

---

## Modules and Components

### AudioFileManager

**File:** `AudioFileManager.swift`

**Description:**

`AudioFileManager` is a singleton class responsible for managing local audio recordings stored in the app's document directory. It provides functionalities to fetch, update, delete, and format audio file information.

**Class Definition:**

```swift
class AudioFileManager {
    static let shared = AudioFileManager()
    
    private init() {}
    
    // Methods...
}
```

**Methods:**

- **`getDocumentsDirectory() -> URL`**
  
  Returns the URL of the app's document directory where audio files are stored.
  
  ```swift
  func getDocumentsDirectory() -> URL
  ```

- **`updateLocalRecordings() -> [AudioRecording]`**
  
  Scans the document directory for `.m4a` files and returns a sorted list of `AudioRecording` objects representing each file.
  
  ```swift
  func updateLocalRecordings() -> [AudioRecording]
  ```

- **`deleteRecording(_ recording: AudioRecording) throws`**
  
  Deletes the specified audio recording file from the document directory.
  
  ```swift
  func deleteRecording(_ recording: AudioRecording) throws
  ```

- **`formattedFileSize(bytes: Int64) -> String`**
  
  Formats the file size from bytes to a human-readable string (KB or MB).
  
  ```swift
  func formattedFileSize(bytes: Int64) -> String
  ```

- **`formattedDuration(_ duration: TimeInterval) -> String`**
  
  Formats the duration from seconds to a `MM:SS` string format.
  
  ```swift
  func formattedDuration(_ duration: TimeInterval) -> String
  ```

**Usage Example:**

```swift
let recordings = AudioFileManager.shared.updateLocalRecordings()
for recording in recordings {
    print("Recording: \(recording.url.lastPathComponent), Size: \(AudioFileManager.shared.formattedFileSize(bytes: recording.fileSize))")
}
```

---

### WebSocketManagerProtocol

**File:** `WebSocketManagerProtocol.swift`

**Description:**

Defines protocols for managing WebSocket connections and audio state within the application. These protocols ensure that any WebSocket manager or audio state manager conforms to the required interface, promoting flexibility and testability.

**Protocols:**

- **`WebSocketManagerProtocol`**
  
  Defines the interface for a WebSocket manager handling audio data transmission.
  
  ```swift
  protocol WebSocketManagerProtocol {
      var receivedDataPublisher: AnyPublisher<Data, Never> { get }
      func sendAudioData(_ data: Data)
  }
  ```

- **`AudioStateProtocol`**
  
  Defines the interface for managing audio state, including recording, playback, and local recordings.
  
  ```swift
  protocol AudioStateProtocol: ObservableObject {
      // Published properties
      var isRecording: Bool { get set }
      var isPlaying: Bool { get set }
      var recordingTime: TimeInterval { get set }
      var recordingProgress: Double { get set }
      var currentRecording: AudioRecording? { get set }
      var isPlaybackAvailable: Bool { get set }
      var errorMessage: String? { get set }
      var localRecordings: [AudioRecording] { get set }
      var audioLevelPublisher: AnyPublisher<Float, Never> { get }
      var formattedRecordingTime: String { get }
      
      // Methods
      func setupWebSocket(manager: WebSocketManagerProtocol)
      func toggleRecording()
      func stopRecording()
      func togglePlayback()
      func deleteRecording(_ recording: AudioRecording)
      func updateLocalRecordings()
      func formattedFileSize(bytes: Int64) -> String
  }
  ```

---

### WebSocketManager

**File:** `WebSocketManagerProtocol.swift`

**Description:**

`WebSocketManager` conforms to the `WebSocketManagerProtocol` and handles the establishment and management of WebSocket connections. It sends audio data over the WebSocket and publishes any received data for further processing.

**Class Definition:**

```swift
class WebSocketManager: NSObject, WebSocketManagerProtocol {
    // Properties and Initializer
    
    // Methods...
}
```

**Properties:**

- **`receivedDataPublisher: AnyPublisher<Data, Never>`**
  
  A publisher that emits received data from the WebSocket.
  
  ```swift
  var receivedDataPublisher: AnyPublisher<Data, Never>
  ```

**Initializer:**

- **`init(url: URL)`**
  
  Initializes the WebSocket manager with the specified URL and sets up the WebSocket connection.
  
  ```swift
  init(url: URL)
  ```

**Methods:**

- **`sendAudioData(_ data: Data)`**
  
  Sends audio data over the established WebSocket connection.
  
  ```swift
  func sendAudioData(_ data: Data)
  ```

- **`private func setupWebSocket(url: URL)`**
  
  Establishes the WebSocket connection and starts receiving messages.
  
  ```swift
  private func setupWebSocket(url: URL)
  ```

- **`private func receiveMessage()`**
  
  Continuously listens for incoming WebSocket messages and publishes them.
  
  ```swift
  private func receiveMessage()
  ```

**Usage Example:**

```swift
let webSocketURL = URL(string: "wss://yourserver.com/socket")!
let webSocketManager = WebSocketManager(url: webSocketURL)

webSocketManager.receivedDataPublisher
    .sink { data in
        // Handle received data
    }
    .store(in: &cancellables)

webSocketManager.sendAudioData(audioData)
```

---

### AudioRecordingModel

**File:** `AudioRecordingModel.swift`

**Description:**

Defines the data models used within the Audio Management Module, including structures for location, device information, speech segments, transcription status, and the main `AudioRecording` model.

**Structures and Enums:**

- **`Location`**
  
  Represents the geographical location where the audio was recorded.
  
  ```swift
  struct Location {
      let latitude: Double
      let longitude: Double
      let altitude: Double?  // Optional
      let timestamp: Date
  }
  ```

- **`DeviceInfo`**
  
  Contains information about the device used to record the audio.
  
  ```swift
  struct DeviceInfo {
      let deviceModel: String
      let osVersion: String
      let deviceType: String?       // Optional
      let deviceName: String?       // Optional
  }
  ```

- **`SpeechSegment`**
  
  Represents segments of detected speech within an audio recording.
  
  ```swift
  struct SpeechSegment {
      let startTime: TimeInterval
      let endTime: TimeInterval
      let confidence: Double
  }
  ```

- **`TranscriptionStatus`**
  
  Enum representing the status of the transcription process.
  
  ```swift
  enum TranscriptionStatus {
      case pending
      case inProgress
      case completed
      case failed
  }
  ```

- **`AudioRecording`**
  
  The primary model representing an audio recording, including metadata and analysis results.
  
  ```swift
  struct AudioRecording: Identifiable {
      let id: UUID
      let url: URL
      let creationDate: Date
      let fileSize: Int64
      var isSpeechLikely: Bool?
      var speechSegments: [SpeechSegment]?
      var duration: TimeInterval?
      var location: Location?
      var transcriptionStatus: TranscriptionStatus = .pending
      var ambientNoiseLevel: Double?
      var deviceInfo: DeviceInfo?
      var processedAt: Date?
  }
  ```

**Usage Example:**

```swift
let recording = AudioRecording(
    id: UUID(),
    url: recordingURL,
    creationDate: Date(),
    fileSize: 2048,
    isSpeechLikely: true,
    speechSegments: [],
    duration: 120.0,
    location: Location(latitude: 37.7749, longitude: -122.4194, altitude: nil, timestamp: Date()),
    transcriptionStatus: .pending,
    ambientNoiseLevel: nil,
    deviceInfo: DeviceInfo(deviceModel: "iPhone 14", osVersion: "iOS 17", deviceType: nil, deviceName: nil),
    processedAt: nil
)
```

---

### AudioState

**File:** `AudioStateIndex.swift`

**Description:**

`AudioState` is a singleton class conforming to `AudioStateProtocol`. It manages the overall audio state of the application, including recording, playback, handling audio sessions, integrating with WebSockets for live streaming, and managing local recordings. It utilizes `Combine` for reactive state management and `Speech` for speech recognition.

**Class Definition:**

```swift
class AudioState: NSObject, AudioStateProtocol {
    static let shared = AudioState()
    
    // Published Properties
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordingProgress: Double = 0
    @Published var currentRecording: AudioRecording?
    @Published var isPlaybackAvailable = false
    @Published var errorMessage: String?
    @Published var localRecordings: [AudioRecording] = []
    
    // Other Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    private var recordingTimer: Timer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }
    
    private var audioEngine: AVAudioEngine?
    private var webSocketManager: WebSocketManagerProtocol?
    private let audioBufferSize: AVAudioFrameCount = 1024
    
    private var cancellables: Set<AnyCancellable> = []
    
    // Initializer and Methods...
}
```

**Published Properties:**

- **`isRecording: Bool`**
  
  Indicates whether audio recording is currently active.

- **`isPlaying: Bool`**
  
  Indicates whether audio playback is currently active.

- **`recordingTime: TimeInterval`**
  
  Tracks the duration of the current recording.

- **`recordingProgress: Double`**
  
  Represents the progress of the recording as a percentage.

- **`currentRecording: AudioRecording?`**
  
  Holds the currently active `AudioRecording`.

- **`isPlaybackAvailable: Bool`**
  
  Indicates whether playback is available for the current recording.

- **`errorMessage: String?`**
  
  Stores any error messages related to audio operations.

- **`localRecordings: [AudioRecording]`**
  
  Contains a list of all local audio recordings.

**Other Properties:**

- **`audioLevelPublisher: AnyPublisher<Float, Never>`**
  
  Publishes real-time audio levels for UI visualization.

**Initializer:**

- **`init()`**
  
  Sets up the audio session and fetches existing local recordings upon initialization.
  
  ```swift
  override init()
  ```

**Methods:**

- **`setupWebSocket(manager: WebSocketManagerProtocol)`**
  
  Assigns a WebSocket manager for live audio streaming.
  
  ```swift
  func setupWebSocket(manager: WebSocketManagerProtocol)
  ```

- **`toggleRecording()`**
  
  Toggles between starting and stopping audio recording.
  
  ```swift
  func toggleRecording()
  ```

- **`startRecording()`**
  
  Initiates audio recording, either live streaming or file recording based on WebSocket availability.
  
  ```swift
  func startRecording()
  ```

- **`stopRecording()`**
  
  Stops the current audio recording and updates the state accordingly.
  
  ```swift
  func stopRecording()
  ```

- **`startLiveStreaming()`**
  
  Configures and starts live audio streaming via WebSocket.
  
  ```swift
  private func startLiveStreaming()
  ```

- **`processMicrophoneBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime)`**
  
  Processes incoming audio buffers from the microphone and sends them over WebSocket.
  
  ```swift
  private func processMicrophoneBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime)
  ```

- **`startFileRecording()`**
  
  Configures and starts audio recording to a file.
  
  ```swift
  private func startFileRecording()
  ```

- **`startRecordingTimer()`**
  
  Starts a timer to track recording duration and update audio levels.
  
  ```swift
  private func startRecordingTimer()
  ```

- **`stopRecordingTimer()`**
  
  Stops the recording timer.
  
  ```swift
  private func stopRecordingTimer()
  ```

- **`updateAudioLevels()`**
  
  Updates the audio level for UI purposes.
  
  ```swift
  private func updateAudioLevels()
  ```

- **`updateCurrentRecording()`**
  
  Updates the `currentRecording` property with the latest recording information.
  
  ```swift
  private func updateCurrentRecording()
  ```

- **`updateLocalRecordings()`**
  
  Fetches and updates the list of local recordings, initiating speech likelihood analysis if needed.
  
  ```swift
  func updateLocalRecordings()
  ```

- **`fetchRecordings()`**
  
  Alias for `updateLocalRecordings()`.
  
  ```swift
  func fetchRecordings()
  ```

- **`deleteRecording(_ recording: AudioRecording)`**
  
  Deletes a specified recording and updates the local recordings list.
  
  ```swift
  func deleteRecording(_ recording: AudioRecording)
  ```

- **`determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void)`**
  
  Uses speech recognition to determine if the recording likely contains speech.
  
  ```swift
  private func determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void)
  ```

- **`togglePlayback()`**
  
  Toggles between starting and pausing audio playback.
  
  ```swift
  func togglePlayback()
  ```

- **`startPlayback()`**
  
  Initiates playback of the current recording.
  
  ```swift
  private func startPlayback()
  ```

- **`pausePlayback()`**
  
  Pauses audio playback.
  
  ```swift
  private func pausePlayback()
  ```

- **`formattedRecordingTime: String`**
  
  Provides a formatted string of the current recording time.
  
  ```swift
  var formattedRecordingTime: String
  ```

- **`formattedFileSize(bytes: Int64) -> String`**
  
  Formats a given byte count into a human-readable string.
  
  ```swift
  func formattedFileSize(bytes: Int64) -> String
  ```

**Delegate Conformance:**

- **`AVAudioPlayerDelegate`**
  
  Handles playback completion events.
  
  ```swift
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
  ```

**Usage Example:**

```swift
// Accessing the shared AudioState instance
let audioState = AudioState.shared

// Starting a recording
audioState.toggleRecording()

// Observing recording time
audioState.$recordingTime
    .sink { time in
        print("Recording Time: \(time) seconds")
    }
    .store(in: &cancellables)

// Setting up WebSocket for live streaming
let webSocketURL = URL(string: "wss://yourserver.com/socket")!
let webSocketManager = WebSocketManager(url: webSocketURL)
audioState.setupWebSocket(manager: webSocketManager)

// Handling received data
webSocketManager.receivedDataPublisher
    .sink { data in
        // Process received audio data
    }
    .store(in: &cancellables)
```

---

## Usage Examples

Below are some practical examples demonstrating how to utilize the various components of the Audio Management Module within your Swift application.

### Recording Audio

```swift
import SwiftUI
import Combine

struct RecordingView: View {
    @ObservedObject var audioState = AudioState.shared
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            Text(audioState.formattedRecordingTime)
                .font(.largeTitle)
            
            Button(action: {
                audioState.toggleRecording()
            }) {
                Image(systemName: audioState.isRecording ? "stop.circle" : "mic.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(audioState.isRecording ? .red : .blue)
            }
            
            if audioState.isRecording {
                AudioLevelView(audioLevelPublisher: audioState.audioLevelPublisher)
            }
            
            List(audioState.localRecordings) { recording in
                HStack {
                    Text(recording.url.lastPathComponent)
                    Spacer()
                    Text(audioState.formattedFileSize(bytes: recording.fileSize))
                    Button(action: {
                        audioState.togglePlayback()
                    }) {
                        Image(systemName: audioState.isPlaying ? "pause.circle" : "play.circle")
                    }
                }
            }
        }
        .onAppear {
            audioState.fetchRecordings()
        }
        .alert(item: $audioState.errorMessage) { error in
            Alert(title: Text("Error"), message: Text(error), dismissButton: .default(Text("OK")))
        }
    }
}

struct AudioLevelView: View {
    @State private var audioLevel: Float = 0.0
    private var cancellable: AnyCancellable
    
    init(audioLevelPublisher: AnyPublisher<Float, Never>) {
        self.cancellable = audioLevelPublisher.assign(to: \.audioLevel, on: self)
    }
    
    var body: some View {
        ProgressView(value: Double(audioLevel + 160) / 160)
            .progressViewStyle(LinearProgressViewStyle())
            .padding()
    }
}
```

### Streaming Audio via WebSocket

```swift
import Combine

class LiveStreamingManager {
    private var audioState = AudioState.shared
    private var webSocketManager: WebSocketManagerProtocol
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        let webSocketURL = URL(string: "wss://yourserver.com/socket")!
        self.webSocketManager = WebSocketManager(url: webSocketURL)
        audioState.setupWebSocket(manager: webSocketManager)
        
        // Subscribe to received data
        webSocketManager.receivedDataPublisher
            .sink { data in
                // Handle received audio data
            }
            .store(in: &cancellables)
    }
    
    func startStreaming() {
        audioState.toggleRecording()
    }
    
    func stopStreaming() {
        audioState.stopRecording()
    }
}
```

---

## Error Handling

The Audio Management Module incorporates comprehensive error handling to ensure that any issues encountered during audio operations are gracefully managed and communicated to the user.

- **Error Messages:**
  
  Errors are captured and stored in the `errorMessage` property of `AudioState`. This property is marked with `@Published`, allowing the UI to reactively display error messages when they occur.
  
  ```swift
  @Published var errorMessage: String?
  ```

- **Error Scenarios:**
  
  - **Audio Session Setup Failure:** If the audio session fails to configure, an error message is set.
  
  - **Recording Failure:** Errors during the initiation or stopping of recordings are captured.
  
  - **Playback Issues:** Errors encountered during audio playback are handled and communicated.
  
  - **WebSocket Errors:** Errors in sending or receiving data over WebSocket are printed to the console and can be extended to update the UI if necessary.

- **Displaying Errors:**
  
  In your SwiftUI views, you can observe the `errorMessage` and present alerts or other UI elements to inform the user.

  ```swift
  .alert(item: $audioState.errorMessage) { error in
      Alert(title: Text("Error"), message: Text(error), dismissButton: .default(Text("OK")))
  }
  ```

---

## Dependencies

The Audio Management Module relies on the following Apple frameworks:

- **`Foundation`**
  
  Provides essential data types, collections, and operating-system services.

- **`AVFoundation`**
  
  Handles audio recording, playback, and processing.

- **`Combine`**
  
  Manages asynchronous events through publishers and subscribers.

- **`Speech`**
  
  Enables speech recognition capabilities for analyzing audio recordings.

- **`CoreLocation`** (Optional)
  
  Used for handling location data associated with recordings.

**Import Statements:**

Ensure that these frameworks are imported in the relevant Swift files.

```swift
import Foundation
import AVFoundation
import Combine
import Speech
import CoreLocation
```

---

## License

This Audio Management Module is developed and owned by Elijah Arbee. Ensure that any usage complies with your project's licensing agreements and guidelines.

---

# Conclusion

This documentation provides a detailed overview of the Audio Management Module, explaining each component's role and functionality. By following this guide, developers can understand, maintain, and extend the module to fit evolving project requirements effectively.
