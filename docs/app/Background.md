# BackgroundAudio.swift I/O Notes

## Overview

`BackgroundAudio` is a Swift class designed to manage background audio recording within a SwiftUI application. It leverages the Singleton pattern to provide a shared instance across the app and conforms to `ObservableObject` to enable reactive UI updates based on recording state changes.

## Class Definition

```swift
class BackgroundAudio: ObservableObject {
    // Implementation details...
}
```

## Properties

| Property                            | Type                 | Access Level | Description                                                                                                                                                                   |
|-------------------------------------|----------------------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `shared`                            | `BackgroundAudio`    | Static       | Singleton instance of `BackgroundAudio`. In `DEBUG` mode, it can be overridden for testing purposes. In production, it is a constant shared instance.                           |
| `isRecording`                      | `Bool`               | `@Published` | Indicates whether audio recording is currently active. Changes to this property update the `audioState.isRecording` and notify SwiftUI views of the state change.               |
| `isRecordingEnabled`                | `Bool`               | `@AppStorage` | Persistent storage flag indicating if recording is enabled. Stored under the key `"isRecordingEnabled"`.                                                                         |
| `isBackgroundRecordingEnabled`      | `Bool`               | `@AppStorage` | Persistent storage flag indicating if background recording is permitted. Stored under the key `"isBackgroundRecordingEnabled"`.                                                   |
| `audioState`                        | `AudioState`         | Private      | Reference to an instance of `AudioState`, responsible for low-level audio recording functionalities.                                                                           |

## Initializer

| Initializer                | Parameters         | Access Level | Description                                                                                                     |
|----------------------------|--------------------|--------------|-----------------------------------------------------------------------------------------------------------------|
| `init(audioState:)`        | `audioState: AudioState = AudioState.shared` | Private      | Initializes the `BackgroundAudio` instance with a specified `AudioState`. Sets up initial recording state and registers for system notifications. |

## Methods

### `getInstance(forTesting:)`

| Method Signature                          | Parameters                     | Returns           | Description                                                                                                                                                                |
|-------------------------------------------|--------------------------------|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `static func getInstance(forTesting testInstance: AudioState? = nil) -> BackgroundAudio` | `testInstance: AudioState?` | `BackgroundAudio` | Returns the shared singleton instance. If a `testInstance` is provided, it creates a new `BackgroundAudio` instance using the provided `AudioState` for testing purposes.       |

### `toggleRecording()`

| Method Signature | Parameters | Returns | Description                                                                                                       |
|------------------|------------|---------|-------------------------------------------------------------------------------------------------------------------|
| `func toggleRecording()` | None       | `Void`  | Toggles the `isRecordingEnabled` state. If enabled, it initiates the audio session; if disabled, it stops the recording if active. |

### `setupAudioSession()`

| Method Signature     | Parameters | Returns | Description                                                                                                   |
|----------------------|------------|---------|---------------------------------------------------------------------------------------------------------------|
| `func setupAudioSession()` | None       | `Void`  | Configures the audio session based on the `isRecordingEnabled` state. Starts or stops recording accordingly.   |

### `startRecording()`

| Method Signature  | Parameters | Returns | Description                                                          |
|-------------------|------------|---------|----------------------------------------------------------------------|
| `func startRecording()` | None       | `Void`  | Initiates the recording process by delegating to `audioState` and updates `isRecording`. |

### `stopRecording()`

| Method Signature | Parameters | Returns | Description                                                          |
|------------------|------------|---------|----------------------------------------------------------------------|
| `func stopRecording()` | None       | `Void`  | Stops the recording process by delegating to `audioState` and updates `isRecording`.    |

### `setupNotifications()`

| Method Signature     | Parameters | Returns | Description                                                                                       |
|----------------------|------------|---------|---------------------------------------------------------------------------------------------------|
| `private func setupNotifications()` | None       | `Void`  | Registers observers for app lifecycle events such as entering background or termination. |

### `handleAppBackgrounding()`

| Method Signature                 | Parameters | Returns | Description                                                                                                 |
|----------------------------------|------------|---------|-------------------------------------------------------------------------------------------------------------|
| `@objc private func handleAppBackgrounding()` | None       | `Void`  | Handles app transitioning to the background. Continues recording if `isBackgroundRecordingEnabled` is true; otherwise, stops recording. |

### `handleAppTermination()`

| Method Signature              | Parameters | Returns | Description                                                                                             |
|-------------------------------|------------|---------|---------------------------------------------------------------------------------------------------------|
| `@objc private func handleAppTermination()` | None       | `Void`  | Ensures that recording is stopped when the app is about to terminate to prevent data loss or resource leaks. |

## Inputs and Outputs

### Inputs

- **User Actions:**
  - **Toggle Recording:** Invokes `toggleRecording()` to start or stop audio recording based on the current state.

- **App Lifecycle Events:**
  - **Backgrounding:** Triggers `handleAppBackgrounding()` to manage recording state when the app moves to the background.
  - **Termination:** Triggers `handleAppTermination()` to stop recording gracefully when the app is about to terminate.

- **Persistent Storage:**
  - **`isRecordingEnabled`:** Retrieved and stored using `@AppStorage`, allowing users to enable or disable recording across app launches.
  - **`isBackgroundRecordingEnabled`:** Retrieved and stored using `@AppStorage`, controlling whether recording continues in the background.

- **Dependency Injection (Testing):**
  - **`AudioState`:** Can be injected via `getInstance(forTesting:)` to facilitate testing with mock or custom audio states.

### Outputs

- **State Changes:**
  - **`isRecording`:** Published property that notifies SwiftUI views of changes in the recording state, allowing the UI to react accordingly.

- **Audio Recording Control:**
  - **Start Recording:** Initiates audio recording through `audioState.startRecording()`.
  - **Stop Recording:** Halts audio recording through `audioState.stopRecording()`.

- **System Interactions:**
  - **Audio Session Management:** Configures the audio session based on user settings and app state.
  - **Notification Handling:** Responds to system notifications to maintain appropriate recording behavior during app lifecycle transitions.

## Usage Example

```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var backgroundAudio = BackgroundAudio.shared

    var body: some View {
        VStack {
            Text(backgroundAudio.isRecording ? "Recording..." : "Not Recording")
            Button(action: {
                backgroundAudio.toggleRecording()
            }) {
                Text(backgroundAudio.isRecording ? "Stop Recording" : "Start Recording")
            }
        }
        .padding()
    }
}
```

In the example above, the `ContentView` observes the `BackgroundAudio` instance. It displays the current recording state and provides a button to toggle recording. When the button is pressed, `toggleRecording()` is called, which updates the recording state and manages the audio session accordingly.

## Testing Considerations

- **Singleton Flexibility:** In `DEBUG` mode, the `shared` instance can be overridden to inject mock `AudioState` instances, facilitating unit testing.
- **Dependency Injection:** The `getInstance(forTesting:)` method allows tests to provide custom `AudioState` instances, enabling controlled testing environments.

## Dependencies

- **SwiftUI:** Utilized for reactive UI updates via the `ObservableObject` protocol and `@Published` properties.
- **Foundation:** Provides foundational classes and functionalities.
- **AudioState:** A separate class responsible for low-level audio recording operations. It must conform to the expected interface used within `BackgroundAudio`.

## Notes

- **Thread Safety:** Ensure that any interactions with `BackgroundAudio` occur on the main thread, especially when updating `@Published` properties to maintain UI consistency.
- **Resource Management:** Properly stopping recordings during app termination or when disabling recording is crucial to prevent resource leaks or data corruption.
- **Error Handling:** While not explicitly handled in the provided code, consider implementing error handling for audio session failures or unexpected interruptions.