# openaudiostandard Framework SDK Documentation

## Overview

The `openaudiostandard` framework is designed to simplify audio management for iOS and watchOS applications. It encapsulates core functionalities like recording, playback, live audio streaming, and speech recognition, offering an efficient, centralized system to handle audio tasks while minimizing complexity for developers. This framework provides a comprehensive suite of tools for audio recording, playback, speech recognition, sound measurement, and location tracking. It is designed to facilitate the integration of advanced audio functionalities into your Swift applications seamlessly.

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Core Components](#core-components)
    - [AudioFileManager](#audiofilemanager)
    - [AudioRecording](#audiorecording)
    - [AudioState](#audiostate)
    - [AudioEngineManager](#audioenginemanager)
    - [LocationData](#locationdata)
    - [LocationManager](#locationmanager)
    - [WebSocketManager](#websocketmanager)
    - [SoundMeasurementManager](#soundmeasurementmanager)
    - [SpeechRecognitionManager](#speechrecognitionmanager)
4. [Protocols](#protocols)
    - [WebSocketManagerProtocol](#websocketmanagerprotocol)
    - [AudioEngineManagerProtocol](#audioenginemanagerprotocol)
    - [AudioStateProtocol](#audiostateprotocol)
5. [Usage Examples](#usage-examples)
6. [Error Handling](#error-handling)
7. [License](#license)
8. [Contact](#contact)

---

## Overview

**openaudiostandard** is a robust Swift framework designed to handle various audio-related functionalities, including:

- **Audio File Management**: Recording, saving, retrieving, and deleting audio files.
- **Audio Playback**: Playing recorded audio files with control over playback states.
- **Speech Recognition**: Transcribing audio recordings to text and detecting speech presence.
- **Sound Measurement**: Analyzing audio levels and background noise.
- **Location Tracking**: Capturing and managing user location data.
- **WebSocket Integration**: Streaming audio data in real-time.

This SDK leverages Apple's AVFoundation, Combine, and Speech frameworks to deliver high-performance audio processing and management capabilities.

---

## Installation

To integrate **openaudiostandard** into your Swift project, follow these steps:

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/your-repo/IRL-AudioCore.git
   ```

2. **Add to Your Project**:

   - Drag and drop the `IRL-AudioCore` folder into your Xcode project.
   - Ensure that all the necessary files are included in your project target.

3. **Import the Framework**:

   In your Swift files, import the framework:

   ```swift
   import openaudiostandard
   ```

4. **Configure Permissions**:

   Ensure that your app's `Info.plist` includes the necessary permissions for audio recording, speech recognition, and location services:

   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>We need access to your microphone to record audio.</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>We need access to speech recognition to transcribe your recordings.</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need access to your location to tag your recordings.</string>
   ```

---

## Core Components

### AudioFileManager

**File**: `AudioFileManager.swift`  
**Framework**: AudioFramework

**Description**:  
`AudioFileManager` is a singleton class responsible for managing audio files within the app's document directory. It provides functionalities to retrieve, update, and delete audio recordings.

**Usage**:

```swift
let fileManager = AudioFileManager.shared
let documentsURL = fileManager.getDocumentsDirectory()
let recordings = fileManager.updateLocalRecordings()
try fileManager.deleteRecording(recording)
let formattedDuration = fileManager.formattedDuration(duration)
let formattedSize = fileManager.formattedFileSize(bytes: fileSize)
```

**Properties**:

- `shared`: `AudioFileManager`  
  Singleton instance for global access.

**Methods**:

- `getDocumentsDirectory() -> URL`  
  Returns the URL of the app's documents directory.

- `updateLocalRecordings() -> [AudioRecording]`  
  Fetches and returns a sorted list of local audio recordings.

- `deleteRecording(_ recording: AudioRecording) throws`  
  Deletes a specific audio recording from local storage.

- `formattedDuration(_ duration: TimeInterval) -> String`  
  Formats a duration interval into a `MM:SS` string.

- `formattedFileSize(bytes: Int64) -> String`  
  Formats a file size in bytes into a human-readable string (e.g., MB).

---

### AudioRecording

**File**: `AudioRecordingModel.swift`  
**Framework**: openaudiostandard

**Description**:  
`AudioRecording` is a struct representing an individual audio recording. It conforms to the `Identifiable` protocol, allowing it to be used seamlessly with SwiftUI views.

**Usage**:

```swift
let recording = AudioRecording(url: recordingURL)
print(recording.id)
```

**Properties**:

- `id`: `UUID`  
  Unique identifier for the recording.

- `url`: `URL`  
  File URL of the audio recording.

- `isSpeechLikely`: `Bool?`  
  Optional flag indicating whether the recording likely contains speech.

**Initializer**:

```swift
init(id: UUID = UUID(), url: URL, isSpeechLikely: Bool? = nil)
```

---

### AudioState

**File**: `AudioState.swift`  
**Framework**: openaudiostandard

**Description**:  
`AudioState` is a singleton class that manages the overall audio state within the application. It handles recording, playback, audio session configurations, and integrates with other managers like `SpeechRecognitionManager` and `SoundMeasurementManager`.

**Usage**:

```swift
let audioState = AudioState.shared
audioState.toggleRecording(manual: true)
audioState.togglePlayback()
audioState.setupWebSocket(manager: webSocketManager)
```

**Properties**:

- **Published Properties**:

  - `isRecording`: `Bool`  
    Indicates whether a recording is in progress.

  - `isPlaying`: `Bool`  
    Indicates whether audio playback is in progress.

  - `recordingTime`: `TimeInterval`  
    Tracks the duration of the current recording.

  - `recordingProgress`: `Double`  
    Represents the progress or audio level during recording.

  - `isPlaybackAvailable`: `Bool`  
    Indicates whether playback is available.

  - `errorMessage`: `String?`  
    Stores error messages related to audio operations.

  - `localRecordings`: `[AudioRecording]`  
    List of local audio recordings.

  - `currentRecording`: `AudioRecording?`  
    The currently selected recording for playback.

- **Persistent Storage Properties**:

  - `isRecordingEnabled`: `Bool`  
    Indicates if recording is enabled.

  - `isBackgroundRecordingEnabled`: `Bool`  
    Indicates if background recording is enabled.

- **Audio Components**:

  - `audioRecorder`: `AVAudioRecorder?`  
    Manages audio recording.

  - `audioPlayer`: `AVAudioPlayer?`  
    Manages audio playback.

  - `recordingSession`: `AVAudioSession?`  
    Manages the audio session.

  - `recordingTimer`: `Timer?`  
    Timer for tracking recording duration.

- **Managers**:

  - `speechRecognitionManager`: `SpeechRecognitionManager`  
    Manages speech recognition.

  - `soundMeasurementManager`: `SoundMeasurementManager`  
    Manages sound level measurements.

- **WebSocket Manager**:

  - `webSocketManager`: `WebSocketManagerProtocol?`  
    Manages live audio streaming via WebSocket.

- **Control Flags**:

  - `isManualRecording`: `Bool`  
    Indicates if the recording was manually started by the user.

- **Publishers**:

  - `cancellables`: `Set<AnyCancellable>`  
    Manages Combine subscriptions.

  - `audioEngineCancellables`: `Set<AnyCancellable>`  
    Manages Combine subscriptions for audio engine.

**Methods**:

- **Setup Methods**:

  - `setupBindings()`  
    Sets up Combine bindings to receive audio levels and other updates.

  - `setupSpeechRecognitionManager()`  
    Configures speech recognition callbacks.

  - `setupNotifications()`  
    Registers for system notifications related to app lifecycle.

- **Notification Handlers**:

  - `handleAppBackgrounding()`  
    Handles app transitioning to the background.

  - `handleAppTermination()`  
    Handles app termination events.

- **WebSocket Setup**:

  - `setupWebSocket(manager: WebSocketManagerProtocol)`  
    Assigns a WebSocket manager for live audio streaming.

- **Audio Session Setup**:

  - `setupAudioSession(caller: String = #function)`  
    Configures the AVAudioSession for playback and recording.

- **Recording Controls**:

  - `toggleRecording(manual: Bool)`  
    Toggles between starting and stopping a recording session.

  - `startRecording(manual: Bool)`  
    Initiates recording, with optional live streaming.

  - `stopRecording()`  
    Stops the current recording and updates the state.

- **File Recording**:

  - `startFileRecording()`  
    Begins a file-based audio recording.

- **Recording Timer**:

  - `startRecordingTimer()`  
    Starts a timer to track recording duration.

  - `stopRecordingTimer()`  
    Stops the recording timer.

  - `updateAudioLevels()`  
    Updates audio levels based on recorder's meter data.

  - `mapAudioLevelToProgress(_ averagePower: Float) -> Double`  
    Maps average power in decibels to a normalized progress value.

- **File Management**:

  - `updateCurrentRecording()`  
    Saves the current recording and updates the recordings list.

  - `updateLocalRecordings()`  
    Refreshes the list of local recordings.

  - `fetchRecordings()`  
    Fetches and reloads recordings, useful for UI updates.

  - `deleteRecording(_ recording: AudioRecording)`  
    Deletes a specified recording from local storage.

- **Playback Controls**:

  - `togglePlayback()`  
    Toggles between starting and pausing playback.

  - `startPlayback()`  
    Begins playback of the current recording.

  - `pausePlayback()`  
    Pauses the current playback.

- **Formatting Helpers**:

  - `formattedRecordingTime`: `String`  
    Returns the formatted recording duration.

  - `formattedFileSize(bytes: Int64) -> String`  
    Formats the file size for display.

- **Audio Level Publisher**:

  - `audioLevelPublisher`: `AnyPublisher<Float, Never>`  
    Emits the current audio level.

**Delegate Conformance**:

- **AVAudioRecorderDelegate**:

  - `audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)`  
    Called when recording finishes.

  - `audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?)`  
    Called when a recording error occurs.

- **AVAudioPlayerDelegate**:

  - `audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)`  
    Called when playback finishes.

  - `audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?)`  
    Called when a playback error occurs.

---

### AudioEngineManager

**File**: `Engine.swift`  

**Description**:  
`AudioEngineManager` is a singleton class that manages the AVAudioEngine for real-time audio processing and live streaming via WebSocket. It captures audio buffers, calculates audio levels, and handles recording to files.

**Usage**:

```swift
let engineManager = AudioEngineManager.shared
engineManager.startEngine()
engineManager.stopEngine()
engineManager.assignWebSocketManager(manager: webSocketManager)
engineManager.startRecording()
engineManager.stopRecording()
```

**Properties**:

- **Subjects**:

  - `audioLevelSubject`: `PassthroughSubject<Float, Never>`  
    Publishes the current audio level.

  - `audioBufferSubject`: `PassthroughSubject<AVAudioPCMBuffer, Never>`  
    Publishes audio buffers for processing.

- **Published Properties**:

  - `audioLevelPublisher`: `AnyPublisher<Float, Never>`  
    Exposes `audioLevelSubject` as a publisher.

  - `audioBufferPublisher`: `AnyPublisher<AVAudioPCMBuffer, Never>`  
    Exposes `audioBufferSubject` as a publisher.

- **Engine Properties**:

  - `isEngineRunning`: `Bool` (read-only)  
    Indicates whether the audio engine is running.

  - `audioEngine`: `AVAudioEngine`  
    The AVAudioEngine instance managing audio.

  - `webSocketManager`: `WebSocketManagerProtocol?`  
    Weak reference to the WebSocket manager.

  - `audioBufferSize`: `AVAudioFrameCount`  
    Size of the audio buffer per tap.

  - `isRecording`: `Bool`  
    Indicates if recording to file is active.

  - `audioFile`: `AVAudioFile?`  
    The audio file being recorded to.

**Methods**:

- **Initialization**:

  - `init()`  
    Initializes and sets up the audio session.

- **WebSocket Management**:

  - `assignWebSocketManager(manager: WebSocketManagerProtocol)`  
    Assigns a WebSocket manager for live streaming.

- **Engine Controls**:

  - `startEngine()`  
    Starts the AVAudioEngine for audio processing and streaming.

  - `stopEngine()`  
    Stops the AVAudioEngine.

- **Recording Controls**:

  - `startRecording()`  
    Begins recording audio to a file.

  - `stopRecording()`  
    Stops recording audio to a file.

- **Audio Processing**:

  - `processAudioBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime)`  
    Handles incoming audio buffers, sends data via WebSocket, publishes audio levels, and writes to file if recording.

- **Utility Methods**:

  - `calculateRMS(channelData: UnsafeMutablePointer<Float>, frameCount: Int) -> Float`  
    Calculates the Root Mean Square (RMS) of the audio signal.

**Usage Example**:

```swift
// Assign WebSocket Manager
let webSocketManager = WebSocketManager(url: websocketURL)
AudioEngineManager.shared.assignWebSocketManager(manager: webSocketManager)

// Start Audio Engine
AudioEngineManager.shared.startEngine()

// Start Recording
AudioEngineManager.shared.startRecording()

// Stop Recording
AudioEngineManager.shared.stopRecording()

// Stop Audio Engine
AudioEngineManager.shared.stopEngine()
```

---

### LocationData

**File**: `Location.swift`  
**Framework**: IRL-AudioCore

**Description**:  
`LocationData` is a struct that encapsulates detailed location information along with metadata. It conforms to the `Codable` protocol, allowing for easy serialization and storage.

**Usage**:

```swift
let locationData = LocationData(latitude: 37.7749, longitude: -122.4194, ...)
print(locationData.latitude)
```

**Properties**:

- `uuid`: `String`  
  Unique identifier for the location data entry.

- `latitude`: `Double?`  
  Latitude coordinate.

- `longitude`: `Double?`  
  Longitude coordinate.

- `accuracy`: `Double?`  
  Accuracy of the location data.

- `timestamp`: `Date`  
  Timestamp of when the location was captured.

- `altitude`: `Double?`  
  Altitude at the location.

- `speed`: `Double?`  
  Speed of the device at the location.

- `course`: `Double?`  
  Course direction at the location.

- `isLocationAvailable`: `Bool`  
  Indicates if the location data is available.

**Initializer**:

```swift
init(uuid: String = UUID().uuidString,
     latitude: Double?,
     longitude: Double?,
     accuracy: Double?,
     timestamp: Date,
     altitude: Double?,
     speed: Double?,
     course: Double?,
     isLocationAvailable: Bool)
```

---

### LocationManager

**File**: `Location.swift`  
**Framework**: openaudiostandard

**Description**:  
`LocationManager` is a singleton class that manages user location tracking. It provides real-time location updates and handles significant location changes for optimized performance.

**Usage**:

```swift
let locationManager = LocationManager.shared
locationManager.requestLocationAuthorization()

// Subscribe to location updates
locationManager.$currentLocation
    .sink { location in
        print("Current Location: \(location)")
    }
    .store(in: &cancellables)

// Subscribe to error messages
locationManager.$locationErrorMessage
    .sink { error in
        if let error = error {
            print("Location Error: \(error)")
        }
    }
    .store(in: &cancellables)
```

**Properties**:

- **Published Properties**:

  - `currentLocation`: `LocationData?`  
    The latest location data.

  - `locationErrorMessage`: `String?`  
    Stores error messages related to location services.

- **Private Properties**:

  - `locationManager`: `CLLocationManager`  
    The CLLocationManager instance managing location updates.

  - `lastLocation`: `CLLocation?`  
    The most recent location received.

  - `isMonitoringSignificantChanges`: `Bool`  
    Indicates if significant location changes are being monitored.

  - `locationSubject`: `PassthroughSubject<LocationData?, Never>`  
    Publisher for location updates.

**Methods**:

- **Initialization**:

  - `init()`  
    Sets up the CLLocationManager and requests location authorization.

- **Setup Methods**:

  - `setupLocationManager()`  
    Configures the CLLocationManager's properties and delegates.

- **Authorization**:

  - `requestLocationAuthorization()`  
    Requests when-in-use location authorization from the user.

- **CLLocationManagerDelegate Methods**:

  - `locationManager(_:didChangeAuthorization:)`  
    Handles changes in location authorization status.

  - `locationManager(_:didUpdateLocations:)`  
    Handles incoming location updates.

  - `locationManager(_:didFailWithError:)`  
    Handles errors during location updates.

- **Significant Change Monitoring**:

  - `startSignificantChangeMonitoring()`  
    Begins monitoring significant location changes.

  - `stopSignificantChangeMonitoring()`  
    Stops monitoring significant location changes.

- **Utility Methods**:

  - `generateLocationData(for location: CLLocation) -> LocationData`  
    Converts a CLLocation object into a LocationData struct.

**Usage Example**:

```swift
// Request Authorization
LocationManager.shared.requestLocationAuthorization()

// Observe Location Updates
LocationManager.shared.locationPublisher
    .sink { location in
        if let location = location {
            print("New Location: \(location)")
        }
    }
    .store(in: &cancellables)
```

---

### WebSocketManager

**File**: `socketmanager.swift`  
**Framework**: openaudiostandard

**Description**:  
`WebSocketManager` is a class that manages WebSocket connections for real-time audio streaming. It conforms to the `WebSocketManagerProtocol`, enabling seamless integration with other components of the SDK.

**Usage**:

```swift
let webSocketURL = URL(string: "wss://yourserver.com/socket")!
let webSocketManager = WebSocketManager(url: webSocketURL)

// Send Audio Data
webSocketManager.sendAudioData(audioData)

// Receive Data
webSocketManager.receivedDataPublisher
    .sink { data in
        // Handle received data
    }
    .store(in: &cancellables)
```

**Properties**:

- `receivedDataPublisher`: `AnyPublisher<Data, Never>`  
  Publisher that emits data received from the WebSocket.

- `webSocketTask`: `URLSessionWebSocketTask?`  
  The active WebSocket task.

**Methods**:

- **Initialization**:

  - `init(url: URL)`  
    Initializes the WebSocketManager with a specified URL and sets up the connection.

- **WebSocket Setup**:

  - `setupWebSocket(url: URL)`  
    Configures and starts the WebSocket connection.

- **Data Transmission**:

  - `sendAudioData(_ data: Data)`  
    Sends audio data through the WebSocket connection.

- **Data Reception**:

  - `receiveMessage()`  
    Listens for incoming messages from the WebSocket.

- **Deinitialization**:

  - `deinit`  
    Cancels the WebSocket task when the manager is deallocated.

**Usage Example**:

```swift
// Initialize WebSocket Manager
let webSocketURL = URL(string: "wss://yourserver.com/socket")!
let webSocketManager = WebSocketManager(url: webSocketURL)

// Assign to AudioEngineManager
AudioEngineManager.shared.assignWebSocketManager(manager: webSocketManager)

// Listen for Incoming Data
webSocketManager.receivedDataPublisher
    .sink { data in
        // Process received data
    }
    .store(in: &cancellables)
```

---

### SoundMeasurementManager

**File**: `SoundMeasurement.swift`  
**Framework**: openaudiostandard

**Description**:  
`SoundMeasurementManager` is a singleton class responsible for analyzing audio levels, measuring background noise, and detecting speech presence. It integrates with `AudioEngineManager` and `SpeechRecognitionManager` to provide comprehensive sound analysis.

**Usage**:

```swift
let soundManager = SoundMeasurementManager.shared
let currentLevel = soundManager.currentAudioLevel
let backgroundNoise = soundManager.averageBackgroundNoise
```

**Properties**:

- **Published Properties**:

  - `currentAudioLevel`: `Double`  
    The current normalized audio level.

  - `averageBackgroundNoise`: `Double`  
    The average background noise level.

  - `isBackgroundNoiseReady`: `Bool`  
    Indicates if background noise calibration is complete.

  - `isSpeechDetected`: `Bool`  
    Indicates if speech is currently detected.

- **Persistent Storage Properties**:

  - `isBackgroundNoiseCalibrated`: `Bool`  
    Indicates if background noise has been calibrated.

  - `averageBackgroundNoisePersisted`: `Double`  
    Persisted average background noise level.

- **Private Properties**:

  - `backgroundNoiseLevels`: `[Double]`  
    Array storing background noise levels.

  - `isCollectingBackgroundNoise`: `Bool`  
    Indicates if background noise collection is active.

  - `backgroundNoiseTimer`: `Timer?`  
    Timer for background noise calibration.

  - `lastCalibrationTime`: `Date`  
    Timestamp of the last calibration.

  - `cancellables`: `Set<AnyCancellable>`  
    Manages Combine subscriptions.

  - `speechRecognitionManager`: `SpeechRecognitionManager`  
    Reference to the speech recognition manager.

**Methods**:

- **Initialization**:

  - `init()`  
    Sets up Combine bindings for audio levels and speech detection.

- **Setup Bindings**:

  - `setupBindings()`  
    Subscribes to audio level updates from `AudioEngineManager` and speech detection updates from `SpeechRecognitionManager`.

- **Audio Level Handling**:

  - `handleAudioLevel(_ level: Float)`  
    Processes incoming audio levels, manages background noise calibration, and adjusts current audio levels.

- **Background Noise Management**:

  - `startBackgroundNoiseCollection()`  
    Initiates the collection of background noise levels.

  - `resetBackgroundNoiseCollection()`  
    Resets the background noise collection process upon speech detection.

  - `computeAverageBackgroundNoise()`  
    Calculates the average background noise from collected levels.

  - `updateBackgroundNoise(_ average: Double)`  
    Updates and persists the average background noise.

  - `updateNoiseIfCalibrated(_ normalizedLevel: Double)`  
    Updates background noise levels using Exponential Moving Average (EMA).

  - `adjustCurrentAudioLevelIfReady(_ normalizedLevel: Double)`  
    Adjusts the current audio level based on calibrated background noise.

**Usage Example**:

```swift
// Access Current Audio Level
let currentLevel = SoundMeasurementManager.shared.currentAudioLevel

// Access Average Background Noise
let averageNoise = SoundMeasurementManager.shared.averageBackgroundNoise

// Listen for Changes
SoundMeasurementManager.shared.$currentAudioLevel
    .sink { level in
        print("Current Audio Level: \(level)")
    }
    .store(in: &cancellables)
```

---

### SpeechRecognitionManager

**File**: `SpeechRecognition.swift`  
**Framework**: openaudiostandard

**Description**:  
`SpeechRecognitionManager` is a singleton class that manages speech recognition functionalities. It transcribes audio recordings to text, detects speech presence, and provides metadata about the transcription process.

**Usage**:

```swift
let speechManager = SpeechRecognitionManager.shared
speechManager.requestSpeechAuthorization()
speechManager.startRecording()

// Listen for Transcribed Text
speechManager.$transcribedText
    .sink { text in
        print("Transcribed Text: \(text)")
    }
    .store(in: &cancellables)
```

**Properties**:

- **Published Properties**:

  - `transcribedText`: `String`  
    The latest transcribed text from speech recognition.

  - `transcriptionSegments`: `[String]`  
    Segments of the transcribed text.

  - `isSpeechDetected`: `Bool`  
    Indicates if speech is currently detected.

  - `speechMetadata`: `[String: Any]`  
    Metadata related to the speech recognition process.

- **Callbacks**:

  - `onSpeechStart`: `(() -> Void)?`  
    Closure invoked when speech detection starts.

  - `onSpeechEnd`: `(() -> Void)?`  
    Closure invoked when speech detection ends.

- **Private Properties**:

  - `speechRecognizer`: `SFSpeechRecognizer`  
    The speech recognizer instance.

  - `recognitionRequest`: `SFSpeechAudioBufferRecognitionRequest?`  
    The current speech recognition request.

  - `recognitionTask`: `SFSpeechRecognitionTask?`  
    The current speech recognition task.

  - `lastTranscription`: `String`  
    The last transcribed string.

  - `cancellables`: `Set<AnyCancellable>`  
    Manages Combine subscriptions.

  - `maxSegmentCount`: `Int`  
    Maximum number of transcription segments to retain.

- **Streamed Properties**:

  - `audioEngineManager`: `AudioEngineManagerProtocol`  
    Reference to the audio engine manager.

**Methods**:

- **Initialization**:

  - `init(audioEngineManager: AudioEngineManagerProtocol = AudioEngineManager.shared)`  
    Initializes the manager with an audio engine manager.

- **Authorization**:

  - `requestSpeechAuthorization()`  
    Requests authorization for speech recognition.

- **Recording Control**:

  - `startRecording()`  
    Starts the speech recognition process.

  - `stopRecording()`  
    Stops the speech recognition process.

- **Recognition Task Management**:

  - `resetRecognitionTask()`  
    Cancels and resets the current recognition task.

- **Speech Recognition Setup**:

  - `setupSpeechRecognition()`  
    Configures the speech recognition request and task.

- **Streaming Transcription Handling**:

  - `handleStreamingResult(_ result: SFSpeechRecognitionResult?, _ error: Error?)`  
    Processes the results from the speech recognizer.

  - `updateTranscriptionSegments(from transcription: SFTranscription)`  
    Updates the transcription segments based on new data.

- **Speech Likelihood Analysis**:

  - `determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void)`  
    Analyzes an audio file to determine if it contains speech.

- **Audio Buffer Subscription**:

  - `subscribeToAudioBuffers()`  
    Subscribes to audio buffers from the audio engine manager for real-time transcription.

**Usage Example**:

```swift
// Request Authorization
SpeechRecognitionManager.shared.requestSpeechAuthorization()

// Start Recording for Transcription
SpeechRecognitionManager.shared.startRecording()

// Listen for Transcriptions
SpeechRecognitionManager.shared.$transcribedText
    .sink { text in
        print("Transcribed Text: \(text)")
    }
    .store(in: &cancellables)

// Stop Recording
SpeechRecognitionManager.shared.stopRecording()
```

---

## Protocols

### WebSocketManagerProtocol

**File**: `Protocols.swift`  
**Framework**: openaudiostandard

**Description**:  
`WebSocketManagerProtocol` defines the interface for managing WebSocket connections, enabling live audio streaming functionalities.

**Definition**:

```swift
public protocol WebSocketManagerProtocol: AnyObject {
    var receivedDataPublisher: AnyPublisher<Data, Never> { get }
    func sendAudioData(_ data: Data)
}
```

**Requirements**:

- **Properties**:

  - `receivedDataPublisher`: `AnyPublisher<Data, Never>`  
    A publisher that emits data received from the WebSocket.

- **Methods**:

  - `sendAudioData(_ data: Data)`  
    Sends audio data through the WebSocket connection.

**Usage**:  
Implement this protocol to create custom WebSocket managers or use the provided `WebSocketManager` class.

---

### AudioEngineManagerProtocol

**File**: `Protocols.swift`  
**Framework**: IRL-AudioCore

**Description**:  
`AudioEngineManagerProtocol` defines the interface for managing the audio engine, enabling functionalities like audio level publishing and audio buffer processing.

**Definition**:

```swift
public protocol AudioEngineManagerProtocol: AnyObject {
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> { get }
    var isEngineRunning: Bool { get }
    func startEngine()
    func stopEngine()
    func assignWebSocketManager(manager: WebSocketManagerProtocol)
    func startRecording()
    func stopRecording()
}
```

**Requirements**:

- **Properties**:

  - `audioLevelPublisher`: `AnyPublisher<Float, Never>`  
    Publishes the current audio level.

  - `audioBufferPublisher`: `AnyPublisher<AVAudioPCMBuffer, Never>`  
    Publishes audio buffers for processing.

  - `isEngineRunning`: `Bool`  
    Indicates if the audio engine is currently running.

- **Methods**:

  - `startEngine()`  
    Starts the audio engine.

  - `stopEngine()`  
    Stops the audio engine.

  - `assignWebSocketManager(manager: WebSocketManagerProtocol)`  
    Assigns a WebSocket manager for live streaming.

  - `startRecording()`  
    Starts recording audio to a file.

  - `stopRecording()`  
    Stops recording audio to a file.

**Usage**:  
Implement this protocol to create custom audio engine managers or use the provided `AudioEngineManager` class.

---

### AudioStateProtocol

**File**: `Protocols.swift`  
**Framework**: openaudiostandard
**Description**:  
`AudioStateProtocol` defines the interface for managing audio states, including recording, playback, and error handling.

**Definition**:

```swift
public protocol AudioStateProtocol: ObservableObject {
    var isRecording: Bool { get set }
    var isRecordingEnabled: Bool { get set }
    var isBackgroundRecordingEnabled: Bool { get set }
    var isPlaying: Bool { get set }
    var isPlaybackAvailable: Bool { get set }
    var recordingTime: TimeInterval { get set }
    var recordingProgress: Double { get set }
    var currentRecording: AudioRecording? { get set }
    var errorMessage: String? { get set }
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    var formattedRecordingTime: String { get }
    func setupWebSocket(manager: WebSocketManagerProtocol)
    func toggleRecording(manual: Bool)
    func stopRecording()
    func togglePlayback()
    func deleteRecording(_ recording: AudioRecording)
    func updateLocalRecordings()
    func fetchRecordings()
    func formattedFileSize(bytes: Int64) -> String
}
```

**Requirements**:

- **Properties**:

  - `isRecording`: `Bool`  
    Indicates if recording is active.

  - `isRecordingEnabled`: `Bool`  
    Indicates if recording is enabled.

  - `isBackgroundRecordingEnabled`: `Bool`  
    Indicates if background recording is enabled.

  - `isPlaying`: `Bool`  
    Indicates if playback is active.

  - `isPlaybackAvailable`: `Bool`  
    Indicates if playback is available.

  - `recordingTime`: `TimeInterval`  
    Tracks the duration of the current recording.

  - `recordingProgress`: `Double`  
    Represents the progress or audio level during recording.

  - `currentRecording`: `AudioRecording?`  
    The currently selected recording.

  - `errorMessage`: `String?`  
    Stores error messages related to audio operations.

  - `audioLevelPublisher`: `AnyPublisher<Float, Never>`  
    Publishes the current audio level.

  - `formattedRecordingTime`: `String`  
    Returns the formatted recording duration.

- **Methods**:

  - `setupWebSocket(manager: WebSocketManagerProtocol)`  
    Assigns a WebSocket manager for live audio streaming.

  - `toggleRecording(manual: Bool)`  
    Toggles between starting and stopping a recording session.

  - `stopRecording()`  
    Stops the current recording.

  - `togglePlayback()`  
    Toggles between starting and pausing playback.

  - `deleteRecording(_ recording: AudioRecording)`  
    Deletes a specified recording.

  - `updateLocalRecordings()`  
    Updates the list of local recordings.

  - `fetchRecordings()`  
    Fetches recordings, useful for UI updates.

  - `formattedFileSize(bytes: Int64) -> String`  
    Formats file size for display.

**Usage**:  
`AudioState` conforms to `AudioStateProtocol` and provides a comprehensive interface for managing audio states within your application.

---

## Usage Examples

### Recording Audio

To start and stop recording audio:

```swift
let audioState = AudioState.shared

// Start Recording Manually
audioState.toggleRecording(manual: true)

// Stop Recording
audioState.stopRecording()
```

### Playing Audio

To play and pause audio playback:

```swift
let audioState = AudioState.shared

// Start Playback
audioState.togglePlayback()

// Pause Playback
audioState.togglePlayback()
```

### Managing Recordings

To fetch and delete recordings:

```swift
let audioState = AudioState.shared

// Fetch Recordings
audioState.fetchRecordings()

// Delete a Recording
if let recording = audioState.currentRecording {
    audioState.deleteRecording(recording)
}
```

### Speech Recognition

To handle speech recognition:

```swift
let speechManager = SpeechRecognitionManager.shared
speechManager.requestSpeechAuthorization()
speechManager.startRecording()

// Listen for Transcriptions
speechManager.$transcribedText
    .sink { text in
        print("Transcribed Text: \(text)")
    }
    .store(in: &cancellables)
```

### Location Tracking

To manage location updates:

```swift
let locationManager = LocationManager.shared
locationManager.requestLocationAuthorization()

// Subscribe to Location Updates
locationManager.$currentLocation
    .sink { location in
        if let location = location {
            print("Current Location: \(location)")
        }
    }
    .store(in: &cancellables)
```

### WebSocket Integration

To stream audio data via WebSocket:

```swift
let webSocketURL = URL(string: "wss://yourserver.com/socket")!
let webSocketManager = WebSocketManager(url: webSocketURL)

// Assign to AudioEngineManager
AudioEngineManager.shared.assignWebSocketManager(manager: webSocketManager)

// Listen for Incoming Data
webSocketManager.receivedDataPublisher
    .sink { data in
        // Process received data
    }
    .store(in: &cancellables)

// Start Audio Engine
AudioEngineManager.shared.startEngine()
```

---

## Error Handling

The **openaudiostandard** SDK utilizes `@Published` properties to relay error messages related to various operations. Monitor the `errorMessage` property in `AudioState` and `LocationManager` to handle errors gracefully within your application.

**Example**:

```swift
AudioState.shared.$errorMessage
    .sink { error in
        if let error = error {
            // Display or log the error message
            print("Audio Error: \(error)")
        }
    }
    .store(in: &cancellables)
```

---

## License

**openaudiostandard** is released under the [MIT License](https://opensource.org/licenses/MIT). You are free to use, modify, and distribute this SDK in your projects.

---

## Contact

For support, feature requests, or contributions, please contact:

- **Author**: Elijah Arbee
- **Email**: elijah.arbee@example.com
- **GitHub**: [https://github.com/your-repo/IRL-AudioCore](https://github.com/your-repo/IRL-AudioCore)

---
