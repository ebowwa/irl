# I/O Notes for `SpeechAnalysisService.swift`

## Overview

`SpeechAnalysisService` is a singleton service responsible for handling speech analysis within the application. It manages tasks such as detecting whether audio files are suitable for transcription and prosody analysis, maintaining a queue of audio files ready for analysis, and providing user controls for enabling or disabling the service via a widget.

---

## Table of Contents

- [Class Overview](#class-overview)
  - [Properties](#properties)
  - [Methods](#methods)
- [Delegates](#delegates)
- [Usage](#usage)
- [Notes](#notes)

---

## Class Overview

### `SpeechAnalysisService`

A singleton class that manages speech recognition tasks, including authorization, analysis, and error handling.

```swift
@available(iOS 17.0, *)
class SpeechAnalysisService: NSObject, ObservableObject, SFSpeechRecognitionTaskDelegate {
    // ...
}
```

---

### Properties

#### Published Properties

- **`analysisProbabilities: [URL: Double]`**
  
  - **Description:**  
    A dictionary mapping each audio recording's URL to its corresponding analysis probability percentage.
  
  - **Input:**  
    - Key: `URL` of the audio recording.
  
  - **Output:**  
    - Value: `Double` representing the probability percentage that the audio contains sufficient speech for transcription.

- **`isAnalyzing: Bool`**
  
  - **Description:**  
    Indicates whether an audio recording is currently being analyzed.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - `true` if analysis is in progress, `false` otherwise.

- **`errorMessage: String?`**
  
  - **Description:**  
    Stores error messages related to speech recognition and analysis tasks.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - A descriptive error message string or `nil` if there are no errors.

- **`authorizationStatus: SFSpeechRecognizerAuthorizationStatus`**
  
  - **Description:**  
    Represents the current authorization status for speech recognition.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - Enum value indicating authorization status (`authorized`, `denied`, `restricted`, `notDetermined`).

#### Private Properties

- **`speechRecognizer: SFSpeechRecognizer?`**
  
  - **Description:**  
    The speech recognizer instance used for processing audio recordings.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - An optional `SFSpeechRecognizer` instance.

- **`recognitionTask: SFSpeechRecognitionTask?`**
  
  - **Description:**  
    The current speech recognition task being executed.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - An optional `SFSpeechRecognitionTask` instance.

- **`currentRecordingURL: URL?`**
  
  - **Description:**  
    The URL of the audio recording currently under analysis.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - An optional `URL` pointing to the current audio file.

- **`analysisQueue: DispatchQueue`**
  
  - **Description:**  
    The dispatch queue dedicated to handling speech analysis tasks.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - A `DispatchQueue` instance configured for user-initiated quality of service.

---

### Methods

#### Initializer

- **`private override init()`**
  
  - **Description:**  
    Initializes the `SpeechAnalysisService`, setting up the speech recognizer and requesting necessary permissions.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - An instance of `SpeechAnalysisService`.

#### Setup Methods

- **`private func setupSpeechRecognizer()`**
  
  - **Description:**  
    Configures the speech recognizer and assigns its delegate.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - None.

- **`private func setupLanguageModel()`**
  
  - **Description:**  
    Prints locale information of the speech recognizer for debugging purposes.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - None.

#### Language Configuration

- **`func changeLanguage(to identifier: String)`**
  
  - **Description:**  
    Changes the speech recognizer's language to the specified locale identifier.
  
  - **Input:**  
    - `identifier: String` - Locale identifier (e.g., `"en-US"`, `"fr-FR"`).
  
  - **Output:**  
    - None. Updates the `speechRecognizer` instance and reinitializes the language model.

#### Permission Handling

- **`func checkSpeechRecognitionPermission()`**
  
  - **Description:**  
    Requests and handles the user's permission for speech recognition services.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - Updates `authorizationStatus` and `errorMessage` based on the user's response.

#### Analysis Methods

- **`func analyzeRecording(_ recording: AudioRecording) async`**
  
  - **Description:**  
    Analyzes a single audio recording to determine its suitability for transcription.
  
  - **Input:**  
    - `recording: AudioRecording` - The audio recording to be analyzed.
  
  - **Output:**  
    - Updates `analysisProbabilities`, `isAnalyzing`, and `errorMessage` based on the analysis outcome.

- **`func analyzeAllRecordings(_ recordings: [AudioRecording]) async`**
  
  - **Description:**  
    Sequentially analyzes multiple audio recordings.
  
  - **Input:**  
    - `recordings: [AudioRecording]` - An array of audio recordings to be analyzed.
  
  - **Output:**  
    - Updates `analysisProbabilities`, `isAnalyzing`, and `errorMessage` for each recording.

- **`private func processResult(_ result: SFSpeechRecognitionResult) async`**
  
  - **Description:**  
    Processes the result from the speech recognizer to calculate word count and speech probability.
  
  - **Input:**  
    - `result: SFSpeechRecognitionResult` - The result obtained from speech recognition.
  
  - **Output:**  
    - Updates `analysisProbabilities` and `errorMessage` based on the processed result.

#### Task Management

- **`func cancelOngoingTasks()`**
  
  - **Description:**  
    Cancels any ongoing speech recognition tasks and resets relevant states.
  
  - **Input:**  
    - None.
  
  - **Output:**  
    - Resets `recognitionTask` to `nil` and sets `isAnalyzing` to `false`.

---

## Delegates

### `SFSpeechRecognizerDelegate`

Conforms to `SFSpeechRecognizerDelegate` to handle changes in the availability of the speech recognizer.

- **`func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)`**
  
  - **Description:**  
    Called when the availability of the speech recognizer changes.
  
  - **Input:**  
    - `speechRecognizer: SFSpeechRecognizer` - The speech recognizer instance.
    - `available: Bool` - Availability status (`true` if available, `false` otherwise).
  
  - **Output:**  
    - Updates `errorMessage` to notify the user if speech recognition becomes unavailable or clears previous error messages if it becomes available.

---

## Usage

To utilize the `SpeechAnalysisService` within your SwiftUI views or other parts of the application:

1. **Access the Singleton Instance:**

    ```swift
    let speechService = SpeechAnalysisService.shared
    ```

2. **Observe Published Properties:**

    ```swift
    @ObservedObject var speechService = SpeechAnalysisService.shared
    ```

3. **Analyze an Audio Recording:**

    ```swift
    Task {
        await speechService.analyzeRecording(yourAudioRecording)
    }
    ```

4. **Change Speech Recognizer Language:**

    ```swift
    speechService.changeLanguage(to: "es-ES") // Changes to Spanish (Spain)
    ```

5. **Handle Authorization Status:**

    Monitor `authorizationStatus` and `errorMessage` to update the UI accordingly.

---

## Notes

- **iOS Version Requirement:**  
  The service is only available on iOS 17.0 or later versions, as specified by the `@available(iOS 17.0, *)` attribute.

- **Error Handling:**  
  The service updates `errorMessage` to inform the user of any issues during speech recognition, such as permission denials or recognition failures.

- **Concurrency:**  
  Utilizes Swift's async/await for handling asynchronous speech recognition tasks, ensuring that UI updates occur on the main thread.

- **TODO:**  
  - Correct the analysis result behavior:
    - Currently determines analysis results but often requires a full page refresh to change the state.
    - If no speech is detected, it still indicates "analyzing" instead of "no speech detected."

---

## Conclusion

`SpeechAnalysisService` provides a comprehensive solution for managing speech analysis within an iOS application. By handling authorization, language configuration, task management, and error reporting, it serves as a robust backbone for any feature requiring speech recognition and analysis.