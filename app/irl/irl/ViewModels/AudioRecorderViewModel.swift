//
//  AudioRecorderViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 8/30/24.
//

import SwiftUI
import Combine

class AudioRecorderViewModel: ObservableObject {
    // View model is an @ObservableObject, meaning the SwiftUI views observing it will update when these
    // @Published properties change. This is the core of state management in this view model.
    
    @Published private(set) var audioState: AudioState // Holds shared audio state across the app (singleton).
    @Published private(set) var speechRecognitionManager: SpeechRecognitionManager // Manages speech recognition (singleton).
    @Published private(set) var recordings: [RecordingViewModel] = [] // Holds the list of recordings.
    @Published var currentRecording: RecordingViewModel? // Tracks the currently active recording.
    @Published var errorMessage: String? // Holds error messages that might be triggered during recording or playback.
    
    private var cancellables = Set<AnyCancellable>() // Used for managing Combine subscriptions.

    init() {
        // Initializing singletons for AudioState and SpeechRecognitionManager ensures state persistence across app views.
        self.audioState = AudioState.shared
        self.speechRecognitionManager = SpeechRecognitionManager.shared
        
        // Set up bindings to automatically update the UI when audio state changes or errors occur.
        setupBindings()
        
        // Optionally, request speech authorization when the view model initializes
        self.speechRecognitionManager.requestSpeechAuthorization()
    }

    private func setupBindings() {
        // Binding localRecordings from AudioState to update the list of RecordingViewModels.
        // This ensures that when recordings are fetched or changed, the view updates accordingly.
        audioState.$localRecordings
            .sink { [weak self] recordings in
                self?.updateRecordingViewModels(recordings)
            }
            .store(in: &cancellables)

        // Binding currentRecording from AudioState to update the current recording being played or recorded.
        audioState.$currentRecording
            .sink { [weak self] recording in
                if let recording = recording {
                    self?.currentRecording = self?.recordings.first { $0.recording.id == recording.id }
                } else {
                    self?.currentRecording = nil
                }
            }
            .store(in: &cancellables)

        // Listening to error messages from AudioState and updating the error message in the view model.
        audioState.$errorMessage
            .sink { [weak self] message in
                self?.errorMessage = message
            }
            .store(in: &cancellables)

        // Listening to transcribed text updates from the SpeechRecognitionManager for speech recognition-related information.
        speechRecognitionManager.$transcribedText
            .sink { [weak self] transcribedText in
                // Handle transcription updates if necessary
                // For example, you might want to update the current recording's transcription
                if let current = self?.currentRecording {
                    current.transcribedText = transcribedText
                }
            }
            .store(in: &cancellables)
        
        // Listening to speech detection status to update error messages or UI elements.
        speechRecognitionManager.$isSpeechDetected
            .sink { [weak self] isDetected in
                if !isDetected && self?.speechRecognitionManager.transcribedText.contains("Failed") == true {
                    self?.errorMessage = self?.speechRecognitionManager.transcribedText
                }
            }
            .store(in: &cancellables)
    }

    // Converts recordings fetched from AudioState into RecordingViewModel instances,
    // which handle additional behavior like speech recognition.
    private func updateRecordingViewModels(_ recordings: [AudioRecording]) {
        self.recordings = recordings.map { recording in
            let viewModel = RecordingViewModel(recording: recording, speechRecognitionManager: speechRecognitionManager)
            viewModel.startTranscription() // Starts transcription for each recording immediately after fetching.
            return viewModel
        }
    }
    
    // Fetches recordings from the AudioState singleton, which likely interacts with persistent storage.
    func fetchRecordings() {
        audioState.fetchRecordings()
    }

    // Updates local recordings by calling the equivalent function in AudioState.
    // This function ensures that any stored audio recordings are loaded and available in the UI.
    func updateLocalRecordings() {
        audioState.updateLocalRecordings()
    }

    // Toggles the recording state by interacting with the AudioState singleton.
    func toggleRecording() {
        audioState.toggleRecording()
    }

    // Toggles playback for the current recording.
    func togglePlayback() {
        audioState.togglePlayback()
    }

    // Deletes a recording and removes it from both the AudioState and local view model list.
    func deleteRecording(_ recording: RecordingViewModel) {
        audioState.deleteRecording(recording.recording) // Calls into AudioState to handle deletion.
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings.remove(at: index) // Remove from local state after deletion in AudioState.
        }
    }

    // Computed properties that expose the current audio recording/playback states from AudioState.
    var isRecording: Bool {
        audioState.isRecording
    }

    var isPlaying: Bool {
        audioState.isPlaying
    }

    var isPlaybackAvailable: Bool {
        audioState.isPlaybackAvailable
    }

    // Returns the current recording progress as a percentage.
    var recordingProgress: Double {
        audioState.recordingProgress
    }

    // Formats the current recording time for display.
    var formattedRecordingTime: String {
        audioState.formattedRecordingTime
    }

    // Formats the file size of the recording, potentially useful for UI display.
    func formattedFileSize(bytes: Int64) -> String {
        audioState.formattedFileSize(bytes: bytes)
    }
}

// View model for individual recordings, also an @ObservableObject to update the UI when state changes.
class RecordingViewModel: ObservableObject, Identifiable {
    let id: UUID // Unique identifier for each recording.
    let recording: AudioRecording // Holds the actual AudioRecording data.
    @Published var transcribedText: String = "Transcription will appear here." // Stores the transcription result for this recording.
    
    private let speechRecognitionManager: SpeechRecognitionManager // Reference to the shared SpeechRecognitionManager.
    private var cancellable: AnyCancellable? // Manages the subscription to the speech transcription updates.

    init(recording: AudioRecording, speechRecognitionManager: SpeechRecognitionManager) {
        self.id = recording.id
        self.recording = recording
        self.speechRecognitionManager = speechRecognitionManager
    }

    // Starts transcription by subscribing to transcribed text updates from the speech recognition manager.
    func startTranscription() {
        // Assuming SpeechRecognitionManager can handle transcription of existing recordings.
        // If SpeechRecognitionManager only handles live transcription, additional implementation is needed.
        
        // Example implementation:
        // speechRecognitionManager.transcribeAudio(url: recording.url)
        
        // Subscribe to the transcribedText for this recording.
        // This assumes SpeechRecognitionManager provides a way to transcribe specific audio files.
        cancellable = speechRecognitionManager.$transcribedText
            .sink { [weak self] text in
                // Update the transcribedText if it corresponds to this recording
                // This requires SpeechRecognitionManager to associate transcriptions with recordings
                // For simplicity, assuming one transcription at a time
                self?.transcribedText = text
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
